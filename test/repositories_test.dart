import 'package:drift/drift.dart';
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
}
