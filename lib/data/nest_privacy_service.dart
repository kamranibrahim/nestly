import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import 'auth_repository.dart';
import 'db/app_database.dart';
import 'locator_models.dart';
import 'nest_home_widget.dart';
import 'repositories.dart';

/// Nest-scoped Firestore collections that sync from the client.
const nestCloudSubcollections = <String>[
  'members',
  'locations',
  'tasks',
  'shoppingLists',
  'shoppingItems',
  'events',
  'expenses',
  'bills',
  'emergency',
  'vault',
  'timeline',
  'meals',
  'care',
  'careProfiles',
  'school',
];

/// Export / leave / delete helpers for privacy and store compliance (no paywall).
class NestPrivacyService {
  NestPrivacyService(
    this._db, {
    AuthRepository? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _authRepo = auth ?? AuthRepository(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  final AppDatabase _db;
  final AuthRepository _authRepo;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<Map<String, dynamic>> buildExportPayload() async {
    final nest = await _authRepo.currentNest();
    final user = FirebaseAuth.instance.currentUser;

    final members = await _db.select(_db.nestMembers).get();
    final tasks = await _db.select(_db.tasks).get();
    final lists = await _db.select(_db.shoppingLists).get();
    final items = await _db.select(_db.shoppingItems).get();
    final events = await _db.select(_db.calendarEvents).get();
    final expenses = await _db.select(_db.expenses).get();
    final bills = await _db.select(_db.bills).get();
    final emergency = await _db.select(_db.emergencyEntries).get();
    final vault = await _db.select(_db.vaultDocuments).get();
    final timeline = await _db.select(_db.timelineEvents).get();
    final meals = await _db.select(_db.mealPlans).get();
    final care = await _db.select(_db.careItems).get();
    final careProfiles = await _db.select(_db.careProfiles).get();
    final school = await _db.select(_db.schoolActivities).get();
    final groceryHabits = await _db.select(_db.groceryHabits).get();
    final expenseRepo = ExpenseRepository(_db);
    final monthBudget = await expenseRepo.getMonthBudget();
    final tomorrowPreview = await expenseRepo.getTomorrowPreviewEnabled();

    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'app': 'casaio',
      'version': '1.0.0',
      'account': {'uid': user?.uid, 'email': user?.email},
      'nest': nest == null
          ? null
          : {
              'id': nest.id,
              'name': nest.name,
              'inviteCode': nest.inviteCode,
            },
      'settings': {
        'monthBudget': monthBudget,
        'tomorrowPreviewEnabled': tomorrowPreview,
      },
      'data': {
        'members': members.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'shoppingLists': lists.map((e) => e.toJson()).toList(),
        'shoppingItems': items.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'bills': bills.map((e) => e.toJson()).toList(),
        'emergency': emergency.map((e) => e.toJson()).toList(),
        'vault': vault.map((e) => e.toJson()).toList(),
        'timeline': timeline.map((e) => e.toJson()).toList(),
        'meals': meals.map((e) => e.toJson()).toList(),
        'care': care.map((e) => e.toJson()).toList(),
        'careProfiles': careProfiles.map((e) => e.toJson()).toList(),
        'school': school.map((e) => e.toJson()).toList(),
        'groceryHabits': groceryHabits.map((e) => e.toJson()).toList(),
      },
      'notes': [
        'Vault file binaries are not included — only document titles, folders, and metadata.',
        'To re-download vault files, open Casaio while signed in and use Vault.',
        'Budget and nest preference settings are included under settings.',
        'Locator last-known pins are nest-scoped and opt-in; binaries and live GPS streams are not exported.',
      ],
    };
  }

  Future<void> shareExport({AppLocalizations? l10n}) async {
    final payload = await buildExportPayload();
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final bytes = utf8.encode(json);
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: 'nestly-export-$stamp.json',
          ),
        ],
        subject: l10n?.privacyExportSubject ?? 'Casaio data export',
        text: l10n?.privacyExportShareText ??
            'Your Casaio nest export (JSON). Vault file binaries are not included.',
      ),
    );
  }

  /// Leaves the current nest but keeps the Casaio account signed in.
  ///
  /// Removes this user from the nest member list and clears local household
  /// data. If this was the last member, wipes the nest (Firestore + Storage).
  Future<void> leaveNest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final nestId = userDoc.data()?['nestId'] as String?;
    if (nestId == null || nestId.isEmpty) {
      throw StateError('You are not in a nest.');
    }

    await _detachFromNest(nestId: nestId, uid: user.uid);

    await _firestore.collection('users').doc(user.uid).set({
      'nestId': FieldValue.delete(),
    }, SetOptions(merge: true));

    try {
      await NestHomeWidget.clear();
    } catch (_) {}

    await _db.clearHouseholdData();
    await _db.setMeta('nestId', '');
    await _db.setMeta('householdClean', '0');
    await _db.setMeta(locatorSharingMetaKey, '0');
    await _db.setMeta(locatorLastLatMetaKey, '');
    await _db.setMeta(locatorLastLngMetaKey, '');
    await _db.setMeta(locatorLastAtMetaKey, '');
    await _db.setMeta(locatorLastLabelMetaKey, '');
    await _db.setMeta(locatorLastAccuracyMetaKey, '');
  }

  /// Leaves the nest (wiping it if last member), deletes Auth user + profile,
  /// then wipes local DB.
  ///
  /// Pass [password] so Casaio can reauthenticate when Firebase requires a
  /// recent login (common for account deletion).
  Future<void> deleteAccount({required String password}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }
    if (password.trim().isEmpty) {
      throw StateError('Enter your password to delete your account.');
    }

    await _authRepo.reauthenticateWithPassword(password.trim());

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final nestId = userDoc.data()?['nestId'] as String?;

    if (nestId != null && nestId.isNotEmpty) {
      await _detachFromNest(nestId: nestId, uid: user.uid);
    }

    try {
      await _firestore.collection('users').doc(user.uid).delete();
    } catch (_) {}

    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw StateError(
          'For security, sign out, sign back in, then delete your account again.',
        );
      }
      rethrow;
    }

    try {
      await NestHomeWidget.clear();
    } catch (_) {}

    await _db.clearHouseholdData();
    await _db.delete(_db.syncMeta).go();
  }

  /// Removes [uid] from the nest. If they were the last member, deletes the
  /// nest document, invite code, all synced subcollections, and vault Storage.
  Future<void> _detachFromNest({
    required String nestId,
    required String uid,
  }) async {
    final nestRef = _firestore.collection('nests').doc(nestId);
    final membersSnap = await nestRef.collection('members').get();
    final otherMembers = membersSnap.docs.where((d) => d.id != uid).length;
    final isLastMember = otherMembers == 0;

    if (isLastMember) {
      await wipeNestCloudData(
        firestore: _firestore,
        storage: _storage,
        nestId: nestId,
      );
      return;
    }

    try {
      await nestRef.collection('locations').doc(uid).delete();
    } catch (_) {}
    try {
      await nestRef.collection('members').doc(uid).delete();
    } catch (_) {}
  }
}

