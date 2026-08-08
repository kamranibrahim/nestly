import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'repositories.dart';
import 'task_due.dart';

/// Polished App Store showcase content for a real nest.
/// Writes local Drift rows as dirty so [SyncService.syncAll] pushes to Firestore.
class ShowcaseSeedService {
  ShowcaseSeedService(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  static const memberMom = 'mom';
  static const memberAyaan = 'ayaan';
  static const memberNoor = 'noor';

  Future<void> seed({required String nestId, required String ownerMemberId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dad = ownerMemberId;

    await _db.clearHouseholdData();
    await _db.setMeta('householdClean', '1');
    await _db.setMeta('nestId', nestId);

    await _db.batch((b) {
      b.insertAll(_db.nestMembers, [
        NestMembersCompanion.insert(
          id: dad,
          nestId: nestId,
          name: 'Kamran Ibrahim',
          role: const Value('Dad'),
          initials: 'K',
          colorValue: 0xFFB2B2E6,
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: memberMom,
          nestId: nestId,
          name: 'Sara Ibrahim',
          role: const Value('Mom'),
          initials: 'S',
          colorValue: 0xFFF5C6D8,
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: memberAyaan,
          nestId: nestId,
          name: 'Ayaan Ibrahim',
          role: const Value('Son'),
          initials: 'A',
          colorValue: 0xFFD4E7B3,
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: memberNoor,
          nestId: nestId,
          name: 'Noor Ibrahim',
          role: const Value('Daughter'),
          initials: 'N',
          colorValue: 0xFFFFD8A8,
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      ]);

      b.insertAll(_db.tasks, [
        _task('School drop-off', dad, 'Today', now, recurring: true),
        _task('Pack soccer kit', memberAyaan, 'Today', now),
        _task('Water the plants', memberNoor, 'Today', now,
            done: true, recurring: true),
        _task('Prep family dinner', memberMom, 'Today', now, recurring: true),
        _task('Pay internet bill', dad, 'Fri', now),
        _task('Sign permission slip', memberMom, 'Tomorrow', now),
        _task('Empty dishwasher', memberAyaan, 'Today', now, recurring: true),
      ]);

      b.insert(
        _db.shoppingLists,
        ShoppingListsCompanion.insert(
          id: ShoppingRepository.defaultListId,
          nestId: Value(nestId),
          name: 'Family Groceries',
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      b.insertAll(_db.shoppingItems, [
        _shop('Organic milk', 'Dairy', '2 L', 0, now),
        _shop('Free-range eggs', 'Dairy', '12', 1, now),
        _shop('Bananas', 'Produce', '1 kg', 2, now, done: true),
        _shop('Chicken breast', 'Meat', '1 kg', 3, now),
        _shop('Sourdough bread', 'Bakery', '2', 4, now),
        _shop('Baby spinach', 'Produce', '200 g', 5, now),
        _shop('Dish soap', 'Home', '1', 6, now),
        _shop('Greek yogurt', 'Dairy', '4', 7, now, done: true),
      ]);

      b.insertAll(_db.calendarEvents, [
        _event(
          'School drop-off',
          dad,
          'School',
          today.add(const Duration(hours: 7, minutes: 45)),
          now,
          location: 'Greenfield Academy',
          endsAt: today.add(const Duration(hours: 8, minutes: 15)),
        ),
        _event(
          'Dentist — Noor',
          memberMom,
          'Health',
          today.add(const Duration(hours: 11, minutes: 30)),
          now,
          location: 'SmileCare Clinic',
          endsAt: today.add(const Duration(hours: 12, minutes: 15)),
        ),
        _event(
          'Soccer practice',
          memberAyaan,
          'Sports',
          today.add(const Duration(hours: 16, minutes: 30)),
          now,
          location: 'City Field B',
          endsAt: today.add(const Duration(hours: 18)),
        ),
        _event(
          'Family dinner',
          memberMom,
          'Family',
          today.add(const Duration(hours: 19)),
          now,
          location: 'Home',
          endsAt: today.add(const Duration(hours: 20)),
        ),
        _event(
          'Parent-teacher meeting',
          dad,
          'School',
          today.add(const Duration(days: 1, hours: 15)),
          now,
          location: 'Greenfield Academy',
          endsAt: today.add(const Duration(days: 1, hours: 15, minutes: 45)),
        ),
        _event(
          "Ayaan's birthday",
          memberAyaan,
          'Birthday',
          today.add(const Duration(days: 4)),
          now,
          allDay: true,
        ),
        _event(
          'Car service',
          dad,
          'Home',
          today.add(const Duration(days: 5, hours: 10)),
          now,
          location: 'AutoCare Center',
          endsAt: today.add(const Duration(days: 5, hours: 12)),
        ),
      ]);

      b.insertAll(_db.expenses, [
        _expense('Weekly groceries', 'Groceries', 86.40, 'Kamran', today, now),
        _expense('Fuel', 'Transport', 42, 'Sara',
            today.subtract(const Duration(days: 1)), now),
        _expense('School supplies', 'Kids', 28.50, 'Sara',
            today.subtract(const Duration(days: 3)), now),
        _expense('Plumbing fix', 'Home', 120, 'Kamran',
            today.subtract(const Duration(days: 5)), now),
        _expense('Soccer club fees', 'Kids', 65, 'Kamran',
            today.subtract(const Duration(days: 7)), now),
      ]);

      b.insertAll(_db.bills, [
        _bill('Electricity', 64.20, today.add(const Duration(days: 3)), now,
            cadenceDays: 30),
        _bill('Internet', 49.99, today.add(const Duration(days: 5)), now,
            cadenceDays: 30),
        _bill('Water', 22.50, today.subtract(const Duration(days: 2)), now,
            paid: true),
        _bill('Rent', 1450, today.add(const Duration(days: 8)), now,
            cadenceDays: 30),
      ]);

      b.insertAll(_db.emergencyEntries, [
        _emergency('em-1', 'Emergency contact', 'Omar Ibrahim · +1 555 0142',
            'phone', 0, now),
        _emergency(
            'em-2', 'Family doctor', 'Dr. Patel · City Care', 'doctor', 1, now),
        _emergency('em-3', 'Nearest hospital', 'Riverside General · 8 min',
            'hospital', 2, now),
        _emergency('em-4', 'Allergies', 'Ayaan — peanuts · Noor — none',
            'warning', 3, now),
        _emergency(
            'em-5', 'Blood groups', 'K O+ · S A+ · A B+ · N O+', 'blood', 4, now),
        _emergency('em-6', 'Insurance', 'HealthPlus Family · #HP-88241',
            'shield', 5, now),
      ]);

      b.insertAll(_db.vaultDocuments, [
        _vault(
          'Passports',
          'IDs',
          'passports.pdf',
          now.subtract(const Duration(days: 14)),
          notes: 'Family passports — renew Noor 2027',
          expiresAt: today.add(const Duration(days: 400)),
        ),
        _vault(
          'Car insurance',
          'Car',
          'car-insurance.pdf',
          now.subtract(const Duration(days: 1)),
          notes: 'Policy #CI-44102',
          expiresAt: today.add(const Duration(days: 90)),
        ),
        _vault(
          'Birth certificates',
          'IDs',
          'birth-certificates.pdf',
          now.subtract(const Duration(days: 60)),
        ),
        _vault(
          'Home warranty',
          'Home',
          'home-warranty.pdf',
          now.subtract(const Duration(days: 120)),
          notes: 'Covers HVAC + appliances',
          expiresAt: today.add(const Duration(days: 200)),
        ),
        _vault(
          'School records',
          'Family',
          'school-records.pdf',
          now.subtract(const Duration(days: 7)),
          notes: 'Ayaan + Noor 2025–26',
        ),
      ]);

      b.insertAll(_db.timelineEvents, [
        _timeline('Kamran completed grocery shopping', dad, 'Kamran',
            now.subtract(const Duration(minutes: 20))),
        _timeline('Sara uploaded car insurance', memberMom, 'Sara',
            now.subtract(const Duration(hours: 1))),
        _timeline('Noor watered the plants', memberNoor, 'Noor',
            now.subtract(const Duration(hours: 2))),
        _timeline('Ayaan added soccer practice', memberAyaan, 'Ayaan',
            today.subtract(const Duration(days: 1)).add(const Duration(hours: 18))),
        _timeline('Water bill marked as paid', dad, 'Kamran',
            today.subtract(const Duration(days: 1)).add(const Duration(hours: 10))),
        _timeline(
          'Who can pick up Ayaan from soccer on Thursday?',
          memberMom,
          'Sara',
          now.subtract(const Duration(minutes: 45)),
          kind: 'post',
        ),
      ]);

      b.insertAll(_db.mealPlans, [
        _meal(1, 'Lemon herb chicken',
            'chicken breast, lemon, garlic, spinach, rice', now),
        _meal(2, 'Pasta primavera',
            'pasta, zucchini, cherry tomatoes, parmesan', now),
        _meal(3, 'Fish tacos',
            'white fish, tortillas, cabbage, lime, yogurt', now),
        _meal(4, 'Beef stir-fry',
            'beef, broccoli, soy sauce, ginger, rice', now),
        _meal(5, 'Homemade pizza night',
            'pizza dough, mozzarella, tomato sauce, basil', now),
        _meal(6, 'Grill & salad',
            'burgers, buns, mixed greens, avocado', now),
        _meal(7, 'Roast chicken Sunday',
            'whole chicken, potatoes, carrots, rosemary', now),
      ]);

      b.insertAll(_db.careItems, [
        CareItemsCompanion.insert(
          id: 'care-1',
          nestId: const Value(null),
          title: 'Walk Milo',
          category: const Value('Pet'),
          cadenceDays: const Value(1),
          lastDoneAt: Value(today.add(const Duration(hours: 7))),
          nextDueAt: today.add(const Duration(hours: 18)),
          notes: const Value('Evening walk around the park'),
          memberId: const Value(memberAyaan),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CareItemsCompanion.insert(
          id: 'care-2',
          title: 'Change HVAC filter',
          category: const Value('Home'),
          cadenceDays: const Value(90),
          lastDoneAt: Value(today.subtract(const Duration(days: 60))),
          nextDueAt: today.add(const Duration(days: 30)),
          notes: const Value('Filters in utility closet'),
          memberId: Value(dad),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CareItemsCompanion.insert(
          id: 'care-3',
          title: 'Car oil check',
          category: const Value('Car'),
          cadenceDays: const Value(30),
          lastDoneAt: Value(today.subtract(const Duration(days: 20))),
          nextDueAt: today.add(const Duration(days: 10)),
          notes: const Value('Honda CR-V'),
          memberId: Value(dad),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CareItemsCompanion.insert(
          id: 'care-4',
          title: 'Water houseplants',
          category: const Value('Home'),
          cadenceDays: const Value(3),
          lastDoneAt: Value(today.subtract(const Duration(days: 1))),
          nextDueAt: today.add(const Duration(days: 2)),
          memberId: const Value(memberNoor),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      b.insertAll(_db.careProfiles, [
        CareProfilesCompanion.insert(
          id: memberAyaan,
          memberId: memberAyaan,
          allergies: const Value('Peanuts — EpiPen in backpack'),
          primaryDoctor: const Value('Dr. Patel · City Care'),
          notes: const Value(
            'Soccer season — keep inhaler for asthma flare-ups',
          ),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CareProfilesCompanion.insert(
          id: memberNoor,
          memberId: memberNoor,
          allergies: const Value('None'),
          primaryDoctor: const Value('Dr. Patel · City Care'),
          notes: const Value('Upcoming dentist checkup today'),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      b.insertAll(_db.schoolActivities, [
        SchoolActivitiesCompanion.insert(
          id: 'school-1',
          title: 'Morning drop-off',
          kind: const Value('Pickup'),
          cadenceDays: const Value(1),
          lastDoneAt:
              Value(today.subtract(const Duration(days: 1)).add(const Duration(hours: 7, minutes: 45))),
          nextAt: today.add(const Duration(hours: 7, minutes: 45)),
          location: const Value('Greenfield Academy'),
          memberId: Value(dad),
          notes: const Value('Main gate'),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        SchoolActivitiesCompanion.insert(
          id: 'school-2',
          title: 'Soccer practice',
          kind: const Value('Sports'),
          cadenceDays: const Value(7),
          lastDoneAt:
              Value(today.subtract(const Duration(days: 7)).add(const Duration(hours: 16, minutes: 30))),
          nextAt: today.add(const Duration(hours: 16, minutes: 30)),
          location: const Value('City Field B'),
          memberId: const Value(memberAyaan),
          notes: const Value('Bring water bottle + shin guards'),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        SchoolActivitiesCompanion.insert(
          id: 'school-3',
          title: 'Piano lesson',
          kind: const Value('Club'),
          cadenceDays: const Value(7),
          lastDoneAt:
              Value(today.subtract(const Duration(days: 3)).add(const Duration(hours: 16))),
          nextAt: today.add(const Duration(days: 4, hours: 16)),
          location: const Value('Harmony Music'),
          memberId: const Value(memberNoor),
          notes: const Value('Book bag with sheet music'),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        SchoolActivitiesCompanion.insert(
          id: 'school-4',
          title: 'Afternoon pickup',
          kind: const Value('Pickup'),
          cadenceDays: const Value(1),
          lastDoneAt:
              Value(today.subtract(const Duration(days: 1)).add(const Duration(hours: 15, minutes: 15))),
          nextAt: today.add(const Duration(hours: 15, minutes: 15)),
          location: const Value('Greenfield Academy'),
          memberId: const Value(memberMom),
          notes: const Value('Car line B'),
          dirty: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
    });

    await _db.setMeta('showcaseSeededAt', now.toIso8601String());
  }

  TasksCompanion _task(
    String title,
    String assigneeId,
    String dueLabel,
    DateTime now, {
    bool done = false,
    bool recurring = false,
    int cadenceDays = 0,
  }) {
    final dueAt = resolveTaskDueAt(dueLabel: dueLabel, now: now);
    final resolvedCadence = effectiveTaskCadenceDays(
      recurring: recurring,
      cadenceDays: cadenceDays,
    );
    return TasksCompanion.insert(
      id: 'task-${_uuid.v4().substring(0, 8)}',
      title: title,
      assigneeId: Value(assigneeId),
      dueLabel: Value(dueLabelForDueAt(dueAt, now: now)),
      dueAt: Value(dueAt),
      cadenceDays: Value(resolvedCadence),
      done: Value(done),
      recurring: Value(recurring),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  ShoppingItemsCompanion _shop(
    String name,
    String category,
    String qty,
    int sortOrder,
    DateTime now, {
    bool done = false,
  }) {
    return ShoppingItemsCompanion.insert(
      id: 'item-${_uuid.v4().substring(0, 8)}',
      listId: ShoppingRepository.defaultListId,
      name: name,
      category: Value(category),
      qty: Value(qty),
      done: Value(done),
      sortOrder: Value(sortOrder),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  CalendarEventsCompanion _event(
    String title,
    String memberId,
    String category,
    DateTime startsAt,
    DateTime now, {
    String? location,
    DateTime? endsAt,
    bool allDay = false,
  }) {
    return CalendarEventsCompanion.insert(
      id: 'event-${_uuid.v4().substring(0, 8)}',
      title: title,
      memberId: Value(memberId),
      category: Value(category),
      location: Value(location),
      startsAt: startsAt,
      endsAt: Value(endsAt),
      allDay: Value(allDay),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  ExpensesCompanion _expense(
    String title,
    String category,
    double amount,
    String paidBy,
    DateTime spentAt,
    DateTime now,
  ) {
    return ExpensesCompanion.insert(
      id: 'exp-${_uuid.v4().substring(0, 8)}',
      title: title,
      category: Value(category),
      amount: amount,
      paidBy: Value(paidBy),
      spentAt: Value(spentAt),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  BillsCompanion _bill(
    String title,
    double amount,
    DateTime dueAt,
    DateTime now, {
    bool paid = false,
    int cadenceDays = 0,
  }) {
    return BillsCompanion.insert(
      id: 'bill-${_uuid.v4().substring(0, 8)}',
      title: title,
      amount: amount,
      dueAt: dueAt,
      cadenceDays: Value(cadenceDays),
      paid: Value(paid),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  EmergencyEntriesCompanion _emergency(
    String id,
    String label,
    String value,
    String iconName,
    int sortOrder,
    DateTime now,
  ) {
    return EmergencyEntriesCompanion.insert(
      id: id,
      label: label,
      value: value,
      iconName: Value(iconName),
      sortOrder: Value(sortOrder),
      dirty: const Value(true),
      updatedAt: Value(now),
    );
  }

  VaultDocumentsCompanion _vault(
    String title,
    String category,
    String fileName,
    DateTime at, {
    String notes = '',
    DateTime? expiresAt,
  }) {
    return VaultDocumentsCompanion.insert(
      id: 'vault-${_uuid.v4().substring(0, 8)}',
      title: title,
      category: Value(category),
      fileName: fileName,
      mimeType: const Value('application/pdf'),
      sizeBytes: const Value(200000),
      notes: Value(notes),
      expiresAt: Value(expiresAt),
      dirty: const Value(true),
      createdAt: Value(at),
      updatedAt: Value(at),
    );
  }

  TimelineEventsCompanion _timeline(
    String message,
    String memberId,
    String memberName,
    DateTime createdAt, {
    String kind = 'activity',
  }) {
    return TimelineEventsCompanion.insert(
      id: 'tl-${_uuid.v4().substring(0, 8)}',
      message: message,
      memberId: Value(memberId),
      memberName: Value(memberName),
      kind: Value(kind),
      dirty: const Value(true),
      createdAt: Value(createdAt),
      updatedAt: Value(createdAt),
    );
  }

  MealPlansCompanion _meal(
    int weekday,
    String title,
    String ingredients,
    DateTime now,
  ) {
    return MealPlansCompanion.insert(
      id: 'meal-$weekday',
      weekday: weekday,
      mealType: const Value('Dinner'),
      title: title,
      ingredients: Value(ingredients),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }
}
