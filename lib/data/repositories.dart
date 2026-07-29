import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'db/app_database.dart';
import 'member_roles.dart';

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
    final now = DateTime.now();

    if (markingDone && task.recurring) {
      final nextLabel = nextDueLabel(task.dueLabel);
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          done: const Value(false),
          dueLabel: Value(nextLabel),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
      await TimelineRepository(_db).add(
        message: 'Completed "${task.title}" · next $nextLabel',
        memberName: 'You',
      );
      return;
    }

    await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        done: Value(markingDone),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    if (markingDone) {
      await TimelineRepository(_db).add(
        message: 'Completed "${task.title}"',
        memberName: 'You',
      );
    }
  }

  /// Advances recurring chore labels without a full calendar cadence.
  static String nextDueLabel(String current) {
    switch (current.trim().toLowerCase()) {
      case 'today':
        return 'Tomorrow';
      case 'tomorrow':
        return 'In 7 days';
      case 'in 7 days':
        return 'Today';
      default:
        return 'Tomorrow';
    }
  }

  Future<void> addTask({
    required String title,
    String assigneeId = '',
    String dueLabel = 'Today',
    bool recurring = false,
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
            recurring: Value(recurring),
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

  static String normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

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

  /// Habits ready to restock: bought 2+ times, past learned cadence, not open.
  Stream<List<GroceryHabit>> watchSuggestions({
    String listId = defaultListId,
  }) {
    return _db.select(_db.groceryHabits).watch().asyncMap((habits) async {
      final open = await (_db.select(_db.shoppingItems)
            ..where(
              (i) =>
                  i.listId.equals(listId) &
                  i.deleted.equals(false) &
                  i.done.equals(false),
            ))
          .get();
      final openNames = {
        for (final i in open) normalizeName(i.name),
      };
      final now = DateTime.now();
      final due = habits.where((h) {
        if (h.buyCount < 2) return false;
        if (openNames.contains(h.id)) return false;
        final staleDays = h.cadenceDays.clamp(2, 60);
        return now.difference(h.lastBoughtAt).inDays >= staleDays;
      }).toList()
        ..sort((a, b) {
          final aOverdue =
              now.difference(a.lastBoughtAt).inDays - a.cadenceDays;
          final bOverdue =
              now.difference(b.lastBoughtAt).inDays - b.cadenceDays;
          final byOverdue = bOverdue.compareTo(aOverdue);
          if (byOverdue != 0) return byOverdue;
          return b.buyCount.compareTo(a.buyCount);
        });
      return due.take(8).toList();
    });
  }

  /// Blend a new purchase gap into the habit cadence (days).
  static int blendCadence({
    required int previousCadence,
    required int gapDays,
    required int buyCount,
  }) {
    final gap = gapDays.clamp(1, 90);
    if (buyCount <= 2) return gap;
    // EMA: newer gaps weigh more as the habit matures.
    final weight = buyCount >= 6 ? 0.45 : 0.35;
    final blended = (previousCadence * (1 - weight)) + (gap * weight);
    return blended.round().clamp(2, 60);
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
      await _recordPurchase(item);
      await TimelineRepository(_db).add(
        message: 'Checked off ${item.name}',
        memberName: 'You',
      );
    }
  }

  Future<void> _recordPurchase(ShoppingItem item) async {
    final key = normalizeName(item.name);
    if (key.isEmpty) return;
    final now = DateTime.now();
    final existing = await (_db.select(_db.groceryHabits)
          ..where((h) => h.id.equals(key)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.groceryHabits).insert(
            GroceryHabitsCompanion.insert(
              id: key,
              name: item.name.trim(),
              category: Value(item.category),
              buyCount: const Value(1),
              cadenceDays: const Value(7),
              lastBoughtAt: now,
              updatedAt: Value(now),
            ),
          );
    } else {
      final gapDays = now.difference(existing.lastBoughtAt).inDays;
      final nextCount = existing.buyCount + 1;
      final cadence = blendCadence(
        previousCadence: existing.cadenceDays,
        gapDays: gapDays <= 0 ? existing.cadenceDays : gapDays,
        buyCount: nextCount,
      );
      await (_db.update(_db.groceryHabits)..where((h) => h.id.equals(key)))
          .write(
        GroceryHabitsCompanion(
          name: Value(item.name.trim()),
          category: Value(item.category),
          buyCount: Value(nextCount),
          cadenceDays: Value(cadence),
          lastBoughtAt: Value(now),
          updatedAt: Value(now),
        ),
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
    final key = normalizeName(name);
    final habit = key.isEmpty
        ? null
        : await (_db.select(_db.groceryHabits)..where((h) => h.id.equals(key)))
            .getSingleOrNull();
    final resolvedCategory =
        category == 'General' && habit != null ? habit.category : category;

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
            category: Value(resolvedCategory),
            qty: Value(qty),
            sortOrder: Value(nextOrder),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> addSuggestion(GroceryHabit habit) {
    return addItem(name: habit.name, category: habit.category);
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

  Future<void> updateEvent({
    required String id,
    required String title,
    required DateTime startsAt,
    String memberId = '',
    String category = 'Family',
    String? location,
    bool allDay = false,
    DateTime? endsAt,
  }) {
    return (_db.update(_db.calendarEvents)..where((e) => e.id.equals(id))).write(
      CalendarEventsCompanion(
        title: Value(title.trim()),
        memberId: Value(memberId),
        category: Value(category),
        location: Value(location),
        startsAt: Value(startsAt),
        endsAt: Value(endsAt),
        allDay: Value(allDay),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEvent(String id) {
    return (_db.update(_db.calendarEvents)..where((e) => e.id.equals(id))).write(
      CalendarEventsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
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

  Future<void> updateRole(String memberId, String role) {
    return (_db.update(_db.nestMembers)..where((m) => m.id.equals(memberId)))
        .write(
      NestMembersCompanion(
        role: Value(role),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
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

  Future<void> setLocalPath({
    required String id,
    required String localPath,
  }) {
    return (_db.update(_db.vaultDocuments)..where((d) => d.id.equals(id)))
        .write(
      VaultDocumentsCompanion(
        localPath: Value(localPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMeta({
    required String id,
    String? notes,
    DateTime? expiresAt,
    bool clearExpiry = false,
  }) {
    return (_db.update(_db.vaultDocuments)..where((d) => d.id.equals(id)))
        .write(
      VaultDocumentsCompanion(
        notes: notes == null ? const Value.absent() : Value(notes),
        expiresAt: clearExpiry
            ? const Value(null)
            : (expiresAt == null
                ? const Value.absent()
                : Value(expiresAt)),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.update(_db.vaultDocuments)..where((d) => d.id.equals(id)))
        .write(
      VaultDocumentsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Docs expiring within [withinDays] (includes already expired).
  Stream<List<VaultDocument>> watchExpiringSoon({int withinDays = 45}) {
    final cutoff =
        DateTime.now().add(Duration(days: withinDays)).add(const Duration(days: 1));
    return (_db.select(_db.vaultDocuments)
          ..where(
            (d) =>
                d.deleted.equals(false) &
                d.expiresAt.isNotNull() &
                d.expiresAt.isSmallerOrEqualValue(cutoff),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.expiresAt)]))
        .watch();
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

  Future<void> planDinnerWeek(Map<int, String> titlesByWeekday) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final existingDinners = await (_db.select(_db.mealPlans)
          ..where(
            (m) =>
                m.deleted.equals(false) & m.mealType.equals('Dinner'),
          ))
        .get();

    final byWeekday = <int, List<MealPlan>>{};
    for (final meal in existingDinners) {
      byWeekday.putIfAbsent(meal.weekday, () => []).add(meal);
    }

    for (final day in weekdays) {
      final weekday = day.$1;
      final title = (titlesByWeekday[weekday] ?? '').trim();
      final dinners = byWeekday[weekday] ?? const <MealPlan>[];
      final primary = dinners.isEmpty ? null : dinners.first;
      final extras = dinners.skip(1);

      for (final extra in extras) {
        await delete(extra.id);
      }

      if (title.isEmpty) {
        if (primary != null) {
          await delete(primary.id);
        }
        continue;
      }

      if (primary != null) {
        await (_db.update(_db.mealPlans)..where((m) => m.id.equals(primary.id)))
            .write(
          MealPlansCompanion(
            title: Value(title),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      } else {
        await _db.into(_db.mealPlans).insert(
              MealPlansCompanion.insert(
                id: _uuid.v4(),
                nestId: Value(nestId),
                weekday: weekday,
                mealType: const Value('Dinner'),
                title: title,
                dirty: const Value(true),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }
    }

    await TimelineRepository(_db).add(
      message: 'Planned dinner week',
      memberName: 'You',
    );
  }

  /// Parses ingredients (comma or newline) and adds missing ones to groceries.
  Future<int> addIngredientsToShopping(MealPlan meal) async {
    return addMealsIngredientsToShopping([meal], label: meal.title);
  }

  Future<int> addMealsIngredientsToShopping(
    Iterable<MealPlan> meals, {
    String? label,
  }) async {
    final raw = meals
        .expand((meal) => _parseIngredients(meal.ingredients))
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
      final target = label ?? 'meal plan';
      await TimelineRepository(_db).add(
        message: 'Added $added ingredient${added == 1 ? '' : 's'} for $target',
        memberName: 'You',
      );
    }
    return added;
  }

  List<String> _parseIngredients(String ingredients) {
    return ingredients
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
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
    String memberId = '',
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
            memberId: Value(memberId),
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

  Stream<List<CareProfile>> watchProfiles() {
    return (_db.select(_db.careProfiles)
          ..where((p) => p.deleted.equals(false))
          ..orderBy([(p) => OrderingTerm(expression: p.updatedAt)]))
        .watch();
  }

  Future<CareProfile?> profileForMember(String memberId) {
    return (_db.select(_db.careProfiles)
          ..where((p) => p.id.equals(memberId) & p.deleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> upsertProfile({
    required String memberId,
    String medications = '',
    String allergies = '',
    String mobilityNotes = '',
    String primaryDoctor = '',
    String notes = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final existing = await (_db.select(_db.careProfiles)
          ..where((p) => p.id.equals(memberId)))
        .getSingleOrNull();
    if (existing == null) {
      await _db.into(_db.careProfiles).insert(
            CareProfilesCompanion.insert(
              id: memberId,
              nestId: Value(nestId),
              memberId: memberId,
              medications: Value(medications.trim()),
              allergies: Value(allergies.trim()),
              mobilityNotes: Value(mobilityNotes.trim()),
              primaryDoctor: Value(primaryDoctor.trim()),
              notes: Value(notes.trim()),
              dirty: const Value(true),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    } else {
      await (_db.update(_db.careProfiles)..where((p) => p.id.equals(memberId)))
          .write(
        CareProfilesCompanion(
          nestId: Value(nestId),
          medications: Value(medications.trim()),
          allergies: Value(allergies.trim()),
          mobilityNotes: Value(mobilityNotes.trim()),
          primaryDoctor: Value(primaryDoctor.trim()),
          notes: Value(notes.trim()),
          deleted: const Value(false),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
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
    final members = await _db.select(_db.nestMembers).get();
    String assigneeId = '';
    for (final m in members) {
      if (MemberRoles.isAdultLike(m.role)) {
        assigneeId = m.id;
        break;
      }
    }
    if (assigneeId.isEmpty && members.isNotEmpty) {
      assigneeId = members.first.id;
    }
    await TaskRepository(_db).addTask(
      title: title,
      dueLabel: 'Today',
      assigneeId: assigneeId,
    );
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
