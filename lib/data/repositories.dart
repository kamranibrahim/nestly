import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Task>> watchAll() {
    return (_db.select(_db.tasks)
          ..orderBy([
            (t) => OrderingTerm(expression: t.done),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Stream<int> watchOpenCount() {
    final countExp = _db.tasks.id.count();
    final query = _db.selectOnly(_db.tasks)
      ..addColumns([countExp])
      ..where(_db.tasks.done.equals(false));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> toggleDone(Task task) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        done: Value(!task.done),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addTask({
    required String title,
    String assigneeId = 'dad',
    String dueLabel = 'Today',
  }) {
    final now = DateTime.now();
    return _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            title: title.trim(),
            assigneeId: Value(assigneeId),
            dueLabel: Value(dueLabel),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> deleteTask(String id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }
}

class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();
  static const defaultListId = 'list-groceries';

  Stream<List<ShoppingItem>> watchItems({String listId = defaultListId}) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId))
          ..orderBy([
            (i) => OrderingTerm(expression: i.done),
            (i) => OrderingTerm(expression: i.sortOrder),
          ]))
        .watch();
  }

  Stream<int> watchOpenCount({String listId = defaultListId}) {
    final countExp = _db.shoppingItems.id.count();
    final query = _db.selectOnly(_db.shoppingItems)
      ..addColumns([countExp])
      ..where(
        _db.shoppingItems.listId.equals(listId) &
            _db.shoppingItems.done.equals(false),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> toggleDone(ShoppingItem item) {
    return (_db.update(_db.shoppingItems)
          ..where((i) => i.id.equals(item.id)))
        .write(
      ShoppingItemsCompanion(
        done: Value(!item.done),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addItem({
    required String name,
    String listId = defaultListId,
    String category = 'General',
    String qty = '1',
  }) async {
    final now = DateTime.now();
    final maxOrder = await (_db.selectOnly(_db.shoppingItems)
          ..addColumns([_db.shoppingItems.sortOrder.max()])
          ..where(_db.shoppingItems.listId.equals(listId)))
        .getSingle();
    final nextOrder =
        (maxOrder.read(_db.shoppingItems.sortOrder.max()) ?? -1) + 1;

    await _db.into(_db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            id: _uuid.v4(),
            listId: listId,
            name: name.trim(),
            category: Value(category),
            qty: Value(qty),
            sortOrder: Value(nextOrder),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> deleteItem(String id) {
    return (_db.delete(_db.shoppingItems)..where((i) => i.id.equals(id))).go();
  }
}
