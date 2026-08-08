import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/data/enums.dart';
import 'package:nestly/data/repositories.dart';
import 'package:nestly/data/vault_upload_status.dart';

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
    final dueToday = DateTime(2026, 8, 8);
    final dueTomorrow = DateTime(2026, 8, 9);
    await tasks.addTask(
      title: 'Walk dog',
      assigneeId: 'dad',
      dueAt: dueToday,
      recurring: false,
    );
    final added = (await tasks.watchAll().first)
        .firstWhere((t) => t.title == 'Walk dog');

    await tasks.updateTask(
      id: added.id,
      title: 'Walk the dog',
      assigneeId: 'mom',
      dueAt: dueTomorrow,
      recurring: true,
      cadenceDays: 7,
    );

    final updated = (await tasks.watchAll().first)
        .firstWhere((t) => t.id == added.id);
    expect(updated.title, 'Walk the dog');
    expect(updated.assigneeId, 'mom');
    expect(updated.dueAt?.year, 2026);
    expect(updated.dueAt?.month, 8);
    expect(updated.dueAt?.day, 9);
    expect(updated.cadenceDays, 7);
    expect(updated.recurring, isTrue);
  });

  test('recurring task advances dueAt by cadence and stays open', () async {
    final dueToday = DateTime(2026, 8, 8);
    await tasks.addTask(
      title: 'Water plants',
      dueAt: dueToday,
      recurring: true,
      cadenceDays: 7,
    );
    final task = (await tasks.watchAll().first)
        .firstWhere((t) => t.title == 'Water plants');
    expect(task.dueAt?.day, 8);
    await tasks.toggleDone(task);
    final after =
        (await tasks.watchAll().first).firstWhere((t) => t.id == task.id);
    expect(after.done, isFalse);
    expect(after.dueAt?.day, 15);
    expect(after.dueAt?.month, 8);
    expect(after.cadenceDays, 7);
  });

  test('non-recurring task completes when toggled done', () async {
    await tasks.addTask(title: 'One-off chore', recurring: false);
    final task = (await tasks.watchAll().first)
        .firstWhere((t) => t.title == 'One-off chore');
    await tasks.toggleDone(task);
    final after =
        (await tasks.watchAll().first).firstWhere((t) => t.id == task.id);
    expect(after.done, isTrue);
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

  test('second shopping list isolates items', () async {
    final second = await shopping.addList(name: 'Pharmacy');
    await shopping.addItem(
      name: 'Bandages',
      category: 'Health',
      listId: second.id,
    );
    await shopping.addItem(name: 'Soap', category: 'Home');

    final defaultItems = await shopping.watchItems().first;
    final pharmacyItems = await shopping.watchItems(listId: second.id).first;

    expect(defaultItems.any((i) => i.name == 'Soap'), isTrue);
    expect(defaultItems.any((i) => i.name == 'Bandages'), isFalse);
    expect(pharmacyItems.any((i) => i.name == 'Bandages'), isTrue);
    expect(pharmacyItems.any((i) => i.name == 'Soap'), isFalse);
  });

  test('soft-deleting a list hides it and its items', () async {
    final temp = await shopping.addList(name: 'Costco');
    await shopping.addItem(name: 'Bulk rice', listId: temp.id);
    await shopping.softDeleteList(temp.id);

    final lists = await shopping.watchLists().first;
    expect(lists.any((l) => l.id == temp.id), isFalse);

    final items = await shopping.watchItems(listId: temp.id).first;
    expect(items, isEmpty);

    await shopping.softDeleteList(ShoppingRepository.defaultListId);
    final listsAfter = await shopping.watchLists().first;
    expect(listsAfter.any((l) => l.id == ShoppingRepository.defaultListId), isTrue);
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

  test('recipe library apply fills slot and soft-delete hides', () async {
    final recipe = await meals.addRecipe(
      title: 'Chicken curry',
      ingredients: 'Chicken, Curry paste, Rice',
    );

    await meals.applyRecipeToMealPlan(
      recipeId: recipe.id,
      weekday: 3,
      mealType: 'Dinner',
    );

    final wedMeals = await meals.watchForWeekday(3).first;
    final dinner = wedMeals.firstWhere((m) => m.mealType == 'Dinner');
    expect(dinner.title, 'Chicken curry');
    expect(dinner.ingredients, contains('Chicken'));

    final added = await meals.addIngredientsToShopping(dinner);
    expect(added, greaterThan(0));

    await meals.deleteRecipe(recipe.id);
    final recipes = await meals.watchRecipes().first;
    expect(recipes.any((r) => r.id == recipe.id), isFalse);
  });

  test('saveMealAsRecipe copies slot to library', () async {
    await meals.upsert(
      weekday: 5,
      title: 'Taco night',
      ingredients: 'Tortillas, Beef, Salsa',
    );
    final slot = (await meals.watchForWeekday(5).first).first;

    final saved = await meals.saveMealAsRecipe(slot);
    expect(saved.title, 'Taco night');
    expect(saved.ingredients, contains('Tortillas'));

    final library = await meals.watchRecipes().first;
    expect(library.any((r) => r.id == saved.id), isTrue);
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

  test('vault upload status moves local → failed → synced', () async {
    final vault = VaultRepository(database);
    final doc = await vault.addLocalMeta(
      title: 'Insurance',
      category: 'Health',
      fileName: 'card.pdf',
      localPath: '/tmp/card.pdf',
    );
    expect(doc.uploadStatus, VaultUploadStatus.local.storage);

    await vault.markUploadFailed(doc.id);
    final failed = await vault.getById(doc.id);
    expect(failed?.uploadStatus, VaultUploadStatus.failed.storage);

    final pending = await vault.listPendingUploads();
    expect(pending.any((d) => d.id == doc.id), isTrue);

    await vault.markUploaded(id: doc.id, storagePath: 'nests/x/vault/y/card.pdf');
    final synced = await vault.getById(doc.id);
    expect(synced?.uploadStatus, VaultUploadStatus.synced.storage);
    expect(synced?.storagePath, isNot(null));
    expect(synced!.storagePath!.isNotEmpty, isTrue);

    final stillPending = await vault.listPendingUploads();
    expect(stillPending.any((d) => d.id == doc.id), isFalse);
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

  test('weekly recurring event expands to expected count', () async {
    final startsAt = DateTime(2026, 7, 6, 9); // Monday
    await events.addEvent(
      title: 'Pickup',
      startsAt: startsAt,
      memberId: 'dad',
      recurrence: EventRecurrence.weekly,
    );

    final stored = (await events.watchAll().first)
        .firstWhere((e) => e.title == 'Pickup');
    expect(stored.recurrence, EventRecurrence.weekly.storage);

    final expanded = events.expandInRange(
      [stored],
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 31),
    );
    expect(expanded, hasLength(4));
    expect(expanded.map((e) => e.startsAt.day).toList(), [6, 13, 20, 27]);
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

  test('month budget persists per nest and defaults to 1800', () async {
    await database.setMeta('nestId', 'nest-budget');
    final expenses = ExpenseRepository(database);

    expect(await expenses.getMonthBudget(), 1800);

    await expenses.setMonthBudget(2200);
    expect(await expenses.getMonthBudget(), 2200);
    expect(await expenses.watchMonthBudget().first, 2200);

    await expenses.addExpense(
      title: 'Week7 milk',
      amount: 40,
      category: 'W7Groceries',
    );
    await expenses.addExpense(
      title: 'Week7 gas',
      amount: 30,
      category: 'W7Transport',
    );
    final totals = await expenses.watchMonthCategoryTotals().first;
    final byCat = {for (final t in totals) t.category: t.total};
    expect(byCat['W7Groceries'], 40);
    expect(byCat['W7Transport'], 30);
    expect(totals.first.total, greaterThanOrEqualTo(totals.last.total));
  });

  test('zero or negative budget clamps to default', () async {
    await database.setMeta('nestId', 'nest-budget-clamp');
    final expenses = ExpenseRepository(database);
    await expenses.setMonthBudget(0);
    expect(await expenses.getMonthBudget(), 1800);
    await expenses.setMonthBudget(-50);
    expect(await expenses.getMonthBudget(), 1800);
  });

  test('tomorrow preview preference persists', () async {
    await database.setMeta('nestId', 'nest-preview');
    final expenses = ExpenseRepository(database);
    expect(await expenses.getTomorrowPreviewEnabled(), isFalse);
    await expenses.setTomorrowPreviewEnabled(true);
    expect(await expenses.getTomorrowPreviewEnabled(), isTrue);
    expect(await expenses.watchTomorrowPreviewEnabled().first, isTrue);
  });

  test('recurring bill advances due date when marked paid', () async {
    final bills = BillRepository(database);
    final due = DateTime(2026, 8, 1);

    await bills.addBill(
      title: 'Rent',
      amount: 1000,
      dueAt: due,
      cadenceDays: 30,
    );
    final recurring =
        (await bills.watchAll().first).firstWhere((b) => b.title == 'Rent');
    expect(recurring.cadenceDays, 30);
    expect(recurring.paid, isFalse);

    await bills.togglePaid(recurring);
    final afterRecurring =
        (await bills.watchAll().first).firstWhere((b) => b.id == recurring.id);
    expect(afterRecurring.paid, isFalse);
    expect(afterRecurring.dueAt, DateTime(2026, 8, 31));

    await bills.addBill(
      title: 'One-off fee',
      amount: 50,
      dueAt: due,
      cadenceDays: 0,
    );
    final oneOff =
        (await bills.watchAll().first).firstWhere((b) => b.title == 'One-off fee');
    await bills.togglePaid(oneOff);
    final paidOneOff =
        (await bills.watchAll().first).firstWhere((b) => b.id == oneOff.id);
    expect(paidOneOff.paid, isTrue);
    expect(paidOneOff.dueAt, due);
  });

  test('bills sort overdue unpaid before later dues and paid', () async {
    final bills = BillRepository(database);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await bills.addBill(
      title: 'Paid net',
      amount: 10,
      dueAt: today.subtract(const Duration(days: 2)),
    );
    final paid = (await bills.watchAll().first).first;
    await bills.togglePaid(paid);

    await bills.addBill(
      title: 'Future',
      amount: 20,
      dueAt: today.add(const Duration(days: 5)),
    );
    await bills.addBill(
      title: 'Overdue power',
      amount: 90,
      dueAt: today.subtract(const Duration(days: 3)),
    );

    final ordered = await bills.watchAll().first;
    expect(ordered.first.title, 'Overdue power');
    expect(ordered.last.paid, isTrue);
  });

  test('expenses and bills can be updated and deleted', () async {
    final expenses = ExpenseRepository(database);
    final bills = BillRepository(database);

    await expenses.addExpense(
      title: 'Coffee',
      amount: 4.5,
      category: 'Dining',
      paidBy: 'Kamran',
    );
    final expense = (await expenses.watchAll().first)
        .firstWhere((e) => e.title == 'Coffee');

    await expenses.updateExpense(
      id: expense.id,
      title: 'Latte',
      amount: 5.25,
      category: 'Groceries',
      paidBy: 'Sara',
    );
    final updatedExpense =
        (await expenses.watchAll().first).firstWhere((e) => e.id == expense.id);
    expect(updatedExpense.title, 'Latte');
    expect(updatedExpense.amount, 5.25);
    expect(updatedExpense.category, 'Groceries');
    expect(updatedExpense.paidBy, 'Sara');

    await expenses.deleteExpense(expense.id);
    final afterDelete =
        (await expenses.watchAll().first).where((e) => e.id == expense.id);
    expect(afterDelete, isEmpty);

    final due = DateTime(2026, 8, 10);
    await bills.addBill(title: 'Gas', amount: 30, dueAt: due);
    final bill =
        (await bills.watchAll().first).firstWhere((b) => b.title == 'Gas');

    await bills.updateBill(
      id: bill.id,
      title: 'Natural gas',
      amount: 35.5,
      dueAt: due.add(const Duration(days: 5)),
    );
    final updatedBill =
        (await bills.watchAll().first).firstWhere((b) => b.id == bill.id);
    expect(updatedBill.title, 'Natural gas');
    expect(updatedBill.amount, 35.5);
    expect(updatedBill.dueAt.day, 15);

    await bills.deleteBill(bill.id);
    final billsLeft =
        (await bills.watchAll().first).where((b) => b.id == bill.id);
    expect(billsLeft, isEmpty);
  });

  test('addPost persists kind post', () async {
    final timeline = TimelineRepository(database);
    await timeline.addPost(
      body: 'Pizza night Friday?',
      memberId: 'dad',
      memberName: 'Kamran',
    );
    final events = await timeline.watchRecent().first;
    final post = events.firstWhere((e) => e.message == 'Pizza night Friday?');
    expect(post.kind, TimelineKind.post.storage);
    expect(post.memberId, 'dad');
    expect(post.memberName, 'Kamran');
  });
}
