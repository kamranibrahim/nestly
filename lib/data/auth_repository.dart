import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'enums.dart';
import 'invite_code.dart';
import 'nest_home_widget.dart';
import 'repositories.dart';
import 'telemetry.dart';

class NestInfo {
  const NestInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.createdAt,
  });

  final String id;
  final String name;
  final String inviteCode;
  final DateTime? createdAt;
}

class AuthRepository {
  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static const _uuid = Uuid();

  Stream<User?> authState() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(displayName.trim());
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'email': email.trim(),
      'displayName': displayName.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await NestlyTelemetry.signUp();
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await NestlyTelemetry.login();
    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    await NestlyTelemetry.passwordResetRequested();
  }

  Future<void> signOut() async {
    try {
      await NestHomeWidget.clear();
    } catch (_) {}
    await _auth.signOut();
  }

  /// Required before sensitive ops like account deletion when the session is stale.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = _auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw StateError('Not signed in');
    }
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);
  }

  /// Change password while signed in (email/password accounts).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    final trimmed = newPassword.trim();
    if (trimmed.length < 6) {
      throw FirebaseAuthException(
        code: 'weak-password',
        message: 'Use a password with at least 6 characters.',
      );
    }
    await reauthenticateWithPassword(currentPassword);
    await user.updatePassword(trimmed);
    await NestlyTelemetry.changePasswordSuccess();
  }

  Future<NestInfo?> currentNest() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final nestId = userDoc.data()?['nestId'] as String?;
    if (nestId == null) return null;
    final nest = await _firestore.collection('nests').doc(nestId).get();
    final data = nest.data();
    if (data == null) return null;
    return NestInfo(
      id: nestId,
      name: data['name'] as String? ?? 'Family',
      inviteCode: data['inviteCode'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Future<NestInfo> createNest({
    required String nestName,
    required String memberName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to create a nest');
    }

    final nestId = _uuid.v4();
    final inviteCode = _generateInviteCode();
    final batch = _firestore.batch();

    batch.set(_firestore.collection('nests').doc(nestId), {
      'name': nestName.trim(),
      'inviteCode': inviteCode,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(
      _firestore
          .collection('nests')
          .doc(nestId)
          .collection('members')
          .doc(user.uid),
      {
        'name': memberName.trim(),
        'role': 'Adult',
        'initials': _initials(memberName),
        'colorValue': 0xFFB2B2E6,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    batch.set(_firestore.collection('inviteCodes').doc(inviteCode), {
      'nestId': nestId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('users').doc(user.uid), {
      'nestId': nestId,
      'displayName': memberName.trim(),
      'email': user.email,
    }, SetOptions(merge: true));

    await batch.commit();

    final info = NestInfo(
      id: nestId,
      name: nestName.trim(),
      inviteCode: inviteCode,
      createdAt: DateTime.now(),
    );
    await NestlyTelemetry.nestCreated();
    return info;
  }

  Future<NestInfo> joinNest({
    required String inviteCode,
    required String memberName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to join a nest');
    }

    final code = normalizeInviteCode(inviteCode);
    if (code.length < 6) {
      throw StateError('Invite codes are 6 characters.');
    }
    final invite = await _firestore.collection('inviteCodes').doc(code).get();
    if (!invite.exists) {
      throw StateError('Invite code not found');
    }
    final nestId = invite.data()!['nestId'] as String;
    final nest = await _firestore.collection('nests').doc(nestId).get();
    final nestName = nest.data()?['name'] as String? ?? 'Family';

    final colors = [0xFFB2B2E6, 0xFFD4E7B3, 0xFFFFD8A8, 0xFFF5C6D8, 0xFFC5E8E0];
    final color = colors[Random().nextInt(colors.length)];

    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection('nests')
          .doc(nestId)
          .collection('members')
          .doc(user.uid),
      {
        'name': memberName.trim(),
        'role': 'Member',
        'initials': _initials(memberName),
        'colorValue': color,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    batch.set(_firestore.collection('users').doc(user.uid), {
      'nestId': nestId,
      'displayName': memberName.trim(),
      'email': user.email,
    }, SetOptions(merge: true));
    await batch.commit();

    final info = NestInfo(
      id: nestId,
      name: nestName,
      inviteCode: code,
      createdAt: (nest.data()?['createdAt'] as Timestamp?)?.toDate(),
    );
    await NestlyTelemetry.nestJoined();
    await NestlyTelemetry.secondMemberJoined();
    return info;
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

/// Last-write-wins sync between Drift and Firestore for one nest.
class SyncService {
  SyncService(this._db, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final AppDatabase _db;
  final FirebaseFirestore _firestore;
  int _keptLocalDuringPull = 0;

  /// Prefer local dirty / newer rows over remote during pull.
  bool _shouldKeepLocal({
    required bool dirty,
    required DateTime localUpdated,
    required DateTime remoteUpdated,
  }) {
    if (dirty || localUpdated.isAfter(remoteUpdated)) {
      _keptLocalDuringPull++;
      return true;
    }
    return false;
  }

  Future<void> bindNest(String nestId) async {
    final previous = await _db.getMeta('nestId');
    final cleaned = await _db.getMeta('householdClean') == '1';
    if (previous != nestId || !cleaned) {
      await _db.clearHouseholdData();
      await _db.setMeta('householdClean', '1');
    }
    await _db.setMeta('nestId', nestId);
    await _ensureDefaultShoppingList(nestId);
  }

  Future<void> _ensureDefaultShoppingList(String nestId) async {
    final existing =
        await (_db.select(_db.shoppingLists)
              ..where((l) => l.id.equals(ShoppingRepository.defaultListId)))
            .getSingleOrNull();
    if (existing != null) return;
    final now = DateTime.now();
    await _db
        .into(_db.shoppingLists)
        .insert(
          ShoppingListsCompanion.insert(
            id: ShoppingRepository.defaultListId,
            nestId: Value(nestId),
            name: 'Groceries',
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> pullMembers(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('members')
        .get();
    final remoteIds = <String>{};
    for (final doc in snap.docs) {
      remoteIds.add(doc.id);
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.nestMembers,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.nestMembers)
          .insertOnConflictUpdate(
            NestMembersCompanion.insert(
              id: doc.id,
              nestId: nestId,
              name: data['name'] as String? ?? 'Member',
              role: Value(data['role'] as String? ?? 'Member'),
              initials: data['initials'] as String? ?? '?',
              colorValue: data['colorValue'] as int? ?? 0xFF4A78DD,
              dirty: const Value(false),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }

    final locals = await _db.select(_db.nestMembers).get();
    for (final local in locals) {
      if (!remoteIds.contains(local.id) && !local.dirty) {
        await (_db.delete(
          _db.nestMembers,
        )..where((t) => t.id.equals(local.id))).go();
      }
    }
  }

  Future<void> _pushMembers(String nestId) async {
    final dirty = await (_db.select(
      _db.nestMembers,
    )..where((t) => t.dirty.equals(true))).get();
    for (final member in dirty) {
      await _firestore
          .collection('nests')
          .doc(nestId)
          .collection('members')
          .doc(member.id)
          .set({
            'name': member.name,
            'role': member.role,
            'initials': member.initials,
            'colorValue': member.colorValue,
            'updatedAt': Timestamp.fromDate(member.updatedAt),
          }, SetOptions(merge: true));
      await (_db.update(_db.nestMembers)..where((t) => t.id.equals(member.id)))
          .write(const NestMembersCompanion(dirty: Value(false)));
    }
  }

  /// Syncs nest cloud ↔ local. Returns how many remote rows were skipped
  /// because a dirtier/newer local copy won (last-write-wins).
  Future<int> syncAll() async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return 0;
    if (FirebaseAuth.instance.currentUser == null) return 0;
    _keptLocalDuringPull = 0;

    Future<void> step(Future<void> Function() action) async {
      if (FirebaseAuth.instance.currentUser == null) {
        throw const _SignedOutDuringSync();
      }
      await action();
    }

    final sw = Stopwatch()..start();
    try {
      await step(() => _pushTasks(nestId));
      await step(() => _pullTasks(nestId));
      await step(() => _pushShopping(nestId));
      await step(() => _pullShopping(nestId));
      await step(() => _pushEvents(nestId));
      await step(() => _pullEvents(nestId));
      await step(() => _pushExpenses(nestId));
      await step(() => _pullExpenses(nestId));
      await step(() => _pushBills(nestId));
      await step(() => _pullBills(nestId));
      await step(() => _pushNestSettings(nestId));
      await step(() => _pullNestSettings(nestId));
      await step(() => _pushEmergency(nestId));
      await step(() => _pullEmergency(nestId));
      await step(() => _pushVault(nestId));
      await step(() => _pullVault(nestId));
      await step(() => _pushTimeline(nestId));
      await step(() => _pullTimeline(nestId));
      await step(() => _pushMeals(nestId));
      await step(() => _pullMeals(nestId));
      await step(() => _pushCare(nestId));
      await step(() => _pullCare(nestId));
      await step(() => _pushCareProfiles(nestId));
      await step(() => _pullCareProfiles(nestId));
      await step(() => _pushSchool(nestId));
      await step(() => _pullSchool(nestId));
      await step(() => _pushMembers(nestId));
      await step(() => pullMembers(nestId));
      await _db.setMeta('lastSyncAt', DateTime.now().toIso8601String());
      sw.stop();
      await NestlyTelemetry.syncSuccess(durationMs: sw.elapsedMilliseconds);
      return _keptLocalDuringPull;
    } on _SignedOutDuringSync {
      sw.stop();
      debugPrint('Sync aborted: signed out');
      return 0;
    } catch (e, st) {
      // Sign-out / auth race: rules deny unauthenticated reads.
      if (e is FirebaseException &&
          e.code == 'permission-denied' &&
          FirebaseAuth.instance.currentUser == null) {
        sw.stop();
        debugPrint('Sync aborted: signed out during sync');
        return 0;
      }
      sw.stop();
      debugPrint('Sync failed: $e\n$st');
      final reason = e is FirebaseException ? e.code : e.runtimeType.toString();
      await NestlyTelemetry.syncFail(
        reason: reason,
        durationMs: sw.elapsedMilliseconds,
      );
      await NestlyTelemetry.recordNonFatal(e, st, reason: reason);
      rethrow;
    }
  }

  Future<void> _pushTasks(String nestId) async {
    final dirty = await (_db.select(
      _db.tasks,
    )..where((t) => t.dirty.equals(true))).get();
    for (final task in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('tasks')
          .doc(task.id);
      if (task.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': task.title,
          'assigneeId': task.assigneeId,
          'dueLabel': task.dueLabel,
          'done': task.done,
          'recurring': task.recurring,
          'updatedAt': Timestamp.fromDate(task.updatedAt),
          'createdAt': Timestamp.fromDate(task.createdAt),
        });
      }
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        const TasksCompanion(dirty: Value(false)),
      );
    }
  }

  Future<void> _pullTasks(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('tasks')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.tasks,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.tasks)
          .insertOnConflictUpdate(
            TasksCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              assigneeId: Value(data['assigneeId'] as String? ?? 'dad'),
              dueLabel: Value(data['dueLabel'] as String? ?? 'Today'),
              done: Value(data['done'] as bool? ?? false),
              recurring: Value(data['recurring'] as bool? ?? false),
              dirty: const Value(false),
              deleted: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushShopping(String nestId) async {
    final dirtyLists = await (_db.select(
      _db.shoppingLists,
    )..where((t) => t.dirty.equals(true))).get();
    for (final list in dirtyLists) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('shoppingLists')
          .doc(list.id);
      if (list.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'name': list.name,
          'updatedAt': Timestamp.fromDate(list.updatedAt),
          'createdAt': Timestamp.fromDate(list.createdAt),
        });
      }
      await (_db.update(_db.shoppingLists)..where((t) => t.id.equals(list.id)))
          .write(const ShoppingListsCompanion(dirty: Value(false)));
    }

    final dirtyItems = await (_db.select(
      _db.shoppingItems,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirtyItems) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('shoppingItems')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'listId': item.listId,
          'name': item.name,
          'category': item.category,
          'qty': item.qty,
          'done': item.done,
          'sortOrder': item.sortOrder,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.shoppingItems)..where((t) => t.id.equals(item.id)))
          .write(const ShoppingItemsCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullShopping(String nestId) async {
    final lists = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('shoppingLists')
        .get();
    for (final doc in lists.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      await _db
          .into(_db.shoppingLists)
          .insertOnConflictUpdate(
            ShoppingListsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              name: data['name'] as String? ?? 'List',
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }

    final items = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('shoppingItems')
        .get();
    for (final doc in items.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.shoppingItems,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.shoppingItems)
          .insertOnConflictUpdate(
            ShoppingItemsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              listId: data['listId'] as String? ?? 'list-groceries',
              name: data['name'] as String? ?? '',
              category: Value(data['category'] as String? ?? 'General'),
              qty: Value(data['qty'] as String? ?? '1'),
              done: Value(data['done'] as bool? ?? false),
              sortOrder: Value(data['sortOrder'] as int? ?? 0),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushEvents(String nestId) async {
    final dirty = await (_db.select(
      _db.calendarEvents,
    )..where((t) => t.dirty.equals(true))).get();
    for (final event in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('events')
          .doc(event.id);
      if (event.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': event.title,
          'memberId': event.memberId,
          'category': event.category,
          'location': event.location,
          'startsAt': Timestamp.fromDate(event.startsAt),
          'endsAt': event.endsAt == null
              ? null
              : Timestamp.fromDate(event.endsAt!),
          'allDay': event.allDay,
          'updatedAt': Timestamp.fromDate(event.updatedAt),
          'createdAt': Timestamp.fromDate(event.createdAt),
        });
      }
      await (_db.update(_db.calendarEvents)
            ..where((t) => t.id.equals(event.id)))
          .write(const CalendarEventsCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullEvents(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('events')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.calendarEvents,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.calendarEvents)
          .insertOnConflictUpdate(
            CalendarEventsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              memberId: Value(data['memberId'] as String? ?? 'dad'),
              category: Value(data['category'] as String? ?? 'Family'),
              location: Value(data['location'] as String?),
              startsAt:
                  (data['startsAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              endsAt: Value((data['endsAt'] as Timestamp?)?.toDate()),
              allDay: Value(data['allDay'] as bool? ?? false),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushExpenses(String nestId) async {
    final dirty = await (_db.select(
      _db.expenses,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('expenses')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': item.title,
          'category': item.category,
          'amount': item.amount,
          'paidBy': item.paidBy,
          'spentAt': Timestamp.fromDate(item.spentAt),
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.expenses)..where((t) => t.id.equals(item.id)))
          .write(const ExpensesCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullExpenses(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('expenses')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.expenses,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.expenses)
          .insertOnConflictUpdate(
            ExpensesCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              category: Value(data['category'] as String? ?? 'General'),
              amount: (data['amount'] as num?)?.toDouble() ?? 0,
              paidBy: Value(data['paidBy'] as String? ?? ''),
              spentAt: Value(
                (data['spentAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushBills(String nestId) async {
    final dirty = await (_db.select(
      _db.bills,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('bills')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': item.title,
          'amount': item.amount,
          'dueAt': Timestamp.fromDate(item.dueAt),
          'paid': item.paid,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.bills)..where((t) => t.id.equals(item.id))).write(
        const BillsCompanion(dirty: Value(false)),
      );
    }
  }

  Future<void> _pullBills(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('bills')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.bills,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.bills)
          .insertOnConflictUpdate(
            BillsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              amount: (data['amount'] as num?)?.toDouble() ?? 0,
              dueAt: (data['dueAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              paid: Value(data['paid'] as bool? ?? false),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushNestSettings(String nestId) async {
    final row = await (_db.select(
      _db.nestSettings,
    )..where((s) => s.id.equals(nestId))).getSingleOrNull();
    if (row == null || !row.dirty) return;
    await _firestore.collection('nests').doc(nestId).set({
      'monthBudget': row.monthBudget,
      'tomorrowPreviewEnabled': row.tomorrowPreviewEnabled,
      'budgetUpdatedAt': Timestamp.fromDate(row.updatedAt),
    }, SetOptions(merge: true));
    await (_db.update(_db.nestSettings)..where((s) => s.id.equals(nestId)))
        .write(const NestSettingsCompanion(dirty: Value(false)));
  }

  Future<void> _pullNestSettings(String nestId) async {
    final snap = await _firestore.collection('nests').doc(nestId).get();
    final data = snap.data();
    if (data == null || data['monthBudget'] == null) return;
    final remoteUpdated =
        (data['budgetUpdatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final local = await (_db.select(
      _db.nestSettings,
    )..where((s) => s.id.equals(nestId))).getSingleOrNull();
    if (local != null &&
        _shouldKeepLocal(
          dirty: local.dirty,
          localUpdated: local.updatedAt,
          remoteUpdated: remoteUpdated,
        )) {
      return;
    }
    final budget =
        (data['monthBudget'] as num?)?.toDouble() ??
        ExpenseRepository.defaultMonthBudget;
    final tomorrowPreviewEnabled =
        data['tomorrowPreviewEnabled'] as bool? ?? false;
    await _db
        .into(_db.nestSettings)
        .insertOnConflictUpdate(
          NestSettingsCompanion.insert(
            id: nestId,
            monthBudget: Value(budget),
            tomorrowPreviewEnabled: Value(tomorrowPreviewEnabled),
            dirty: const Value(false),
            updatedAt: Value(remoteUpdated),
          ),
        );
  }

  Future<void> _pushEmergency(String nestId) async {
    final dirty = await (_db.select(
      _db.emergencyEntries,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('emergency')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'label': item.label,
          'value': item.value,
          'iconName': item.iconName,
          'sortOrder': item.sortOrder,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
        });
      }
      await (_db.update(_db.emergencyEntries)
            ..where((t) => t.id.equals(item.id)))
          .write(const EmergencyEntriesCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullEmergency(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('emergency')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.emergencyEntries,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.emergencyEntries)
          .insertOnConflictUpdate(
            EmergencyEntriesCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              label: data['label'] as String? ?? '',
              value: data['value'] as String? ?? '',
              iconName: Value(data['iconName'] as String? ?? 'info'),
              sortOrder: Value(data['sortOrder'] as int? ?? 0),
              dirty: const Value(false),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushVault(String nestId) async {
    final dirty = await (_db.select(
      _db.vaultDocuments,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('vault')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': item.title,
          'category': item.category,
          'fileName': item.fileName,
          'storagePath': item.storagePath,
          'mimeType': item.mimeType,
          'sizeBytes': item.sizeBytes,
          'notes': item.notes,
          'expiresAt': item.expiresAt == null
              ? null
              : Timestamp.fromDate(item.expiresAt!),
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.vaultDocuments)..where((t) => t.id.equals(item.id)))
          .write(const VaultDocumentsCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullVault(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('vault')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.vaultDocuments,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.vaultDocuments)
          .insertOnConflictUpdate(
            VaultDocumentsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              category: Value(
                data['category'] as String? ?? VaultFolder.family.label,
              ),
              fileName: data['fileName'] as String? ?? 'file',
              storagePath: Value(data['storagePath'] as String?),
              mimeType: Value(data['mimeType'] as String?),
              sizeBytes: Value(data['sizeBytes'] as int? ?? 0),
              notes: Value(data['notes'] as String? ?? ''),
              expiresAt: Value((data['expiresAt'] as Timestamp?)?.toDate()),
              uploadStatus: Value(
                (data['storagePath'] as String?)?.isNotEmpty == true
                    ? VaultUploadStatus.synced.storage
                    : VaultUploadStatus.local.storage,
              ),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushTimeline(String nestId) async {
    final dirty = await (_db.select(
      _db.timelineEvents,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('timeline')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'message': item.message,
          'memberId': item.memberId,
          'memberName': item.memberName,
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.timelineEvents)..where((t) => t.id.equals(item.id)))
          .write(const TimelineEventsCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullTimeline(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('timeline')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final created =
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.timelineEvents,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null && local.dirty) continue;
      await _db
          .into(_db.timelineEvents)
          .insertOnConflictUpdate(
            TimelineEventsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              message:
                  data['message'] as String? ?? data['text'] as String? ?? '',
              memberId: Value(data['memberId'] as String? ?? ''),
              memberName: Value(data['memberName'] as String? ?? 'Family'),
              dirty: const Value(false),
              createdAt: Value(created),
            ),
          );
    }
  }

  Future<void> _pushMeals(String nestId) async {
    final dirty = await (_db.select(
      _db.mealPlans,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('meals')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'weekday': item.weekday,
          'mealType': item.mealType,
          'title': item.title,
          'ingredients': item.ingredients,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.mealPlans)..where((t) => t.id.equals(item.id)))
          .write(const MealPlansCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullMeals(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('meals')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.mealPlans,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.mealPlans)
          .insertOnConflictUpdate(
            MealPlansCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              weekday: data['weekday'] as int? ?? 1,
              mealType: Value(data['mealType'] as String? ?? 'Dinner'),
              title: data['title'] as String? ?? '',
              ingredients: Value(data['ingredients'] as String? ?? ''),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushCare(String nestId) async {
    final dirty = await (_db.select(
      _db.careItems,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('care')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': item.title,
          'category': item.category,
          'cadenceDays': item.cadenceDays,
          'lastDoneAt': item.lastDoneAt == null
              ? null
              : Timestamp.fromDate(item.lastDoneAt!),
          'nextDueAt': Timestamp.fromDate(item.nextDueAt),
          'notes': item.notes,
          'memberId': item.memberId,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.careItems)..where((t) => t.id.equals(item.id)))
          .write(const CareItemsCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullCare(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('care')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.careItems,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.careItems)
          .insertOnConflictUpdate(
            CareItemsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              category: Value(data['category'] as String? ?? 'Home'),
              cadenceDays: Value(data['cadenceDays'] as int? ?? 7),
              lastDoneAt: Value((data['lastDoneAt'] as Timestamp?)?.toDate()),
              nextDueAt:
                  (data['nextDueAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              notes: Value(data['notes'] as String? ?? ''),
              memberId: Value(data['memberId'] as String? ?? ''),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushCareProfiles(String nestId) async {
    final dirty = await (_db.select(
      _db.careProfiles,
    )..where((t) => t.dirty.equals(true))).get();
    for (final profile in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('careProfiles')
          .doc(profile.id);
      if (profile.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'memberId': profile.memberId,
          'medications': profile.medications,
          'allergies': profile.allergies,
          'mobilityNotes': profile.mobilityNotes,
          'primaryDoctor': profile.primaryDoctor,
          'notes': profile.notes,
          'updatedAt': Timestamp.fromDate(profile.updatedAt),
          'createdAt': Timestamp.fromDate(profile.createdAt),
        });
      }
      await (_db.update(_db.careProfiles)
            ..where((t) => t.id.equals(profile.id)))
          .write(const CareProfilesCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullCareProfiles(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('careProfiles')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.careProfiles,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.careProfiles)
          .insertOnConflictUpdate(
            CareProfilesCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              memberId: data['memberId'] as String? ?? doc.id,
              medications: Value(data['medications'] as String? ?? ''),
              allergies: Value(data['allergies'] as String? ?? ''),
              mobilityNotes: Value(data['mobilityNotes'] as String? ?? ''),
              primaryDoctor: Value(data['primaryDoctor'] as String? ?? ''),
              notes: Value(data['notes'] as String? ?? ''),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }

  Future<void> _pushSchool(String nestId) async {
    final dirty = await (_db.select(
      _db.schoolActivities,
    )..where((t) => t.dirty.equals(true))).get();
    for (final item in dirty) {
      final ref = _firestore
          .collection('nests')
          .doc(nestId)
          .collection('school')
          .doc(item.id);
      if (item.deleted) {
        await ref.delete();
      } else {
        await ref.set({
          'title': item.title,
          'kind': item.kind,
          'cadenceDays': item.cadenceDays,
          'lastDoneAt': item.lastDoneAt == null
              ? null
              : Timestamp.fromDate(item.lastDoneAt!),
          'nextAt': Timestamp.fromDate(item.nextAt),
          'location': item.location,
          'memberId': item.memberId,
          'notes': item.notes,
          'updatedAt': Timestamp.fromDate(item.updatedAt),
          'createdAt': Timestamp.fromDate(item.createdAt),
        });
      }
      await (_db.update(_db.schoolActivities)
            ..where((t) => t.id.equals(item.id)))
          .write(const SchoolActivitiesCompanion(dirty: Value(false)));
    }
  }

  Future<void> _pullSchool(String nestId) async {
    final snap = await _firestore
        .collection('nests')
        .doc(nestId)
        .collection('school')
        .get();
    for (final doc in snap.docs) {
      final data = doc.data();
      final remoteUpdated =
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      final local = await (_db.select(
        _db.schoolActivities,
      )..where((t) => t.id.equals(doc.id))).getSingleOrNull();
      if (local != null &&
          _shouldKeepLocal(
            dirty: local.dirty,
            localUpdated: local.updatedAt,
            remoteUpdated: remoteUpdated,
          )) {
        continue;
      }
      await _db
          .into(_db.schoolActivities)
          .insertOnConflictUpdate(
            SchoolActivitiesCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              kind: Value(data['kind'] as String? ?? 'School'),
              cadenceDays: Value(data['cadenceDays'] as int? ?? 7),
              lastDoneAt: Value((data['lastDoneAt'] as Timestamp?)?.toDate()),
              nextAt:
                  (data['nextAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              location: Value(data['location'] as String? ?? ''),
              memberId: Value(data['memberId'] as String? ?? ''),
              notes: Value(data['notes'] as String? ?? ''),
              dirty: const Value(false),
              createdAt: Value(
                (data['createdAt'] as Timestamp?)?.toDate() ?? remoteUpdated,
              ),
              updatedAt: Value(remoteUpdated),
            ),
          );
    }
  }
}

/// Thrown internally when auth disappears mid-[SyncService.syncAll].
class _SignedOutDuringSync implements Exception {
  const _SignedOutDuringSync();
}
