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
    String assigneeId = '',
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
    String memberId = '',
    String category = 'Family',
    String? location,
    bool allDay = false,
    DateTime? endsAt,
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
            endsAt: Value(endsAt),
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

class MealRepository {
  MealRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  static const weekdays = [
    (1, 'Mon'),
    (2, 'Tue'),
    (3, 'Wed'),
    (4, 'Thu'),
    (5, 'Fri'),
    (6, 'Sat'),
    (7, 'Sun'),
  ];

  Stream<List<MealPlan>> watchAll() {
    return (_db.select(_db.mealPlans)
          ..where((m) => m.deleted.equals(false))
          ..orderBy([
            (m) => OrderingTerm(expression: m.weekday),
            (m) => OrderingTerm(expression: m.mealType),
          ]))
        .watch();
  }

  Stream<List<MealPlan>> watchForWeekday(int weekday) {
    return (_db.select(_db.mealPlans)
          ..where(
            (m) => m.deleted.equals(false) & m.weekday.equals(weekday),
          )
          ..orderBy([(m) => OrderingTerm(expression: m.mealType)]))
        .watch();
  }

  Future<void> upsert({
    String? id,
    required int weekday,
    required String title,
    String mealType = 'Dinner',
    String ingredients = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final mealId = id ?? _uuid.v4();
    await _db.into(_db.mealPlans).insertOnConflictUpdate(
          MealPlansCompanion.insert(
            id: mealId,
            nestId: Value(nestId),
            weekday: weekday,
            mealType: Value(mealType),
            title: title.trim(),
            ingredients: Value(ingredients.trim()),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> delete(String id) {
    return (_db.update(_db.mealPlans)..where((m) => m.id.equals(id))).write(
      MealPlansCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Parses ingredients (comma or newline) and adds missing ones to groceries.
  Future<int> addIngredientsToShopping(MealPlan meal) async {
    final raw = meal.ingredients
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (raw.isEmpty) return 0;

    final shopping = ShoppingRepository(_db);
    final existing = await shopping.watchItems().first;
    final openNames = existing
        .where((i) => !i.done)
        .map((i) => i.name.toLowerCase())
        .toSet();

    var added = 0;
    for (final name in raw) {
      if (openNames.contains(name.toLowerCase())) continue;
      await shopping.addItem(name: name, category: 'Meals');
      openNames.add(name.toLowerCase());
      added++;
    }
    if (added > 0) {
      await TimelineRepository(_db).add(
        message: 'Added $added ingredient${added == 1 ? '' : 's'} for ${meal.title}',
        memberName: 'You',
      );
    }
    return added;
  }
}

class CareRepository {
  CareRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<CareItem>> watchAll() {
    return (_db.select(_db.careItems)
          ..where((c) => c.deleted.equals(false))
          ..orderBy([(c) => OrderingTerm(expression: c.nextDueAt)]))
        .watch();
  }

  Stream<int> watchDueCount() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final countExp = _db.careItems.id.count();
    final query = _db.selectOnly(_db.careItems)
      ..addColumns([countExp])
      ..where(
        _db.careItems.deleted.equals(false) &
            _db.careItems.nextDueAt.isSmallerOrEqualValue(endOfToday),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> add({
    required String title,
    String category = 'Home',
    int cadenceDays = 7,
    String notes = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final due = DateTime(now.year, now.month, now.day)
        .add(Duration(days: cadenceDays));
    await _db.into(_db.careItems).insert(
          CareItemsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            title: title.trim(),
            category: Value(category),
            cadenceDays: Value(cadenceDays),
            nextDueAt: due,
            notes: Value(notes.trim()),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> markDone(CareItem item) async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day)
        .add(Duration(days: item.cadenceDays));
    await (_db.update(_db.careItems)..where((c) => c.id.equals(item.id)))
        .write(
      CareItemsCompanion(
        lastDoneAt: Value(now),
        nextDueAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Completed care: ${item.title}',
      memberName: 'You',
    );
  }

  Future<void> delete(String id) {
    return (_db.update(_db.careItems)..where((c) => c.id.equals(id))).write(
      CareItemsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class SchoolRepository {
  SchoolRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<SchoolActivity>> watchAll() {
    return (_db.select(_db.schoolActivities)
          ..where((s) => s.deleted.equals(false))
          ..orderBy([(s) => OrderingTerm(expression: s.nextAt)]))
        .watch();
  }

  Stream<int> watchDueCount() {
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final countExp = _db.schoolActivities.id.count();
    final query = _db.selectOnly(_db.schoolActivities)
      ..addColumns([countExp])
      ..where(
        _db.schoolActivities.deleted.equals(false) &
            _db.schoolActivities.nextAt.isSmallerOrEqualValue(endOfToday),
      );
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<void> add({
    required String title,
    String kind = 'School',
    int cadenceDays = 7,
    String location = '',
    String memberId = '',
    String notes = '',
    DateTime? nextAt,
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final next = nextAt ??
        DateTime(now.year, now.month, now.day)
            .add(Duration(days: cadenceDays));
    await _db.into(_db.schoolActivities).insert(
          SchoolActivitiesCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            title: title.trim(),
            kind: Value(kind),
            cadenceDays: Value(cadenceDays),
            nextAt: next,
            location: Value(location.trim()),
            memberId: Value(memberId),
            notes: Value(notes.trim()),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> markDone(SchoolActivity item) async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month, now.day)
        .add(Duration(days: item.cadenceDays));
    await (_db.update(_db.schoolActivities)..where((s) => s.id.equals(item.id)))
        .write(
      SchoolActivitiesCompanion(
        lastDoneAt: Value(now),
        nextAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Done: ${item.title}',
      memberName: 'You',
    );
  }

  /// Creates a same-day task for a pickup / activity.
  Future<void> createPickupTask(SchoolActivity item) async {
    final loc = item.location.trim();
    final title = loc.isEmpty
        ? 'Pickup: ${item.title}'
        : 'Pickup: ${item.title} @ $loc';
    await TaskRepository(_db).addTask(title: title, dueLabel: 'Today');
    await TimelineRepository(_db).add(
      message: 'Added pickup task for ${item.title}',
      memberName: 'You',
    );
  }

  Future<void> delete(String id) {
    return (_db.update(_db.schoolActivities)..where((s) => s.id.equals(id)))
        .write(
      SchoolActivitiesCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
