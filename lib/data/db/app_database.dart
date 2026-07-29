import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get assigneeId => text().withDefault(const Constant('dad'))();
  TextColumn get dueLabel => text().withDefault(const Constant('Today'))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  BoolColumn get recurring => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text().references(ShoppingLists, #id)();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get qty => text().withDefault(const Constant('1'))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Tasks, ShoppingLists, ShoppingItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nestly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  /// Seeds sample household data the first time the DB is empty.
  Future<void> ensureSeeded() async {
    final taskCount = await (select(tasks)..limit(1)).get();
    final listCount = await (select(shoppingLists)..limit(1)).get();
    if (taskCount.isNotEmpty || listCount.isNotEmpty) return;

    final now = DateTime.now();

    await batch((b) {
      b.insertAll(tasks, [
        TasksCompanion.insert(
          id: 'task-1',
          title: 'Buy groceries',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Today'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-2',
          title: 'Pack soccer kit',
          assigneeId: const Value('ayaan'),
          dueLabel: const Value('Today'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-3',
          title: 'Water plants',
          assigneeId: const Value('noor'),
          dueLabel: const Value('Today'),
          done: const Value(true),
          recurring: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-4',
          title: 'Clean kitchen',
          assigneeId: const Value('mom'),
          dueLabel: const Value('Tomorrow'),
          recurring: const Value(true),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-5',
          title: 'Pay internet bill',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Fri'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      b.insert(
        shoppingLists,
        ShoppingListsCompanion.insert(
          id: 'list-groceries',
          name: 'Family Groceries',
          createdAt: Value(now),
        ),
      );

      b.insertAll(shoppingItems, [
        ShoppingItemsCompanion.insert(
          id: 'item-1',
          listId: 'list-groceries',
          name: 'Milk',
          category: const Value('Dairy'),
          qty: const Value('2 L'),
          sortOrder: const Value(0),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ShoppingItemsCompanion.insert(
          id: 'item-2',
          listId: 'list-groceries',
          name: 'Eggs',
          category: const Value('Dairy'),
          qty: const Value('12'),
          sortOrder: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ShoppingItemsCompanion.insert(
          id: 'item-3',
          listId: 'list-groceries',
          name: 'Bananas',
          category: const Value('Produce'),
          qty: const Value('1 kg'),
          done: const Value(true),
          sortOrder: const Value(2),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ShoppingItemsCompanion.insert(
          id: 'item-4',
          listId: 'list-groceries',
          name: 'Chicken breast',
          category: const Value('Meat'),
          qty: const Value('1 kg'),
          sortOrder: const Value(3),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ShoppingItemsCompanion.insert(
          id: 'item-5',
          listId: 'list-groceries',
          name: 'Dish soap',
          category: const Value('Home'),
          qty: const Value('1'),
          sortOrder: const Value(4),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ShoppingItemsCompanion.insert(
          id: 'item-6',
          listId: 'list-groceries',
          name: 'Bread',
          category: const Value('Bakery'),
          qty: const Value('2'),
          sortOrder: const Value(5),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
    });
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});
