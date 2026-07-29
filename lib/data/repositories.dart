import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Task>> watchAll() {
    return (_db.select(_db.tasks)
          ..where((t) => t.deleted.equals(false))
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
      ..where(_db.tasks.done.equals(false) & _db.tasks.deleted.equals(false));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> toggleDone(Task task) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        done: Value(!task.done),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addTask({
    required String title,
    String assigneeId = 'dad',
    String dueLabel = 'Today',
    String? nestId,
  }) async {
    final now = DateTime.now();
    final resolvedNest =
        nestId ?? await _db.getMeta('nestId');
    await _db.into(_db.tasks).insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(resolvedNest),
            title: title.trim(),
            assigneeId: Value(assigneeId),
            dueLabel: Value(dueLabel),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> deleteTask(String id) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();
  static const defaultListId = 'list-groceries';

  Stream<List<ShoppingItem>> watchItems({String listId = defaultListId}) {
    return (_db.select(_db.shoppingItems)
          ..where(
            (i) => i.listId.equals(listId) & i.deleted.equals(false),
          )
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
            _db.shoppingItems.done.equals(false) &
            _db.shoppingItems.deleted.equals(false),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> toggleDone(ShoppingItem item) {
    return (_db.update(_db.shoppingItems)
          ..where((i) => i.id.equals(item.id)))
        .write(
      ShoppingItemsCompanion(
        done: Value(!item.done),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addItem({
    required String name,
    String listId = defaultListId,
    String category = 'General',
    String qty = '1',
    String? nestId,
  }) async {
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    final maxOrder = await (_db.selectOnly(_db.shoppingItems)
          ..addColumns([_db.shoppingItems.sortOrder.max()])
          ..where(_db.shoppingItems.listId.equals(listId)))
        .getSingle();
    final nextOrder =
        (maxOrder.read(_db.shoppingItems.sortOrder.max()) ?? -1) + 1;

    await _db.into(_db.shoppingItems).insert(
          ShoppingItemsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(resolvedNest),
            listId: listId,
            name: name.trim(),
            category: Value(category),
            qty: Value(qty),
            sortOrder: Value(nextOrder),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> deleteItem(String id) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id)))
        .write(
      ShoppingItemsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<CalendarEvent>> watchAll() {
    return (_db.select(_db.calendarEvents)
          ..where((e) => e.deleted.equals(false))
          ..orderBy([(e) => OrderingTerm(expression: e.startsAt)]))
        .watch();
  }

  Stream<List<CalendarEvent>> watchForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (_db.select(_db.calendarEvents)
          ..where(
            (e) =>
                e.deleted.equals(false) &
                e.startsAt.isBiggerOrEqualValue(start) &
                e.startsAt.isSmallerThanValue(end),
          )
          ..orderBy([(e) => OrderingTerm(expression: e.startsAt)]))
        .watch();
  }

  Future<void> addEvent({
    required String title,
    required DateTime startsAt,
    String memberId = 'dad',
    String category = 'Family',
    String? location,
    bool allDay = false,
    String? nestId,
  }) async {
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    await _db.into(_db.calendarEvents).insert(
          CalendarEventsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(resolvedNest),
            title: title.trim(),
            memberId: Value(memberId),
            category: Value(category),
            location: Value(location),
            startsAt: startsAt,
            allDay: Value(allDay),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }
}

class MemberRepository {
  MemberRepository(this._db);

  final AppDatabase _db;

  Stream<List<NestMember>> watchAll() {
    return (_db.select(_db.nestMembers)
          ..orderBy([(m) => OrderingTerm(expression: m.name)]))
        .watch();
  }

  Future<List<NestMember>> getAll() {
    return _db.select(_db.nestMembers).get();
  }

  Future<NestMember?> byId(String id) {
    return (_db.select(_db.nestMembers)..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }
}
