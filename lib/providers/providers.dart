import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/db/app_database.dart';
import '../data/locator_models.dart';
import '../data/locator_service.dart';
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

final grocerySuggestionsProvider = StreamProvider<List<GroceryHabit>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchSuggestions();
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

final monthBudgetProvider = StreamProvider<double>((ref) {
  return ref.watch(expenseRepositoryProvider).watchMonthBudget();
});

final tomorrowPreviewEnabledProvider = StreamProvider<bool>((ref) {
  return ref.watch(expenseRepositoryProvider).watchTomorrowPreviewEnabled();
});

final monthCategoryTotalsProvider =
    StreamProvider<List<({String category, double total})>>((ref) {
      return ref.watch(expenseRepositoryProvider).watchMonthCategoryTotals();
    });

final billsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchAll();
});

final emergencyProvider = StreamProvider<List<EmergencyEntry>>((ref) {
  return ref.watch(emergencyRepositoryProvider).watchAll();
});

enum PendingAdd { none, event, task, shopping }

final pendingAddProvider = StateProvider<PendingAdd>((ref) => PendingAdd.none);

/// Focus Calendar on a day (and optionally open an event sheet).
class CalendarFocus {
  const CalendarFocus({required this.day, this.eventId});

  final DateTime day;
  final String? eventId;
}

final calendarFocusProvider = StateProvider<CalendarFocus?>((ref) => null);

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

final vaultExpiringSoonProvider = StreamProvider<List<VaultDocument>>((ref) {
  return ref.watch(vaultRepositoryProvider).watchExpiringSoon();
});

final vaultFailedUploadsProvider = StreamProvider<List<VaultDocument>>((ref) {
  return ref.watch(vaultRepositoryProvider).watchFailedUploads();
});

final vaultFailedUploadCountProvider = StreamProvider<int>((ref) {
  return ref.watch(vaultRepositoryProvider).watchFailedUploadCount();
});

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(databaseProvider));
});

final careRepositoryProvider = Provider<CareRepository>((ref) {
  return CareRepository(ref.watch(databaseProvider));
});

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(ref.watch(databaseProvider));
});

final mealsProvider = StreamProvider<List<MealPlan>>((ref) {
  return ref.watch(mealRepositoryProvider).watchAll();
});

final careItemsProvider = StreamProvider<List<CareItem>>((ref) {
  return ref.watch(careRepositoryProvider).watchAll();
});

final careProfilesProvider = StreamProvider<List<CareProfile>>((ref) {
  return ref.watch(careRepositoryProvider).watchProfiles();
});

final careDueCountProvider = StreamProvider<int>((ref) {
  return ref.watch(careRepositoryProvider).watchDueCount();
});

final schoolActivitiesProvider = StreamProvider<List<SchoolActivity>>((ref) {
  return ref.watch(schoolRepositoryProvider).watchAll();
});

final schoolDueCountProvider = StreamProvider<int>((ref) {
  return ref.watch(schoolRepositoryProvider).watchDueCount();
});

final locatorServiceProvider = Provider<LocatorService>((ref) {
  return LocatorService(ref.watch(databaseProvider));
});

final locatorSharingProvider = FutureProvider<bool>((ref) async {
  return ref.watch(locatorServiceProvider).isSharingEnabled();
});

final nestLocationsProvider = StreamProvider<List<NestLocation>>((ref) {
  return ref.watch(locatorServiceProvider).watchNestLocations();
});
