import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/repositories.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authState();
});

final nestInfoProvider = FutureProvider<NestInfo?>((ref) async {
  final user = await ref.watch(authStateProvider.future);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).currentNest();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.watch(databaseProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(databaseProvider));
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(databaseProvider));
});

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(databaseProvider));
});

final tasksProvider = StreamProvider<List<Task>>((ref) {
  return ref.watch(taskRepositoryProvider).watchAll();
});

final openTaskCountProvider = StreamProvider<int>((ref) {
  return ref.watch(taskRepositoryProvider).watchOpenCount();
});

final shoppingItemsProvider = StreamProvider<List<ShoppingItem>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchItems();
});

final openShoppingCountProvider = StreamProvider<int>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchOpenCount();
});

final eventsProvider = StreamProvider<List<CalendarEvent>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAll();
});

final membersProvider = StreamProvider<List<NestMember>>((ref) {
  return ref.watch(memberRepositoryProvider).watchAll();
});
