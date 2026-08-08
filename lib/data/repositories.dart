import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'calendar_view_math.dart';
import 'db/app_database.dart';
import 'enums.dart';
import 'home_tips.dart';
import 'member_roles.dart';
import 'task_due.dart';

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
      final cadence = effectiveTaskCadenceDays(
        recurring: task.recurring,
        cadenceDays: task.cadenceDays,
      );
      final base = task.dueAt ?? now;
      final nextDue = advanceDueAt(base, cadence);
      final nextLabel = dueLabelForDueAt(nextDue, now: now);
      await (_db.update(_db.tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          done: const Value(false),
          dueAt: Value(nextDue),
          dueLabel: Value(nextLabel),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
      await TimelineRepository(_db).add(
        message: 'Completed "${task.title}" · next $nextLabel',
        memberName: 'You',
      );
      await maybeLogFirstSharedCheckoff(_db, kind: 'task');
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
      await TimelineRepository(
        _db,
      ).add(message: 'Completed "${task.title}"', memberName: 'You');
      await maybeLogFirstSharedCheckoff(_db, kind: 'task');
    }
  }

  /// Legacy label cycle — prefer [advanceDueAt] on [Task.dueAt].
  static String nextDueLabel(String current) =>
      TaskDueLabel.parse(current).next.label;

  Future<void> addTask({
    required String title,
    String assigneeId = '',
    String dueLabel = 'Today',
    DateTime? dueAt,
    bool recurring = false,
    int cadenceDays = 0,
    String? nestId,
  }) async {
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    final resolvedDue = resolveTaskDueAt(
      dueAt: dueAt,
      dueLabel: dueLabel,
      now: now,
    );
    final resolvedCadence = effectiveTaskCadenceDays(
      recurring: recurring,
      cadenceDays: cadenceDays,
    );
    final resolvedLabel = dueLabelForDueAt(resolvedDue, now: now);
    await _db
        .into(_db.tasks)
        .insert(
          TasksCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(resolvedNest),
            title: title.trim(),
            assigneeId: Value(assigneeId),
            dueLabel: Value(resolvedLabel),
            dueAt: Value(resolvedDue),
            cadenceDays: Value(resolvedCadence),
            recurring: Value(recurring),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> updateTask({
    required String id,
    required String title,
    String assigneeId = '',
    String dueLabel = 'Today',
    DateTime? dueAt,
    bool recurring = false,
    int cadenceDays = 0,
  }) {
    final now = DateTime.now();
    final resolvedDue = resolveTaskDueAt(
      dueAt: dueAt,
      dueLabel: dueLabel,
      now: now,
    );
    final resolvedCadence = effectiveTaskCadenceDays(
      recurring: recurring,
      cadenceDays: cadenceDays,
    );
    final resolvedLabel = dueLabelForDueAt(resolvedDue, now: now);
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        title: Value(title.trim()),
        assigneeId: Value(assigneeId),
        dueLabel: Value(resolvedLabel),
        dueAt: Value(resolvedDue),
        cadenceDays: Value(resolvedCadence),
        recurring: Value(recurring),
        dirty: const Value(true),
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

  Stream<List<ShoppingList>> watchLists() {
    return (_db.select(_db.shoppingLists)
          ..where((l) => l.deleted.equals(false))
          ..orderBy([
            (l) => OrderingTerm(
              expression: l.id.equals(defaultListId),
              mode: OrderingMode.desc,
            ),
            (l) => OrderingTerm(expression: l.createdAt),
          ]))
        .watch();
  }

  Future<void> ensureDefaultList({String? nestId}) async {
    final existing =
        await (_db.select(_db.shoppingLists)
              ..where((l) => l.id.equals(defaultListId)))
            .getSingleOrNull();
    if (existing != null) {
      if (existing.deleted) {
        final now = DateTime.now();
        await (_db.update(_db.shoppingLists)
              ..where((l) => l.id.equals(defaultListId)))
            .write(
          ShoppingListsCompanion(
            deleted: const Value(false),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
      return;
    }
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    await _db.into(_db.shoppingLists).insert(
          ShoppingListsCompanion.insert(
            id: defaultListId,
            nestId: Value(resolvedNest),
            name: 'Groceries',
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<ShoppingList> addList({
    required String name,
    String? nestId,
  }) async {
    await ensureDefaultList(nestId: nestId);
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('List name cannot be empty');
    }
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    final id = _uuid.v4();
    await _db.into(_db.shoppingLists).insert(
          ShoppingListsCompanion.insert(
            id: id,
            nestId: Value(resolvedNest),
            name: trimmed,
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (_db.select(_db.shoppingLists)..where((l) => l.id.equals(id)))
        .getSingle();
  }

  Future<void> renameList(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
      ShoppingListsCompanion(
        name: Value(trimmed),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> softDeleteList(String id) async {
    if (id == defaultListId) return;
    final now = DateTime.now();
    await (_db.update(_db.shoppingLists)..where((l) => l.id.equals(id))).write(
      ShoppingListsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await (_db.update(_db.shoppingItems)..where((i) => i.listId.equals(id)))
        .write(
      ShoppingItemsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Stream<List<ShoppingItem>> watchItems({String listId = defaultListId}) {
    return (_db.select(_db.shoppingItems)
          ..where((i) => i.listId.equals(listId) & i.deleted.equals(false))
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
  Stream<List<GroceryHabit>> watchSuggestions({String listId = defaultListId}) {
    return _db.select(_db.groceryHabits).watch().asyncMap((habits) async {
      final nestId = await _db.getMeta('nestId');
      final open =
          await (_db.select(_db.shoppingItems)..where(
                (i) =>
                    i.listId.equals(listId) &
                    i.deleted.equals(false) &
                    i.done.equals(false),
              ))
              .get();
      final openNames = {for (final i in open) normalizeName(i.name)};
      final now = DateTime.now();
      final due =
          habits.where((h) {
            if (h.deleted) return false;
            if (nestId != null &&
                nestId.isNotEmpty &&
                h.nestId != null &&
                h.nestId != nestId) {
              return false;
            }
            if (h.buyCount < 2) return false;
            if (openNames.contains(h.id)) return false;
            final staleDays = h.cadenceDays.clamp(2, 60);
            return now.difference(h.lastBoughtAt).inDays >= staleDays;
          }).toList()..sort((a, b) {
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
    await (_db.update(
      _db.shoppingItems,
    )..where((i) => i.id.equals(item.id))).write(
      ShoppingItemsCompanion(
        done: Value(markingDone),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    if (markingDone) {
      await _recordPurchase(item);
      await TimelineRepository(
        _db,
      ).add(message: 'Checked off ${item.name}', memberName: 'You');
      await maybeLogFirstSharedCheckoff(_db, kind: 'shopping');
    }
  }

  Future<void> _recordPurchase(ShoppingItem item) async {
    final key = normalizeName(item.name);
    if (key.isEmpty) return;
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final existing = await (_db.select(
      _db.groceryHabits,
    )..where((h) => h.id.equals(key))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.groceryHabits)
          .insert(
            GroceryHabitsCompanion.insert(
              id: key,
              nestId: Value(nestId),
              name: item.name.trim(),
              category: Value(item.category),
              buyCount: const Value(1),
              cadenceDays: const Value(7),
              lastBoughtAt: now,
              dirty: const Value(true),
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
      await (_db.update(
        _db.groceryHabits,
      )..where((h) => h.id.equals(key))).write(
        GroceryHabitsCompanion(
          nestId: nestId != null ? Value(nestId) : const Value.absent(),
          name: Value(item.name.trim()),
          category: Value(item.category),
          buyCount: Value(nextCount),
          cadenceDays: Value(cadence),
          lastBoughtAt: Value(now),
          dirty: const Value(true),
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
        : await (_db.select(
            _db.groceryHabits,
          )..where((h) => h.id.equals(key))).getSingleOrNull();
    final resolvedCategory = category == 'General' && habit != null
        ? habit.category
        : category;
    var resolvedQty = qty.trim().isEmpty ? '1' : qty.trim();
    if (resolvedQty == '1' && key.isNotEmpty) {
      final priors =
          await (_db.select(_db.shoppingItems)
                ..where((i) => i.deleted.equals(false) & i.done.equals(true))
                ..orderBy([(i) => OrderingTerm.desc(i.updatedAt)])
                ..limit(40))
              .get();
      for (final prior in priors) {
        if (normalizeName(prior.name) != key) continue;
        final priorQty = prior.qty.trim();
        if (priorQty.isNotEmpty) {
          resolvedQty = priorQty;
          break;
        }
      }
    }

    final maxOrder =
        await (_db.selectOnly(_db.shoppingItems)
              ..addColumns([_db.shoppingItems.sortOrder.max()])
              ..where(_db.shoppingItems.listId.equals(listId)))
            .getSingle();
    final nextOrder =
        (maxOrder.read(_db.shoppingItems.sortOrder.max()) ?? -1) + 1;

    await _db
        .into(_db.shoppingItems)
        .insert(
          ShoppingItemsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(resolvedNest),
            listId: listId,
            name: name.trim(),
            category: Value(resolvedCategory),
            qty: Value(resolvedQty),
            sortOrder: Value(nextOrder),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> addSuggestion(
    GroceryHabit habit, {
    String listId = defaultListId,
  }) {
    return addItem(name: habit.name, category: habit.category, listId: listId);
  }

  Future<void> updateItem({
    required String id,
    required String name,
    required String category,
    required String qty,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return Future.value();
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
      ShoppingItemsCompanion(
        name: Value(trimmed),
        category: Value(category.trim().isEmpty ? 'General' : category.trim()),
        qty: Value(qty.trim().isEmpty ? '1' : qty.trim()),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteItem(String id) {
    return (_db.update(_db.shoppingItems)..where((i) => i.id.equals(id))).write(
      ShoppingItemsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Soft-deletes checked-off items so the open list stays clean.
  Future<int> clearCompleted({String listId = defaultListId}) async {
    final done =
        await (_db.select(_db.shoppingItems)..where(
              (i) =>
                  i.listId.equals(listId) &
                  i.deleted.equals(false) &
                  i.done.equals(true),
            ))
            .get();
    if (done.isEmpty) return 0;
    final now = DateTime.now();
    for (final item in done) {
      await (_db.update(
        _db.shoppingItems,
      )..where((i) => i.id.equals(item.id))).write(
        ShoppingItemsCompanion(
          deleted: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    return done.length;
  }
}

class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  RecurringEventAnchor _anchor(CalendarEvent event) => RecurringEventAnchor(
        startsAt: event.startsAt,
        endsAt: event.endsAt,
        allDay: event.allDay,
        recurrence: EventRecurrence.parse(event.recurrence),
        recurrenceUntil: event.recurrenceUntil,
      );

  CalendarEvent _withOccurrence(CalendarEvent master, EventOccurrence occ) =>
      master.copyWith(
        startsAt: occ.startsAt,
        endsAt: Value(occ.endsAt),
      );

  List<CalendarEvent> expandInRange(
    List<CalendarEvent> events,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final expanded = <CalendarEvent>[];
    for (final event in events) {
      for (final occ in expandRecurringEvent(
        _anchor(event),
        rangeStart,
        rangeEnd,
      )) {
        expanded.add(_withOccurrence(event, occ));
      }
    }
    expanded.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return expanded;
  }

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
    EventRecurrence recurrence = EventRecurrence.none,
    DateTime? recurrenceUntil,
  }) async {
    final now = DateTime.now();
    final resolvedNest = nestId ?? await _db.getMeta('nestId');
    await _db
        .into(_db.calendarEvents)
        .insert(
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
            recurrence: Value(recurrence.storage),
            recurrenceUntil: Value(recurrenceUntil),
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
    EventRecurrence recurrence = EventRecurrence.none,
    DateTime? recurrenceUntil,
  }) {
    return (_db.update(
      _db.calendarEvents,
    )..where((e) => e.id.equals(id))).write(
      CalendarEventsCompanion(
        title: Value(title.trim()),
        memberId: Value(memberId),
        category: Value(category),
        location: Value(location),
        startsAt: Value(startsAt),
        endsAt: Value(endsAt),
        allDay: Value(allDay),
        recurrence: Value(recurrence.storage),
        recurrenceUntil: Value(recurrenceUntil),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteEvent(String id) {
    return (_db.update(
      _db.calendarEvents,
    )..where((e) => e.id.equals(id))).write(
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
    return (_db.select(
      _db.nestMembers,
    )..orderBy([(m) => OrderingTerm(expression: m.name)])).watch();
  }

  Future<List<NestMember>> getAll() {
    return _db.select(_db.nestMembers).get();
  }

  Future<NestMember?> byId(String id) {
    return (_db.select(
      _db.nestMembers,
    )..where((m) => m.id.equals(id))).getSingleOrNull();
  }

  Future<void> updateRole(String memberId, String role) {
    return (_db.update(
      _db.nestMembers,
    )..where((m) => m.id.equals(memberId))).write(
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

  /// Default when the nest has never set a budget.
  static const defaultMonthBudget = 1800.0;

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

  /// Category → spend for the current calendar month (non-zero only).
  Stream<List<({String category, double total})>> watchMonthCategoryTotals() {
    return watchAll().map((items) {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month + 1, 1);
      final map = <String, double>{};
      for (final e in items) {
        if (e.spentAt.isBefore(start) || !e.spentAt.isBefore(end)) continue;
        final key = e.category.trim().isEmpty ? 'General' : e.category.trim();
        map[key] = (map[key] ?? 0) + e.amount;
      }
      final list =
          map.entries.map((e) => (category: e.key, total: e.value)).toList()
            ..sort((a, b) => b.total.compareTo(a.total));
      return list;
    });
  }

  Stream<double> watchMonthBudget() {
    return _db.select(_db.nestSettings).watch().asyncMap((rows) async {
      final nestId = await _db.getMeta('nestId');
      if (nestId == null || nestId.isEmpty) return defaultMonthBudget;
      for (final row in rows) {
        if (row.id == nestId) return row.monthBudget;
      }
      return defaultMonthBudget;
    });
  }

  Future<double> getMonthBudget() async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return defaultMonthBudget;
    final row = await (_db.select(
      _db.nestSettings,
    )..where((s) => s.id.equals(nestId))).getSingleOrNull();
    return row?.monthBudget ?? defaultMonthBudget;
  }

  Future<void> setMonthBudget(double amount) async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return;
    final budget = amount <= 0 ? defaultMonthBudget : amount;
    final now = DateTime.now();
    await _db
        .into(_db.nestSettings)
        .insertOnConflictUpdate(
          NestSettingsCompanion.insert(
            id: nestId,
            monthBudget: Value(budget),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
  }

  Stream<bool> watchTomorrowPreviewEnabled() {
    return _db.select(_db.nestSettings).watch().asyncMap((rows) async {
      final nestId = await _db.getMeta('nestId');
      if (nestId == null || nestId.isEmpty) return false;
      for (final row in rows) {
        if (row.id == nestId) return row.tomorrowPreviewEnabled;
      }
      return false;
    });
  }

  Future<bool> getTomorrowPreviewEnabled() async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return false;
    final row = await (_db.select(
      _db.nestSettings,
    )..where((s) => s.id.equals(nestId))).getSingleOrNull();
    return row?.tomorrowPreviewEnabled ?? false;
  }

  Future<void> setTomorrowPreviewEnabled(bool enabled) async {
    final nestId = await _db.getMeta('nestId');
    if (nestId == null || nestId.isEmpty) return;
    final currentBudget = await getMonthBudget();
    final now = DateTime.now();
    await _db
        .into(_db.nestSettings)
        .insertOnConflictUpdate(
          NestSettingsCompanion.insert(
            id: nestId,
            monthBudget: Value(currentBudget),
            tomorrowPreviewEnabled: Value(enabled),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    String category = 'General',
    String paidBy = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    await _db
        .into(_db.expenses)
        .insert(
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

  Future<void> updateExpense({
    required String id,
    required String title,
    required double amount,
    required String category,
    String paidBy = '',
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    return (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        title: Value(trimmed),
        amount: Value(amount),
        category: Value(category.trim().isEmpty ? 'General' : category.trim()),
        paidBy: Value(paidBy.trim()),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteExpense(String id) {
    return (_db.update(_db.expenses)..where((e) => e.id.equals(id))).write(
      ExpensesCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}

class BillRepository {
  BillRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Bill>> watchAll() {
    return (_db.select(
      _db.bills,
    )..where((b) => b.deleted.equals(false))).watch().map(_sortBills);
  }

  /// Unpaid overdue first, then due soon, then paid.
  static List<Bill> _sortBills(List<Bill> bills) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    int rank(Bill b) {
      if (b.paid) return 2;
      final due = DateTime(b.dueAt.year, b.dueAt.month, b.dueAt.day);
      if (due.isBefore(start)) return 0;
      return 1;
    }

    final copy = List<Bill>.from(bills);
    copy.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return a.dueAt.compareTo(b.dueAt);
    });
    return copy;
  }

  Future<List<Bill>> getUnpaidUpcoming() {
    return (_db.select(
      _db.bills,
    )..where((b) => b.deleted.equals(false) & b.paid.equals(false))).get();
  }

  Future<void> togglePaid(Bill bill) {
    final now = DateTime.now();
    if (!bill.paid) {
      if (bill.cadenceDays >= 1) {
        return (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
          BillsCompanion(
            dueAt: Value(advanceDueAt(bill.dueAt, bill.cadenceDays)),
            paid: const Value(false),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
      return (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
        BillsCompanion(
          paid: const Value(true),
          dirty: const Value(true),
          updatedAt: Value(now),
        ),
      );
    }
    return (_db.update(_db.bills)..where((b) => b.id.equals(bill.id))).write(
      BillsCompanion(
        paid: const Value(false),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> addBill({
    required String title,
    required double amount,
    required DateTime dueAt,
    int cadenceDays = 0,
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    await _db
        .into(_db.bills)
        .insert(
          BillsCompanion.insert(
            id: _uuid.v4(),
            nestId: Value(nestId),
            title: title.trim(),
            amount: amount,
            dueAt: dueAt,
            cadenceDays: Value(cadenceDays.clamp(0, 365)),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
  }

  Future<void> updateBill({
    required String id,
    required String title,
    required double amount,
    required DateTime dueAt,
    int cadenceDays = 0,
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    return (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        title: Value(trimmed),
        amount: Value(amount),
        dueAt: Value(dueAt),
        cadenceDays: Value(cadenceDays.clamp(0, 365)),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteBill(String id) {
    return (_db.update(_db.bills)..where((b) => b.id.equals(id))).write(
      BillsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
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
    await _db
        .into(_db.emergencyEntries)
        .insertOnConflictUpdate(
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
    await _db
        .into(_db.timelineEvents)
        .insert(
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
      uploadStatus: const Value('local'),
      dirty: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.into(_db.vaultDocuments).insert(companion);
    return (await (_db.select(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).getSingle());
  }

  Future<void> setUploadStatus(String id, String status) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        uploadStatus: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markUploaded({required String id, required String storagePath}) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        storagePath: Value(storagePath),
        uploadStatus: const Value('synced'),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markUploadFailed(String id) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        uploadStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<VaultDocument?> getById(String id) {
    return (_db.select(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
  }

  /// Docs with a local file that still need Storage upload.
  Future<List<VaultDocument>> listPendingUploads() {
    return (_db.select(_db.vaultDocuments)
          ..where(
            (d) =>
                d.deleted.equals(false) &
                d.localPath.isNotNull() &
                (d.uploadStatus.equals(VaultUploadStatus.local.storage) |
                    d.uploadStatus.equals(VaultUploadStatus.failed.storage) |
                    d.uploadStatus.equals(
                      VaultUploadStatus.uploading.storage,
                    )),
          )
          ..orderBy([(d) => OrderingTerm(expression: d.createdAt)]))
        .get();
  }

  Stream<List<VaultDocument>> watchFailedUploads() {
    return (_db.select(_db.vaultDocuments)
          ..where(
            (d) =>
                d.deleted.equals(false) &
                d.uploadStatus.equals(VaultUploadStatus.failed.storage),
          )
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch();
  }

  Stream<int> watchFailedUploadCount() {
    final count = _db.vaultDocuments.id.count();
    final query = _db.selectOnly(_db.vaultDocuments)
      ..addColumns([count])
      ..where(
        _db.vaultDocuments.deleted.equals(false) &
            _db.vaultDocuments.uploadStatus.equals(
              VaultUploadStatus.failed.storage,
            ),
      );
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  Future<void> setLocalPath({required String id, required String localPath}) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        localPath: Value(localPath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateMeta({
    required String id,
    String? title,
    String? category,
    String? notes,
    DateTime? expiresAt,
    bool clearExpiry = false,
  }) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        title: title == null ? const Value.absent() : Value(title.trim()),
        category: category == null
            ? const Value.absent()
            : Value(category.trim()),
        notes: notes == null ? const Value.absent() : Value(notes),
        expiresAt: clearExpiry
            ? const Value(null)
            : (expiresAt == null ? const Value.absent() : Value(expiresAt)),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> delete(String id) {
    return (_db.update(
      _db.vaultDocuments,
    )..where((d) => d.id.equals(id))).write(
      VaultDocumentsCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Docs expiring within [withinDays] (includes already expired).
  Stream<List<VaultDocument>> watchExpiringSoon({int withinDays = 45}) {
    final cutoff = DateTime.now()
        .add(Duration(days: withinDays))
        .add(const Duration(days: 1));
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
          ..where((m) => m.deleted.equals(false) & m.weekday.equals(weekday))
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
    await _db
        .into(_db.mealPlans)
        .insertOnConflictUpdate(
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
    final existingDinners =
        await (_db.select(_db.mealPlans)..where(
              (m) => m.deleted.equals(false) & m.mealType.equals('Dinner'),
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
        await (_db.update(
          _db.mealPlans,
        )..where((m) => m.id.equals(primary.id))).write(
          MealPlansCompanion(
            title: Value(title),
            dirty: const Value(true),
            updatedAt: Value(now),
          ),
        );
      } else {
        await _db
            .into(_db.mealPlans)
            .insert(
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

    await TimelineRepository(
      _db,
    ).add(message: 'Planned dinner week', memberName: 'You');
  }

  /// Parses ingredients (comma or newline) and adds missing ones to groceries.
  Future<int> addIngredientsToShopping(MealPlan meal) async {
    return addMealsIngredientsToShopping([meal], label: meal.title);
  }

  /// Ingredients that would be added (not already on the open list).
  Future<List<String>> previewIngredientsToShopping(
    Iterable<MealPlan> meals,
  ) async {
    final raw = meals
        .expand((meal) => _parseIngredients(meal.ingredients))
        .toList();
    if (raw.isEmpty) return const [];

    final shopping = ShoppingRepository(_db);
    final existing = await shopping.watchItems().first;
    final openNames = existing
        .where((i) => !i.done)
        .map((i) => ShoppingRepository.normalizeName(i.name))
        .toSet();

    final toAdd = <String>[];
    final seen = <String>{};
    for (final name in raw) {
      final key = ShoppingRepository.normalizeName(name);
      if (key.isEmpty || openNames.contains(key) || !seen.add(key)) continue;
      toAdd.add(name.trim());
    }
    return toAdd;
  }

  Future<int> addMealsIngredientsToShopping(
    Iterable<MealPlan> meals, {
    String? label,
  }) async {
    final toAdd = await previewIngredientsToShopping(meals);
    if (toAdd.isEmpty) return 0;

    final shopping = ShoppingRepository(_db);
    for (final name in toAdd) {
      await shopping.addItem(name: name, category: 'Meals');
    }
    final target = label ?? 'meal plan';
    await TimelineRepository(_db).add(
      message:
          'Added ${toAdd.length} ingredient${toAdd.length == 1 ? '' : 's'} for $target',
      memberName: 'You',
    );
    return toAdd.length;
  }

  List<String> _parseIngredients(String ingredients) {
    return ingredients
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Stream<List<Recipe>> watchRecipes() {
    return (_db.select(_db.recipes)
          ..where((r) => r.deleted.equals(false))
          ..orderBy([(r) => OrderingTerm(expression: r.title)]))
        .watch();
  }

  Future<Recipe> addRecipe({
    required String title,
    String ingredients = '',
    String notes = '',
  }) async {
    final now = DateTime.now();
    final nestId = await _db.getMeta('nestId');
    final id = _uuid.v4();
    await _db
        .into(_db.recipes)
        .insert(
          RecipesCompanion.insert(
            id: id,
            nestId: Value(nestId),
            title: title.trim(),
            ingredients: Value(ingredients.trim()),
            notes: Value(notes.trim()),
            dirty: const Value(true),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    return (_db.select(_db.recipes)..where((r) => r.id.equals(id)))
        .getSingle();
  }

  Future<void> updateRecipe({
    required String id,
    required String title,
    String ingredients = '',
    String notes = '',
  }) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value();
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        title: Value(trimmed),
        ingredients: Value(ingredients.trim()),
        notes: Value(notes.trim()),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteRecipe(String id) {
    return (_db.update(_db.recipes)..where((r) => r.id.equals(id))).write(
      RecipesCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> applyRecipeToMealPlan({
    required String recipeId,
    required int weekday,
    String mealType = 'Dinner',
  }) async {
    final recipe = await (_db.select(_db.recipes)
          ..where((r) => r.id.equals(recipeId) & r.deleted.equals(false)))
        .getSingleOrNull();
    if (recipe == null) return;

    final existing = await (_db.select(_db.mealPlans)
          ..where(
            (m) =>
                m.deleted.equals(false) &
                m.weekday.equals(weekday) &
                m.mealType.equals(mealType),
          ))
        .get();

    final primary = existing.isEmpty ? null : existing.first;
    for (final extra in existing.skip(1)) {
      await delete(extra.id);
    }

    await upsert(
      id: primary?.id,
      weekday: weekday,
      title: recipe.title,
      mealType: mealType,
      ingredients: recipe.ingredients,
    );
  }

  Future<Recipe> saveMealAsRecipe(MealPlan meal, {String notes = ''}) {
    return addRecipe(
      title: meal.title,
      ingredients: meal.ingredients,
      notes: notes,
    );
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
    final due = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: cadenceDays));
    await _db
        .into(_db.careItems)
        .insert(
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
    final next = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: item.cadenceDays));
    await (_db.update(_db.careItems)..where((c) => c.id.equals(item.id))).write(
      CareItemsCompanion(
        lastDoneAt: Value(now),
        nextDueAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await TimelineRepository(
      _db,
    ).add(message: 'Completed care: ${item.title}', memberName: 'You');
  }

  Future<void> update({
    required String id,
    required String title,
    String category = 'Home',
    int cadenceDays = 7,
    String notes = '',
    String memberId = '',
    DateTime? nextDueAt,
  }) {
    return (_db.update(_db.careItems)..where((c) => c.id.equals(id))).write(
      CareItemsCompanion(
        title: Value(title.trim()),
        category: Value(category),
        cadenceDays: Value(cadenceDays),
        notes: Value(notes.trim()),
        memberId: Value(memberId),
        nextDueAt: nextDueAt == null ? const Value.absent() : Value(nextDueAt),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Push due date out without marking done.
  Future<void> snooze(CareItem item, {int days = 1}) async {
    final base = item.nextDueAt;
    final next = DateTime(base.year, base.month, base.day).add(
      Duration(days: days.clamp(1, 30)),
    );
    await (_db.update(_db.careItems)..where((c) => c.id.equals(item.id))).write(
      CareItemsCompanion(
        nextDueAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Snoozed care: ${item.title}',
      memberName: 'You',
    );
  }

  /// Advance one cadence cycle without recording lastDoneAt.
  Future<void> skipCycle(CareItem item) async {
    final base = item.nextDueAt;
    final next = DateTime(base.year, base.month, base.day).add(
      Duration(days: item.cadenceDays.clamp(1, 365)),
    );
    await (_db.update(_db.careItems)..where((c) => c.id.equals(item.id))).write(
      CareItemsCompanion(
        nextDueAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Skipped care: ${item.title}',
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
    final existing = await (_db.select(
      _db.careProfiles,
    )..where((p) => p.id.equals(memberId))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.careProfiles)
          .insert(
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
      await (_db.update(
        _db.careProfiles,
      )..where((p) => p.id.equals(memberId))).write(
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
    final next =
        nextAt ??
        DateTime(now.year, now.month, now.day).add(Duration(days: cadenceDays));
    await _db
        .into(_db.schoolActivities)
        .insert(
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
    final next = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: item.cadenceDays));
    await (_db.update(
      _db.schoolActivities,
    )..where((s) => s.id.equals(item.id))).write(
      SchoolActivitiesCompanion(
        lastDoneAt: Value(now),
        nextAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(now),
      ),
    );
    await TimelineRepository(
      _db,
    ).add(message: 'Done: ${item.title}', memberName: 'You');
  }

  Future<void> update({
    required String id,
    required String title,
    String kind = 'School',
    int cadenceDays = 7,
    String location = '',
    String memberId = '',
    String notes = '',
    DateTime? nextAt,
  }) {
    return (_db.update(
      _db.schoolActivities,
    )..where((s) => s.id.equals(id))).write(
      SchoolActivitiesCompanion(
        title: Value(title.trim()),
        kind: Value(kind),
        cadenceDays: Value(cadenceDays),
        location: Value(location.trim()),
        memberId: Value(memberId),
        notes: Value(notes.trim()),
        nextAt: nextAt == null ? const Value.absent() : Value(nextAt),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> snooze(SchoolActivity item, {int days = 1}) async {
    final base = item.nextAt;
    final next = DateTime(base.year, base.month, base.day).add(
      Duration(days: days.clamp(1, 30)),
    );
    await (_db.update(
      _db.schoolActivities,
    )..where((s) => s.id.equals(item.id))).write(
      SchoolActivitiesCompanion(
        nextAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Snoozed school: ${item.title}',
      memberName: 'You',
    );
  }

  Future<void> skipCycle(SchoolActivity item) async {
    final base = item.nextAt;
    final next = DateTime(base.year, base.month, base.day).add(
      Duration(days: item.cadenceDays.clamp(1, 365)),
    );
    await (_db.update(
      _db.schoolActivities,
    )..where((s) => s.id.equals(item.id))).write(
      SchoolActivitiesCompanion(
        nextAt: Value(next),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await TimelineRepository(_db).add(
      message: 'Skipped school: ${item.title}',
      memberName: 'You',
    );
  }

  /// Creates a same-day task for a pickup / activity.
  /// Returns the assignee display name used (if any).
  Future<String?> createPickupTask(SchoolActivity item) async {
    final loc = item.location.trim();
    final title = loc.isEmpty
        ? 'Pickup: ${item.title}'
        : 'Pickup: ${item.title} @ $loc';
    final members = await _db.select(_db.nestMembers).get();
    NestMember? assignee;
    for (final m in members) {
      if (MemberRoles.isAdultLike(m.role)) {
        assignee = m;
        break;
      }
    }
    assignee ??= members.isEmpty ? null : members.first;
    await TaskRepository(_db).addTask(
      title: title,
      dueLabel: TaskDueLabel.today.label,
      assigneeId: assignee?.id ?? '',
    );
    await TimelineRepository(_db).add(
      message: 'Added pickup task for ${item.title}',
      memberName: 'You',
    );
    return assignee?.name;
  }

  /// Adds a calendar event on the activity's next date.
  Future<void> createCalendarEvent(SchoolActivity item) async {
    final day = item.nextAt;
    final startsAt = DateTime(day.year, day.month, day.day, 9);
    final loc = item.location.trim();
    await EventRepository(_db).addEvent(
      title: item.title,
      startsAt: startsAt,
      memberId: item.memberId,
      category: 'School',
      location: loc.isEmpty ? null : loc,
      allDay: false,
      endsAt: startsAt.add(const Duration(hours: 1)),
    );
    await TimelineRepository(_db).add(
      message: 'Added calendar event for ${item.title}',
      memberName: 'You',
    );
  }

  Future<void> delete(String id) {
    return (_db.update(
      _db.schoolActivities,
    )..where((s) => s.id.equals(id))).write(
      SchoolActivitiesCompanion(
        deleted: const Value(true),
        dirty: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
