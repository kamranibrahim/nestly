import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';

import 'auth_repository.dart';
import 'db/app_database.dart';

/// Export / delete helpers for privacy and store compliance (no paywall).
class NestPrivacyService {
  NestPrivacyService(this._db, {AuthRepository? auth})
      : _authRepo = auth ?? AuthRepository();

  final AppDatabase _db;
  final AuthRepository _authRepo;

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

    return {
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'app': 'nestly',
      'version': '1.0.0',
      'account': {
        'uid': user?.uid,
        'email': user?.email,
      },
      'nest': nest == null
          ? null
          : {
              'id': nest.id,
              'name': nest.name,
              'inviteCode': nest.inviteCode,
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
      'notes':
          'Vault file binaries are not included; only metadata. Re-download from Nestly while signed in if needed.',
    };
  }

  Future<void> shareExport() async {
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
        subject: 'Nestly data export',
        text: 'Your Nestly nest export',
      ),
    );
  }

  /// Leaves the nest, wipes local SQLite, deletes the Firebase user.
  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Not signed in');
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final nestId = userDoc.data()?['nestId'] as String?;

    if (nestId != null && nestId.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('nests')
            .doc(nestId)
            .collection('members')
            .doc(user.uid)
            .delete();
      } catch (_) {}
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
    } catch (_) {}

    await _db.clearHouseholdData();
    await _db.delete(_db.syncMeta).go();

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
  }
}
