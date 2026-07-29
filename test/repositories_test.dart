import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/data/repositories.dart';

void main() {
  late AppDatabase database;
  late TaskRepository tasks;
  late ShoppingRepository shopping;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.ensureSeeded();
    tasks = TaskRepository(database);
    shopping = ShoppingRepository(database);
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
    final first = (await tasks.watchAll().first).firstWhere((t) => !t.done);
    await tasks.toggleDone(first);
    final afterToggle =
        (await tasks.watchAll().first).firstWhere((t) => t.id == first.id);
    expect(afterToggle.done, isTrue);

    await tasks.addTask(title: 'Test chore', assigneeId: 'mom');
    final titles = (await tasks.watchAll().first).map((t) => t.title);
    expect(titles, contains('Test chore'));
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

  test('checking off items builds grocery habits and suggestions', () async {
    await shopping.addItem(name: 'Milk', category: 'Dairy');
    var milk = (await shopping.watchItems().first)
        .firstWhere((i) => i.name == 'Milk');
    await shopping.toggleDone(milk);

    await shopping.addItem(name: 'Milk', category: 'Dairy');
    milk = (await shopping.watchItems().first)
        .firstWhere((i) => i.name == 'Milk' && !i.done);
    await shopping.toggleDone(milk);

    final habits = await database.select(database.groceryHabits).get();
    final milkHabit = habits.firstWhere((h) => h.id == 'milk');
    expect(milkHabit.buyCount, 2);

    // Make habit stale so it surfaces as a suggestion.
    await (database.update(database.groceryHabits)
          ..where((h) => h.id.equals('milk')))
        .write(
      GroceryHabitsCompanion(
        lastBoughtAt: Value(DateTime.now().subtract(const Duration(days: 14))),
      ),
    );

    final suggestions = await shopping.watchSuggestions().first;
    expect(suggestions.any((s) => s.id == 'milk'), isTrue);

    await shopping.addSuggestion(milkHabit);
    final openNames = (await shopping.watchItems().first)
        .where((i) => !i.done)
        .map((i) => i.name);
    expect(openNames, contains('Milk'));
  });
}
