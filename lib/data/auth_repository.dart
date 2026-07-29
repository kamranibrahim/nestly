import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'repositories.dart';

class NestInfo {
  const NestInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  final String id;
  final String name;
  final String inviteCode;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
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
    return cred;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();

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
      _firestore.collection('nests').doc(nestId).collection('members').doc(user.uid),
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

    return NestInfo(id: nestId, name: nestName.trim(), inviteCode: inviteCode);
  }

  Future<NestInfo> joinNest({
    required String inviteCode,
    required String memberName,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Must be signed in to join a nest');
    }

    final code = inviteCode.trim().toUpperCase();
    final invite = await _firestore.collection('inviteCodes').doc(code).get();
    if (!invite.exists) {
      throw StateError('Invite code not found');
    }
    final nestId = invite.data()!['nestId'] as String;
    final nest = await _firestore.collection('nests').doc(nestId).get();
    final nestName = nest.data()?['name'] as String? ?? 'Family';

    final colors = [
      0xFFB2B2E6,
      0xFFD4E7B3,
      0xFFFFD8A8,
      0xFFF5C6D8,
      0xFFC5E8E0,
    ];
    final color = colors[Random().nextInt(colors.length)];

    final batch = _firestore.batch();
    batch.set(
      _firestore.collection('nests').doc(nestId).collection('members').doc(user.uid),
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

    return NestInfo(id: nestId, name: nestName, inviteCode: code);
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
    final existing = await (_db.select(_db.shoppingLists)
          ..where((l) => l.id.equals(ShoppingRepository.defaultListId)))
        .getSingleOrNull();
    if (existing != null) return;
    final now = DateTime.now();
    await _db.into(_db.shoppingLists).insert(
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
    await _db.batch((b) {
      b.deleteAll(_db.nestMembers);
      for (final doc in snap.docs) {
        final data = doc.data();
        b.insert(
          _db.nestMembers,
          NestMembersCompanion.insert(
            id: doc.id,
            nestId: nestId,
            name: data['name'] as String? ?? 'Member',
            role: Value(data['role'] as String? ?? 'Member'),
            initials: data['initials'] as String? ?? '?',
            colorValue: data['colorValue'] as int? ?? 0xFF4A78DD,
            dirty: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> syncAll() async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return;

    try {
      await _pushTasks(nestId);
      await _pullTasks(nestId);
      await _pushShopping(nestId);
      await _pullShopping(nestId);
      await _pushEvents(nestId);
      await _pullEvents(nestId);
      await _pushExpenses(nestId);
      await _pullExpenses(nestId);
      await _pushBills(nestId);
      await _pullBills(nestId);
      await _pushEmergency(nestId);
      await _pullEmergency(nestId);
      await _pushVault(nestId);
      await _pullVault(nestId);
      await _pushTimeline(nestId);
      await _pullTimeline(nestId);
      await _pushMeals(nestId);
      await _pullMeals(nestId);
      await _pushCare(nestId);
      await _pullCare(nestId);
      await _pushSchool(nestId);
      await _pullSchool(nestId);
      await pullMembers(nestId);
      await _db.setMeta('lastSyncAt', DateTime.now().toIso8601String());
    } catch (e, st) {
      debugPrint('Sync failed: $e\n$st');
      rethrow;
    }
  }

  Future<void> _pushTasks(String nestId) async {
    final dirty = await (_db.select(_db.tasks)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.tasks)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.tasks).insertOnConflictUpdate(
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
    final dirtyLists = await (_db.select(_db.shoppingLists)
          ..where((t) => t.dirty.equals(true)))
        .get();
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

    final dirtyItems = await (_db.select(_db.shoppingItems)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      await _db.into(_db.shoppingLists).insertOnConflictUpdate(
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
      final local = await (_db.select(_db.shoppingItems)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.shoppingItems).insertOnConflictUpdate(
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
    final dirty = await (_db.select(_db.calendarEvents)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.calendarEvents)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.calendarEvents).insertOnConflictUpdate(
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
    final dirty = await (_db.select(_db.expenses)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.expenses)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.expenses).insertOnConflictUpdate(
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
    final dirty = await (_db.select(_db.bills)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      await (_db.update(_db.bills)..where((t) => t.id.equals(item.id)))
          .write(const BillsCompanion(dirty: Value(false)));
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
      final local = await (_db.select(_db.bills)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.bills).insertOnConflictUpdate(
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

  Future<void> _pushEmergency(String nestId) async {
    final dirty = await (_db.select(_db.emergencyEntries)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.emergencyEntries)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.emergencyEntries).insertOnConflictUpdate(
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
    final dirty = await (_db.select(_db.vaultDocuments)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.vaultDocuments)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.vaultDocuments).insertOnConflictUpdate(
            VaultDocumentsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              category: Value(data['category'] as String? ?? 'Family'),
              fileName: data['fileName'] as String? ?? 'file',
              storagePath: Value(data['storagePath'] as String?),
              mimeType: Value(data['mimeType'] as String?),
              sizeBytes: Value(data['sizeBytes'] as int? ?? 0),
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
    final dirty = await (_db.select(_db.timelineEvents)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.timelineEvents)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null && local.dirty) continue;
      await _db.into(_db.timelineEvents).insertOnConflictUpdate(
            TimelineEventsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              message: data['message'] as String? ??
                  data['text'] as String? ??
                  '',
              memberId: Value(data['memberId'] as String? ?? ''),
              memberName: Value(data['memberName'] as String? ?? 'Family'),
              dirty: const Value(false),
              createdAt: Value(created),
            ),
          );
    }
  }

  Future<void> _pushMeals(String nestId) async {
    final dirty = await (_db.select(_db.mealPlans)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.mealPlans)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.mealPlans).insertOnConflictUpdate(
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
    final dirty = await (_db.select(_db.careItems)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.careItems)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.careItems).insertOnConflictUpdate(
            CareItemsCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              category: Value(data['category'] as String? ?? 'Home'),
              cadenceDays: Value(data['cadenceDays'] as int? ?? 7),
              lastDoneAt: Value(
                (data['lastDoneAt'] as Timestamp?)?.toDate(),
              ),
              nextDueAt: (data['nextDueAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
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
    final dirty = await (_db.select(_db.schoolActivities)
          ..where((t) => t.dirty.equals(true)))
        .get();
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
      final local = await (_db.select(_db.schoolActivities)
            ..where((t) => t.id.equals(doc.id)))
          .getSingleOrNull();
      if (local != null &&
          (local.dirty || local.updatedAt.isAfter(remoteUpdated))) {
        continue;
      }
      await _db.into(_db.schoolActivities).insertOnConflictUpdate(
            SchoolActivitiesCompanion.insert(
              id: doc.id,
              nestId: Value(nestId),
              title: data['title'] as String? ?? '',
              kind: Value(data['kind'] as String? ?? 'School'),
              cadenceDays: Value(data['cadenceDays'] as int? ?? 7),
              lastDoneAt: Value(
                (data['lastDoneAt'] as Timestamp?)?.toDate(),
              ),
              nextAt: (data['nextAt'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
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
