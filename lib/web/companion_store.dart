import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Lightweight Firestore access for the laptop web companion (no Drift).
class CompanionStore {
  CompanionStore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get user => _auth.currentUser;

  Stream<User?> authState() => _auth.authStateChanges();

  Future<String?> nestIdForCurrentUser() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['nestId'] as String?;
  }

  Future<({String id, String name, String inviteCode})?> nestInfo() async {
    final nestId = await nestIdForCurrentUser();
    if (nestId == null) return null;
    final nest = await _firestore.collection('nests').doc(nestId).get();
    final data = nest.data();
    if (data == null) return null;
    return (
      id: nestId,
      name: data['name'] as String? ?? 'Family',
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }

  CollectionReference<Map<String, dynamic>> _col(String nestId, String name) {
    return _firestore.collection('nests').doc(nestId).collection(name);
  }

  Stream<List<Map<String, dynamic>>> watchEvents(String nestId) {
    return _col(nestId, 'events')
        .orderBy('startsAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              data['id'] = d.id;
              return data;
            }).toList());
  }

  Stream<List<Map<String, dynamic>>> watchTasks(String nestId) {
    return _col(nestId, 'tasks').snapshots().map((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).where((d) => d['deleted'] != true).toList();
      items.sort((a, b) {
        final aDone = a['done'] == true ? 1 : 0;
        final bDone = b['done'] == true ? 1 : 0;
        if (aDone != bDone) return aDone - bDone;
        return (b['updatedAt'] as Timestamp?)
                ?.compareTo(a['updatedAt'] as Timestamp? ?? Timestamp(0, 0)) ??
            0;
      });
      return items;
    });
  }

  Stream<List<Map<String, dynamic>>> watchShopping(String nestId) {
    return _col(nestId, 'shoppingItems').snapshots().map((snap) {
      final items = snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return data;
      }).where((d) => d['deleted'] != true).toList();
      items.sort((a, b) {
        final aDone = a['done'] == true ? 1 : 0;
        final bDone = b['done'] == true ? 1 : 0;
        if (aDone != bDone) return aDone - bDone;
        return ((a['sortOrder'] as int?) ?? 0) - ((b['sortOrder'] as int?) ?? 0);
      });
      return items;
    });
  }

  Future<void> toggleTask(String nestId, String id, bool done) {
    return _col(nestId, 'tasks').doc(id).set({
      'done': !done,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> toggleShopping(String nestId, String id, bool done) {
    return _col(nestId, 'shoppingItems').doc(id).set({
      'done': !done,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addShoppingItem(String nestId, String name) {
    final id = _firestore.collection('_').doc().id;
    return _col(nestId, 'shoppingItems').doc(id).set({
      'listId': 'list-groceries',
      'name': name.trim(),
      'category': 'General',
      'qty': '1',
      'done': false,
      'sortOrder': DateTime.now().millisecondsSinceEpoch,
      'deleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTask(String nestId, String title) {
    final id = _firestore.collection('_').doc().id;
    return _col(nestId, 'tasks').doc(id).set({
      'title': title.trim(),
      'assigneeId': _auth.currentUser?.uid ?? '',
      'dueLabel': 'Today',
      'done': false,
      'recurring': false,
      'deleted': false,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signOut() => _auth.signOut();
}
