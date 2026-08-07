import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../enums.dart';
import '../task_due.dart';

part 'app_database.g.dart';

class NestMembers extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text()();
  TextColumn get name => text()();
  TextColumn get role => text().withDefault(const Constant('member'))();
  TextColumn get initials => text()();
  IntColumn get colorValue => integer()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get assigneeId => text().withDefault(const Constant('dad'))();
  TextColumn get dueLabel => text().withDefault(const Constant('Today'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get cadenceDays => integer().withDefault(const Constant(0))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  BoolColumn get recurring => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get name => text()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ShoppingItems extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get listId => text().references(ShoppingLists, #id)();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  TextColumn get qty => text().withDefault(const Constant('1'))();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CalendarEvents extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get memberId => text().withDefault(const Constant('dad'))();
  TextColumn get category => text().withDefault(const Constant('Family'))();
  TextColumn get location => text().nullable()();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime().nullable()();
  BoolColumn get allDay => boolean().withDefault(const Constant(false))();
  TextColumn get recurrence => text().withDefault(const Constant('none'))();
  DateTimeColumn get recurrenceUntil => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class SyncMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  RealColumn get amount => real()();
  TextColumn get paidBy => text().withDefault(const Constant(''))();
  DateTimeColumn get spentAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  RealColumn get amount => real()();
  DateTimeColumn get dueAt => dateTime()();
  BoolColumn get paid => boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class EmergencyEntries extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get label => text()();
  TextColumn get value => text()();
  TextColumn get iconName => text().withDefault(const Constant('info'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class VaultDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get category => text().withDefault(const Constant('Family'))();
  TextColumn get fileName => text()();
  TextColumn get storagePath => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();

  /// Optional note (e.g. passport numbers last-4, renewal tips).
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Optional expiry for IDs / insurance / licenses.
  DateTimeColumn get expiresAt => dateTime().nullable()();

  /// Storage upload: local | uploading | synced | failed ([VaultUploadStatus]).
  TextColumn get uploadStatus => text().withDefault(const Constant('local'))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class TimelineEvents extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get message => text()();
  TextColumn get memberId => text().withDefault(const Constant(''))();
  TextColumn get memberName => text().withDefault(const Constant('Family'))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Weekly meal plan slot. weekday: 1=Mon … 7=Sun (DateTime.weekday).
class MealPlans extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  IntColumn get weekday => integer()();
  TextColumn get mealType => text().withDefault(const Constant('Dinner'))();
  TextColumn get title => text()();
  TextColumn get ingredients => text().withDefault(const Constant(''))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Recurring household care (pet, home, car, elder).
class CareItems extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get category => text().withDefault(const Constant('Home'))();
  IntColumn get cadenceDays => integer().withDefault(const Constant(7))();
  DateTimeColumn get lastDoneAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Optional link to a nest member (elder care routines).
  TextColumn get memberId => text().withDefault(const Constant(''))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Shared elder / care-recipient profile (medications, doctor, mobility).
class CareProfiles extends Table {
  /// Same as memberId — one profile per nest member.
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get memberId => text()();
  TextColumn get medications => text().withDefault(const Constant(''))();
  TextColumn get allergies => text().withDefault(const Constant(''))();
  TextColumn get mobilityNotes => text().withDefault(const Constant(''))();
  TextColumn get primaryDoctor => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// School / sports / pickup cadence for kids.
class SchoolActivities extends Table {
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get title => text()();

  /// School | Sports | Pickup | Club
  TextColumn get kind => text().withDefault(const Constant('School'))();
  IntColumn get cadenceDays => integer().withDefault(const Constant(7))();
  DateTimeColumn get lastDoneAt => dateTime().nullable()();
  DateTimeColumn get nextAt => dateTime()();
  TextColumn get location => text().withDefault(const Constant(''))();
  TextColumn get memberId => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Recurring grocery memory synced per nest (LWW on updatedAt).
class GroceryHabits extends Table {
  /// Normalized lowercase name key.
  TextColumn get id => text()();
  TextColumn get nestId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant('General'))();
  IntColumn get buyCount => integer().withDefault(const Constant(0))();

  /// Learned restock interval in days (updated from purchase gaps).
  IntColumn get cadenceDays => integer().withDefault(const Constant(7))();
  DateTimeColumn get lastBoughtAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Per-nest settings (month budget, etc.). Cleared with household data on nest bind.
class NestSettings extends Table {
  /// Same as nest id — one row per nest.
  TextColumn get id => text()();
  RealColumn get monthBudget => real().withDefault(const Constant(1800.0))();
  BoolColumn get tomorrowPreviewEnabled =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    NestMembers,
    Tasks,
    ShoppingLists,
    ShoppingItems,
    CalendarEvents,
    SyncMeta,
    Expenses,
    Bills,
    EmergencyEntries,
    VaultDocuments,
    TimelineEvents,
    MealPlans,
    CareItems,
    CareProfiles,
    SchoolActivities,
    GroceryHabits,
    NestSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 16;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await _createTableIfMissing(m, nestMembers);
        await _createTableIfMissing(m, calendarEvents);
        await _createTableIfMissing(m, syncMeta);
        // Constant defaults are fine for ALTER TABLE; currentDateAndTime is not.
        await _addColumnIfMissing(m, tasks, tasks.nestId);
        await _addColumnIfMissing(m, tasks, tasks.dirty);
        await _addColumnIfMissing(m, tasks, tasks.deleted);
        await _addColumnIfMissing(m, shoppingLists, shoppingLists.nestId);
        await _addColumnIfMissing(m, shoppingLists, shoppingLists.dirty);
        await _addColumnIfMissing(m, shoppingLists, shoppingLists.deleted);
        await _addUpdatedAtIfMissing('shopping_lists');
        await _addColumnIfMissing(m, shoppingItems, shoppingItems.nestId);
        await _addColumnIfMissing(m, shoppingItems, shoppingItems.dirty);
        await _addColumnIfMissing(m, shoppingItems, shoppingItems.deleted);
      }
      if (from < 3) {
        await _createTableIfMissing(m, expenses);
        await _createTableIfMissing(m, bills);
        await _createTableIfMissing(m, emergencyEntries);
      }
      if (from < 4) {
        await _createTableIfMissing(m, vaultDocuments);
        await _createTableIfMissing(m, timelineEvents);
      }
      if (from < 5) {
        await _createTableIfMissing(m, mealPlans);
        await _createTableIfMissing(m, careItems);
      }
      if (from < 6) {
        await _createTableIfMissing(m, schoolActivities);
      }
      if (from < 7) {
        await _createTableIfMissing(m, groceryHabits);
      }
      if (from < 8) {
        await _addColumnIfMissing(m, groceryHabits, groceryHabits.cadenceDays);
      }
      if (from < 9) {
        await _createTableIfMissing(m, careProfiles);
        await _addColumnIfMissing(m, careItems, careItems.memberId);
      }
      if (from < 10) {
        await _addColumnIfMissing(m, vaultDocuments, vaultDocuments.notes);
        await _addColumnIfMissing(m, vaultDocuments, vaultDocuments.expiresAt);
      }
      if (from < 11) {
        await _addColumnIfMissing(
          m,
          vaultDocuments,
          vaultDocuments.uploadStatus,
        );
        await customStatement(
          "UPDATE vault_documents SET upload_status = 'synced' "
          "WHERE storage_path IS NOT NULL AND storage_path != ''",
        );
        await customStatement(
          "UPDATE vault_documents SET upload_status = 'failed' "
          "WHERE (storage_path IS NULL OR storage_path = '') "
          "AND local_path IS NOT NULL AND local_path != '' "
          "AND nest_id IS NOT NULL AND nest_id != ''",
        );
      }
      if (from < 12) {
        await _createTableIfMissing(m, nestSettings);
      }
      if (from < 13) {
        await _addColumnIfMissing(
          m,
          nestSettings,
          nestSettings.tomorrowPreviewEnabled,
        );
      }
      if (from < 14) {
        await _addColumnIfMissing(m, tasks, tasks.dueAt);
        await _addColumnIfMissing(m, tasks, tasks.cadenceDays);
        await _backfillTaskDueAtAndCadence();
      }
      if (from < 15) {
        await _addColumnIfMissing(m, calendarEvents, calendarEvents.recurrence);
        await _addColumnIfMissing(
          m,
          calendarEvents,
          calendarEvents.recurrenceUntil,
        );
      }
      if (from < 16) {
        await _addColumnIfMissing(m, groceryHabits, groceryHabits.nestId);
        await _addColumnIfMissing(m, groceryHabits, groceryHabits.dirty);
        await _addColumnIfMissing(m, groceryHabits, groceryHabits.deleted);
        final nestId = await getMeta('nestId');
        if (nestId != null && nestId.isNotEmpty) {
          await customStatement(
            'UPDATE grocery_habits SET nest_id = ? WHERE nest_id IS NULL',
            [Variable.withString(nestId)],
          );
        }
      }
    },
  );

  Future<void> _backfillTaskDueAtAndCadence() async {
    final now = DateTime.now();
    final rows = await select(tasks).get();
    for (final task in rows) {
      final resolvedDue = task.dueAt ??
          TaskDueLabel.dueDateFor(task.dueLabel, now: now) ??
          DateTime(now.year, now.month, now.day);
      final cadence = task.recurring && task.cadenceDays == 0
          ? 7
          : task.cadenceDays;
      final label = dueLabelForDueAt(resolvedDue, now: now);
      await (update(tasks)..where((t) => t.id.equals(task.id))).write(
        TasksCompanion(
          dueAt: task.dueAt == null ? Value(resolvedDue) : const Value.absent(),
          cadenceDays: cadence != task.cadenceDays
              ? Value(cadence)
              : const Value.absent(),
          dueLabel: label != task.dueLabel ? Value(label) : const Value.absent(),
        ),
      );
    }
  }

  Future<bool> _tableExists(String tableName) async {
    final row = await customSelect(
      "SELECT 1 AS ok FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(tableName)],
      readsFrom: {},
    ).getSingleOrNull();
    return row != null;
  }

  Future<bool> _columnExists(String tableName, String columnName) async {
    final rows = await customSelect(
      'PRAGMA table_info($tableName)',
      readsFrom: {},
    ).get();
    return rows.any((r) => r.read<String>('name') == columnName);
  }

  Future<void> _createTableIfMissing(Migrator m, TableInfo table) async {
    if (!await _tableExists(table.actualTableName)) {
      await m.createTable(table);
    }
  }

  Future<void> _addColumnIfMissing(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    if (!await _columnExists(table.actualTableName, column.name)) {
      await m.addColumn(table, column);
    }
  }

  /// SQLite forbids ALTER TABLE … ADD COLUMN with non-constant defaults
  /// (e.g. CURRENT_TIMESTAMP). Use a constant, then backfill.
  Future<void> _addUpdatedAtIfMissing(String tableName) async {
    if (await _columnExists(tableName, 'updated_at')) return;
    final nowSecs = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await customStatement(
      'ALTER TABLE "$tableName" ADD COLUMN "updated_at" INTEGER NOT NULL DEFAULT $nowSecs',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nestly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<String?> getMeta(String key) async {
    final row = await (select(
      syncMeta,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) {
    return into(
      syncMeta,
    ).insertOnConflictUpdate(SyncMetaCompanion.insert(key: key, value: value));
  }

  /// Wipes local household rows so demo/seed data never leaks into a real nest.
  Future<void> clearHouseholdData() async {
    await batch((b) {
      b.deleteAll(shoppingItems);
      b.deleteAll(shoppingLists);
      b.deleteAll(tasks);
      b.deleteAll(calendarEvents);
      b.deleteAll(expenses);
      b.deleteAll(bills);
      b.deleteAll(emergencyEntries);
      b.deleteAll(vaultDocuments);
      b.deleteAll(timelineEvents);
      b.deleteAll(mealPlans);
      b.deleteAll(careItems);
      b.deleteAll(careProfiles);
      b.deleteAll(schoolActivities);
      b.deleteAll(groceryHabits);
      b.deleteAll(nestMembers);
      b.deleteAll(nestSettings);
    });
  }

  /// Demo seed for widget/unit tests only — never call from production main().
  Future<void> ensureSeeded() async {
    final taskCount = await (select(tasks)..limit(1)).get();
    final listCount = await (select(shoppingLists)..limit(1)).get();
    final memberCount = await (select(nestMembers)..limit(1)).get();
    final eventCount = await (select(calendarEvents)..limit(1)).get();
    final expenseCount = await (select(expenses)..limit(1)).get();
    final emergencyCount = await (select(emergencyEntries)..limit(1)).get();
    final vaultCount = await (select(vaultDocuments)..limit(1)).get();
    final timelineCount = await (select(timelineEvents)..limit(1)).get();

    if (taskCount.isNotEmpty || listCount.isNotEmpty) {
      if (memberCount.isEmpty) await _seedMembers();
      if (eventCount.isEmpty) await _seedEvents();
      if (expenseCount.isEmpty) await _seedMoney();
      if (emergencyCount.isEmpty) await _seedEmergency();
      if (vaultCount.isEmpty) await _seedVaultMeta();
      if (timelineCount.isEmpty) await _seedTimeline();
      return;
    }

    final now = DateTime.now();
    await _seedMembers();
    await _seedEvents();
    await _seedMoney();
    await _seedEmergency();
    await _seedVaultMeta();
    await _seedTimeline();

    await batch((b) {
      final today = DateTime(now.year, now.month, now.day);
      b.insertAll(tasks, [
        TasksCompanion.insert(
          id: 'task-1',
          title: 'Buy groceries',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Today'),
          dueAt: Value(today),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-2',
          title: 'Pack soccer kit',
          assigneeId: const Value('ayaan'),
          dueLabel: const Value('Today'),
          dueAt: Value(today),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-3',
          title: 'Water plants',
          assigneeId: const Value('noor'),
          dueLabel: const Value('Today'),
          dueAt: Value(today),
          done: const Value(true),
          recurring: const Value(true),
          cadenceDays: const Value(7),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-4',
          title: 'Clean kitchen',
          assigneeId: const Value('mom'),
          dueLabel: const Value('Tomorrow'),
          dueAt: Value(today.add(const Duration(days: 1))),
          recurring: const Value(true),
          cadenceDays: const Value(7),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-5',
          title: 'Pay internet bill',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Fri'),
          dueAt: Value(today.add(const Duration(days: 5))),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);

      b.insert(
        shoppingLists,
        ShoppingListsCompanion.insert(
          id: 'list-groceries',
          name: 'Family Groceries',
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
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
          dirty: const Value(false),
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
          dirty: const Value(false),
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
          dirty: const Value(false),
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
          dirty: const Value(false),
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
          dirty: const Value(false),
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
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
    });
  }

  Future<void> _seedMembers() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(nestMembers, [
        NestMembersCompanion.insert(
          id: 'dad',
          nestId: 'local',
          name: 'Kamran',
          role: const Value('Dad'),
          initials: 'K',
          colorValue: 0xFFB2B2E6,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'mom',
          nestId: 'local',
          name: 'Sara',
          role: const Value('Mom'),
          initials: 'S',
          colorValue: 0xFFF5C6D8,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'ayaan',
          nestId: 'local',
          name: 'Ayaan',
          role: const Value('Son'),
          initials: 'A',
          colorValue: 0xFFD4E7B3,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'noor',
          nestId: 'local',
          name: 'Noor',
          role: const Value('Daughter'),
          initials: 'N',
          colorValue: 0xFFFFD8A8,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
      ]);
    });
  }

  Future<void> _seedEvents() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await batch((b) {
      b.insertAll(calendarEvents, [
        CalendarEventsCompanion.insert(
          id: 'event-1',
          title: 'School drop-off',
          memberId: const Value('dad'),
          category: const Value('School'),
          location: const Value('Greenfield Academy'),
          startsAt: today.add(const Duration(hours: 7, minutes: 45)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CalendarEventsCompanion.insert(
          id: 'event-2',
          title: 'Dentist — Noor',
          memberId: const Value('mom'),
          category: const Value('Health'),
          location: const Value('SmileCare Clinic'),
          startsAt: today.add(const Duration(hours: 11, minutes: 30)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CalendarEventsCompanion.insert(
          id: 'event-3',
          title: 'Soccer practice',
          memberId: const Value('ayaan'),
          category: const Value('Sports'),
          location: const Value('City Field B'),
          startsAt: today.add(const Duration(hours: 16, minutes: 30)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CalendarEventsCompanion.insert(
          id: 'event-4',
          title: 'Family dinner',
          memberId: const Value('mom'),
          category: const Value('Family'),
          startsAt: today.add(const Duration(hours: 19)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        CalendarEventsCompanion.insert(
          id: 'event-5',
          title: "Ayaan's birthday",
          memberId: const Value('ayaan'),
          category: const Value('Birthday'),
          startsAt: today.add(const Duration(days: 4)),
          allDay: const Value(true),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
    });
  }

  Future<void> _seedMoney() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await batch((b) {
      b.insertAll(expenses, [
        ExpensesCompanion.insert(
          id: 'exp-1',
          title: 'Weekly groceries',
          category: const Value('Groceries'),
          amount: 86.40,
          paidBy: const Value('Kamran'),
          spentAt: Value(today),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ExpensesCompanion.insert(
          id: 'exp-2',
          title: 'Fuel',
          category: const Value('Transport'),
          amount: 42,
          paidBy: const Value('Sara'),
          spentAt: Value(today.subtract(const Duration(days: 1))),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        ExpensesCompanion.insert(
          id: 'exp-3',
          title: 'School supplies',
          category: const Value('Kids'),
          amount: 28.50,
          paidBy: const Value('Sara'),
          spentAt: Value(today.subtract(const Duration(days: 3))),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
      b.insertAll(bills, [
        BillsCompanion.insert(
          id: 'bill-1',
          title: 'Electricity',
          amount: 64.20,
          dueAt: today.add(const Duration(days: 3)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        BillsCompanion.insert(
          id: 'bill-2',
          title: 'Internet',
          amount: 49.99,
          dueAt: today.add(const Duration(days: 5)),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        BillsCompanion.insert(
          id: 'bill-3',
          title: 'Water',
          amount: 22.50,
          dueAt: today.subtract(const Duration(days: 2)),
          paid: const Value(true),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      ]);
    });
  }

  Future<void> _seedEmergency() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(emergencyEntries, [
        EmergencyEntriesCompanion.insert(
          id: 'em-1',
          label: 'Emergency contact',
          value: 'Omar Ibrahim · +1 555 0142',
          iconName: const Value('phone'),
          sortOrder: const Value(0),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        EmergencyEntriesCompanion.insert(
          id: 'em-2',
          label: 'Family doctor',
          value: 'Dr. Patel · City Care',
          iconName: const Value('doctor'),
          sortOrder: const Value(1),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        EmergencyEntriesCompanion.insert(
          id: 'em-3',
          label: 'Nearest hospital',
          value: 'Riverside General · 8 min',
          iconName: const Value('hospital'),
          sortOrder: const Value(2),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        EmergencyEntriesCompanion.insert(
          id: 'em-4',
          label: 'Allergies',
          value: 'Ayaan — peanuts · Noor — none',
          iconName: const Value('warning'),
          sortOrder: const Value(3),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        EmergencyEntriesCompanion.insert(
          id: 'em-5',
          label: 'Blood groups',
          value: 'K O+ · S A+ · A B+ · N O+',
          iconName: const Value('blood'),
          sortOrder: const Value(4),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        EmergencyEntriesCompanion.insert(
          id: 'em-6',
          label: 'Insurance',
          value: 'HealthPlus Family · #HP-88241',
          iconName: const Value('shield'),
          sortOrder: const Value(5),
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
      ]);
    });
  }

  Future<void> _seedVaultMeta() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(vaultDocuments, [
        VaultDocumentsCompanion.insert(
          id: 'vault-1',
          title: 'Passports',
          category: const Value('IDs'),
          fileName: 'passports.pdf',
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(days: 14))),
          updatedAt: Value(now.subtract(const Duration(days: 14))),
        ),
        VaultDocumentsCompanion.insert(
          id: 'vault-2',
          title: 'Car insurance',
          category: const Value('Car'),
          fileName: 'car-insurance.pdf',
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(days: 1))),
          updatedAt: Value(now.subtract(const Duration(days: 1))),
        ),
        VaultDocumentsCompanion.insert(
          id: 'vault-3',
          title: 'School records',
          category: const Value('Family'),
          fileName: 'school-records.pdf',
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(days: 7))),
          updatedAt: Value(now.subtract(const Duration(days: 7))),
        ),
      ]);
    });
  }

  Future<void> _seedTimeline() async {
    final now = DateTime.now();
    await batch((b) {
      b.insertAll(timelineEvents, [
        TimelineEventsCompanion.insert(
          id: 'tl-1',
          message: 'Kamran completed grocery shopping',
          memberId: const Value('dad'),
          memberName: const Value('Kamran'),
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(minutes: 20))),
        ),
        TimelineEventsCompanion.insert(
          id: 'tl-2',
          message: 'Sara uploaded car insurance',
          memberId: const Value('mom'),
          memberName: const Value('Sara'),
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(hours: 1))),
        ),
        TimelineEventsCompanion.insert(
          id: 'tl-3',
          message: 'Noor watered the plants',
          memberId: const Value('noor'),
          memberName: const Value('Noor'),
          dirty: const Value(false),
          createdAt: Value(now.subtract(const Duration(hours: 2))),
        ),
      ]);
    });
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in main()');
});