/// Deletes nest Storage vault files, all known subcollections, invite code,
/// and the nest document. Safe to call when the caller is the last member.
Future<void> wipeNestCloudData({
  required FirebaseFirestore firestore,
  required FirebaseStorage storage,
  required String nestId,
}) async {
  await _deleteStorageTree(storage.ref('nests/$nestId'));

  final nestRef = firestore.collection('nests').doc(nestId);
  String? inviteCode;
  try {
    final nest = await nestRef.get();
    inviteCode = nest.data()?['inviteCode'] as String?;
  } catch (_) {}

  for (final name in nestCloudSubcollections) {
    await _deleteCollection(nestRef.collection(name));
  }

  if (inviteCode != null && inviteCode.isNotEmpty) {
    try {
      await firestore.collection('inviteCodes').doc(inviteCode).delete();
    } catch (_) {}
  }

  try {
    await nestRef.delete();
  } catch (_) {}
}

Future<void> _deleteCollection(CollectionReference<Map<String, dynamic>> col) async {
  const page = 400;
  while (true) {
    final snap = await col.limit(page).get();
    if (snap.docs.isEmpty) return;
    final batch = col.firestore.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (snap.docs.length < page) return;
  }
}

Future<void> _deleteStorageTree(Reference root) async {
  try {
    final listed = await root.listAll();
    for (final item in listed.items) {
      try {
        await item.delete();
      } catch (_) {}
    }
    for (final prefix in listed.prefixes) {
      await _deleteStorageTree(prefix);
    }
  } catch (_) {}
}
