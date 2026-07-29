import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/notification_service.dart';
import '../data/repositories.dart';
import '../data/vault_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref.watch(databaseProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(databaseProvider));
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

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(databaseProvider));
});

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository(ref.watch(databaseProvider));
});

final emergencyRepositoryProvider = Provider<EmergencyRepository>((ref) {
  return EmergencyRepository(ref.watch(databaseProvider));
});

final timelineRepositoryProvider = Provider<TimelineRepository>((ref) {
  return TimelineRepository(ref.watch(databaseProvider));
});

final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(ref.watch(databaseProvider));
});

final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService(ref.watch(databaseProvider));
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

final expensesProvider = StreamProvider<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});

final monthSpendProvider = StreamProvider<double>((ref) {
  return ref.watch(expenseRepositoryProvider).watchMonthTotal();
});

final billsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchAll();
});

final emergencyProvider = StreamProvider<List<EmergencyEntry>>((ref) {
  return ref.watch(emergencyRepositoryProvider).watchAll();
});

enum PendingAdd { none, event, task, shopping }

final pendingAddProvider = StateProvider<PendingAdd>((ref) => PendingAdd.none);

final timelineProvider = StreamProvider<List<TimelineEvent>>((ref) {
  return ref.watch(timelineRepositoryProvider).watchRecent();
});

final vaultCountProvider = StreamProvider<int>((ref) {
  return ref.watch(vaultRepositoryProvider).watchCount();
});

final vaultDocumentsProvider =
    StreamProvider.family<List<VaultDocument>, String>((ref, category) {
  return ref.watch(vaultRepositoryProvider).watchAll(category: category);
});
