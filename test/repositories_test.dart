import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/data/repositories.dart';

void main() {
  late AppDatabase database;
  late TaskRepository tasks;
  late ShoppingRepository shopping;
  late MealRepository meals;
  late EventRepository events;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.ensureSeeded();
    tasks = TaskRepository(database);
    shopping = ShoppingRepository(database);
    meals = MealRepository(database);
    events = EventRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seed creates open tasks and shopping items', () async {
    final taskList = await tasks.watchAll().first;
    final items = await shopping.watchItems().first;

    expect(taskList, isNotEmpty);
    expect(taskList.where((t) => !t.done).length, greaterThan(0));
    expect(items.where((i) => !i.done).length, greaterThan(0));
  });

  test('toggle and add task persist', () async {
    final first = (await tasks.watchAll().first)
        .firstWhere((t) => !t.done && !t.recurring);
    await tasks.toggleDone(first);
    final afterToggle =
        (await tasks.watchAll().first).firstWhere((t) => t.id == first.id);
    expect(afterToggle.done, isTrue);

    await tasks.addTask(title: 'Test chore', assigneeId: 'mom');
    final titles = (await tasks.watchAll().first).map((t) => t.title);
    expect(titles, contains('Test chore'));
  });

  test('tasks can be updated for assignee due and recurring', () async {
    await tasks.addTask(
      title: 'Walk dog',
      assigneeId: 'dad',
      dueLabel: 'Today',
      recurring: false,
    );
    final added = (await tasks.watchAll().first)
        .firstWhere((t) => t.title == 'Walk dog');

    await tasks.updateTask(
      id: added.id,
      title: 'Walk the dog',
      assigneeId: 'mom',
      dueLabel: 'Tomorrow',
      recurring: true,
    );

    final updated = (await tasks.watchAll().first)
        .firstWhere((t) => t.id == added.id);
    expect(updated.title, 'Walk the dog');
    expect(updated.assigneeId, 'mom');
    expect(updated.dueLabel, 'Tomorrow');
    expect(updated.recurring, isTrue);
  });

  test('recurring task rolls due label and stays open', () async {
    await tasks.addTask(
      title: 'Water plants',
      dueLabel: 'Today',
      recurring: true,
    );
    final task = (await tasks.watchAll().first)
        .firstWhere((t) => t.title == 'Water plants');
    await tasks.toggleDone(task);
    final after =
        (await tasks.watchAll().first).firstWhere((t) => t.id == task.id);
    expect(after.done, isFalse);
    expect(after.dueLabel, 'Tomorrow');
  });

  test('toggle and add shopping item persist', () async {
    final first =
        (await shopping.watchItems().first).firstWhere((i) => !i.done);
    await shopping.toggleDone(first);
    final afterToggle = (await shopping.watchItems().first)
        .firstWhere((i) => i.id == first.id);
    expect(afterToggle.done, isTrue);

    await shopping.addItem(name: 'Yogurt', category: 'Dairy');
    final names = (await shopping.watchItems().first).map((i) => i.name);
    expect(names, contains('Yogurt'));
  });

  test('shopping items can be updated for qty and category', () async {
    await shopping.addItem(name: 'Oats', category: 'Pantry', qty: '1');
    final added =
        (await shopping.watchItems().first).firstWhere((i) => i.name == 'Oats');

    await shopping.updateItem(
      id: added.id,
      name: 'Rolled oats',
      category: 'Bakery',
      qty: '2 kg',
    );

    final updated = (await shopping.watchItems().first)
        .firstWhere((i) => i.id == added.id);
    expect(updated.name, 'Rolled oats');
    expect(updated.category, 'Bakery');
    expect(updated.qty, '2 kg');
  });

  test('checking off items builds grocery habits and suggestions', () async {
    const name = 'Kefir';
    await shopping.addItem(name: name, category: 'Dairy');
    var item = (await shopping.watchItems().first)
        .firstWhere((i) => i.name == name && !i.done);
    await shopping.toggleDone(item);

    await shopping.addItem(name: name, category: 'Dairy');
    item = (await shopping.watchItems().first)
        .firstWhere((i) => i.name == name && !i.done);
    await shopping.toggleDone(item);

    final key = ShoppingRepository.normalizeName(name);
    final habits = await database.select(database.groceryHabits).get();
    final habit = habits.firstWhere((h) => h.id == key);
    expect(habit.buyCount, 2);

    await (database.update(database.groceryHabits)
          ..where((h) => h.id.equals(key)))
        .write(
      GroceryHabitsCompanion(
        cadenceDays: const Value(10),
        lastBoughtAt: Value(DateTime.now().subtract(const Duration(days: 14))),
      ),
    );

    final suggestions = await shopping.watchSuggestions().first;
    expect(suggestions.any((s) => s.id == key), isTrue);

    await shopping.addSuggestion(habit);
    final openNames = (await shopping.watchItems().first)
        .where((i) => !i.done)
        .map((i) => i.name);
    expect(openNames, contains(name));
  });

  test('plan dinner week replaces weekday dinners cleanly', () async {
    await meals.planDinnerWeek({
      1: 'Tacos',
      2: 'Pasta',
      3: '',
      4: 'Soup',
    });

    final allMeals = await meals.watchAll().first;
    final dinners = allMeals.where((m) => m.mealType == 'Dinner').toList();

    expect(
      dinners.where((m) => m.weekday == 1).map((m) => m.title),
      contains('Tacos'),
    );
    expect(
      dinners.where((m) => m.weekday == 2).map((m) => m.title),
      contains('Pasta'),
    );
    expect(
      dinners.where((m) => m.weekday == 4).map((m) => m.title),
      contains('Soup'),
    );
    expect(dinners.where((m) => m.weekday == 3), isEmpty);
  });

  test('adding week meal ingredients dedupes groceries', () async {
    await meals.upsert(
      weekday: 1,
      title: 'Tacos',
      ingredients: 'Tortillas, Avocado\nLime',
    );
    await meals.upsert(
      weekday: 2,
      title: 'Bowls',
      ingredients: 'Avocado, Rice',
    );

    final plannedMeals = await meals.watchAll().first;
    final added = await meals.addMealsIngredientsToShopping(
      plannedMeals.where((m) => m.mealType == 'Dinner'),
      label: 'this week',
    );

    expect(added, 4);

    final openNames = (await shopping.watchItems().first)
        .where((i) => !i.done)
        .map((i) => i.name);
    expect(openNames, containsAll(['Tortillas', 'Avocado', 'Lime', 'Rice']));
  });

  test('vault expiry meta is listed as expiring soon', () async {
    final vault = VaultRepository(database);
    final doc = await vault.addLocalMeta(
      title: 'Passport',
      category: 'IDs',
      fileName: 'passport.pdf',
    );
    await vault.updateMeta(
      id: doc.id,
      notes: 'Renew online',
      expiresAt: DateTime.now().add(const Duration(days: 10)),
    );

    final soon = await vault.watchExpiringSoon().first;
    expect(soon.any((d) => d.id == doc.id), isTrue);
    expect(soon.firstWhere((d) => d.id == doc.id).notes, 'Renew online');
  });

  test('vault docs can be renamed and moved between folders', () async {
    final vault = VaultRepository(database);
    final doc = await vault.addLocalMeta(
      title: 'Lease',
      category: 'House',
      fileName: 'lease.pdf',
    );

    await vault.updateMeta(
      id: doc.id,
      title: 'Apartment lease',
      category: 'Finance',
      notes: 'Signed copy',
    );

    final updated = (await vault.watchAll().first)
        .firstWhere((d) => d.id == doc.id);
    expect(updated.title, 'Apartment lease');
    expect(updated.category, 'Finance');
    expect(updated.notes, 'Signed copy');

    final finance = await vault.watchAll(category: 'Finance').first;
    expect(finance.any((d) => d.id == doc.id), isTrue);
  });

  test('calendar events can be updated and deleted', () async {
    final startsAt = DateTime(2026, 7, 29, 9);
    final endsAt = DateTime(2026, 7, 29, 10);

    await events.addEvent(
      title: 'Dentist',
      startsAt: startsAt,
      endsAt: endsAt,
      memberId: 'mom',
      location: 'Main Street Clinic',
    );

    final added = (await events.watchAll().first)
        .firstWhere((e) => e.title == 'Dentist');

    await events.updateEvent(
      id: added.id,
      title: 'Dentist check-in',
      startsAt: startsAt.add(const Duration(hours: 1)),
      endsAt: endsAt.add(const Duration(hours: 1)),
      memberId: 'dad',
      location: 'Clinic front desk',
      allDay: false,
      category: added.category,
    );

    final updated = (await events.watchAll().first)
        .firstWhere((e) => e.id == added.id);
    expect(updated.title, 'Dentist check-in');
    expect(updated.memberId, 'dad');
    expect(updated.location, 'Clinic front desk');
    expect(updated.startsAt.hour, 10);

    await events.deleteEvent(added.id);
    final remaining = await events.watchAll().first;
    expect(remaining.any((e) => e.id == added.id), isFalse);
  });

  test('school activities can be updated with next date and notes', () async {
    final school = SchoolRepository(database);
    final nextAt = DateTime(2026, 7, 30);
    await school.add(
      title: 'Soccer',
      kind: 'Sports',
      cadenceDays: 7,
      location: 'Field A',
      memberId: 'kid',
      nextAt: nextAt,
    );

    final added = (await school.watchAll().first)
        .firstWhere((s) => s.title == 'Soccer');

    await school.update(
      id: added.id,
      title: 'Soccer practice',
      kind: 'Sports',
      cadenceDays: 3,
      location: 'Field B',
      memberId: 'kid2',
      notes: 'Bring water bottle',
      nextAt: nextAt.add(const Duration(days: 2)),
    );

    final updated = (await school.watchAll().first)
        .firstWhere((s) => s.id == added.id);
    expect(updated.title, 'Soccer practice');
    expect(updated.cadenceDays, 3);
    expect(updated.location, 'Field B');
    expect(updated.memberId, 'kid2');
    expect(updated.notes, 'Bring water bottle');
    expect(updated.nextAt.day, 1);
    expect(updated.nextAt.month, 8);
  });
}
