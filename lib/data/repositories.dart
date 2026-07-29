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

  Future<void> toggleDone(Task task) async {
    final markingDone = !task.done;
    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        done: Value(markingDone),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (markingDone) {
      await TimelineRepository(_db).add(
        message: 'Completed "${task.title}"',
        memberName: 'You',
      );
    }
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

  Future<void> toggleDone(ShoppingItem item) async {
    final markingDone = !item.done;
    await (_db.update(_db.shoppingItems)
          ..where((i) => i.id.equals(item.id)))
        .write(
      ShoppingItemsCompanion(
        done: Value(markingDone),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (markingDone) {
      await TimelineRepository(_db).add(
        message: 'Checked off ${item.name}',
        memberName: 'You',
      );
    }
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

class ExpenseRepository {
  ExpenseRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();
  static const monthBudget = 1800.0;

  Stream<List<Expense>> watchAll() {
    return (_db.select(_db.expenses)
          ..where((e) => e.deleted.equals(false))
          ..orderBy([(e) => OrderingTerm.desc(e.spentAt)]))
        .watch();
  }

  Stream<double> watchMonthTotal() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);
    final sum = _db.expenses.amount.sum();
    final query = _db.selectOnly(_db.expenses)
      ..addColumns([sum])
      ..where(
        _db.expenses.deleted.equals(false) &
            _db.expenses.spentAt.isBiggerOrEqualValue(start) &
            _db.expenses.spentAt.isSmallerThanValue(end),
      );
    return query.watchSingle().map((row) => row.read(sum) ?? 0);
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    String category = 'General',
    String paidBy = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    await _db.into(_db.expenses).insert(
          ExpensesCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            title: title.trim(),
            category: Value(category),
            amount: amount,
            paidBy: Value(paidBy),
            spentAt: Value(now),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }
}

class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Bill>> watchAll() {
    return (_db.select(_db.bills)
          ..where((b) => b.deleted.equals(false))
          ..orderBy([
            (b) => OrderingTerm(expression: b.paid),
            (b) => OrderingTerm(expression: b.dueAt),
          ]))
        .watch();
  }

  Future<List<Bill>> getUnpaidUpcoming() {
    return (_db.select(_db.bills)
          ..where((b) => b.deleted.equals(false) & b.paid.equals(false)))
        .get();
  }

  Future<void> togglePaid(Bill bill) {
    return (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
      BillsCompanion(
        paid: Value(!bill.paid),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> addBill({
    required String title,
    required double amount,
    required DateTime dueAt,
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    await _db.into(_db.bills).insert(
          BillsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            title: title.trim(),
            amount: amount,
            dueAt: dueAt,
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }
}

class EmergencyRepository {
  EmergencyRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<EmergencyEntry>> watchAll() {
    return (_db.select(_db.emergencyEntries)
          ..where((e) => e.deleted.equals(false))
          ..orderBy([(e) => OrderingTerm(expression: e.sortOrder)]))
        .watch();
  }

  Future<void> upsert({
    String? id,
    required String label,
    required String value,
    String iconName = 'info',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final entryId = id ?? _uuid.v4();
    await _db.into(_db.emergencyEntries).insertOnConflictUpdate(
          EmergencyEntriesCompanion.insert(
            id: entryId,
            nestId: Value(nestId),
            label: label.trim(),
            value: value.trim(),
            iconName: Value(iconName),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
  }
}

class TimelineRepository {
  TimelineRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<TimelineEvent>> watchRecent({int limit = 40}) {
    return (_db.select(_db.timelineEvents)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<void> add({
    required String message,
    String memberId = '',
    String memberName = 'Family',
  }) async {
    final nestId = await _db.getMeta('nestId');
    await _db.into(_db.timelineEvents).insert(
          TimelineEventsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            message: message,
            memberId: Value(memberId),
            memberName: Value(memberName),
            dirty: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
  }
}

class VaultRepository {
  VaultRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<VaultDocument>> watchAll({String? category}) {
    final query = _db.select(_db.vaultDocuments)
      ..where((d) => d.deleted.equals(false))
      ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]);
    if (category != null && category != 'All') {
      query.where((d) => d.category.equals(category));
    }
    return query.watch();
  }

  Stream<int> watchCount() {
    final count = _db.vaultDocuments.id.count();
    final query = _db.selectOnly(_db.vaultDocuments)
      ..addColumns([count])
      ..where(_db.vaultDocuments.deleted.equals(false));
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<VaultDocument> addLocalMeta({
    required String title,
    required String category,
    required String fileName,
    String? localPath,
    String? mimeType,
    int sizeBytes = 0,
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final id = _uuid.v4();
    final companion = VaultDocumentsCompanion.insert(
      id: id,
      nestId: Value(nestId),
      title: title,
      category: Value(category),
      fileName: fileName,
      localPath: Value(localPath),
      mimeType: Value(mimeType),
      sizeBytes: Value(sizeBytes),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.vaultDocuments).insert(companion);
    return (await (_db.select(_db.vaultDocuments)
          ..where((d) => d.id.equals(id)))
        .getSingle());
  }

  Future<void> markUploaded({
    required String id,
    required String storagePath,
  }) {
    return (_db.update(_db.vaultDocuments)..where((d) => d.id.equals(id)))
        .write(
      VaultDocumentsCompanion(
        storagePath: Value(storagePath),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
