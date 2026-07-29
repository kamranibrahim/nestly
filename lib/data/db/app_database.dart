import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(nestMembers);
            await m.createTable(calendarEvents);
            await m.createTable(syncMeta);
            await m.addColumn(tasks, tasks.nestId);
            await m.addColumn(tasks, tasks.dirty);
            await m.addColumn(tasks, tasks.deleted);
            await m.addColumn(shoppingLists, shoppingLists.nestId);
            await m.addColumn(shoppingLists, shoppingLists.dirty);
            await m.addColumn(shoppingLists, shoppingLists.deleted);
            await m.addColumn(shoppingLists, shoppingLists.updatedAt);
            await m.addColumn(shoppingItems, shoppingItems.nestId);
            await m.addColumn(shoppingItems, shoppingItems.dirty);
            await m.addColumn(shoppingItems, shoppingItems.deleted);
          }
          if (from < 3) {
            await m.createTable(expenses);
            await m.createTable(bills);
            await m.createTable(emergencyEntries);
          }
          if (from < 4) {
            await m.createTable(vaultDocuments);
            await m.createTable(timelineEvents);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'nestly',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }

  Future<String?> getMeta(String key) async {
    final row = await (select(syncMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setMeta(String key, String value) {
    return into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(key: key, value: value),
    );
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
      b.deleteAll(nestMembers);
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
      b.insertAll(tasks, [
        TasksCompanion.insert(
          id: 'task-1',
          title: 'Buy groceries',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Today'),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-2',
          title: 'Pack soccer kit',
          assigneeId: const Value('ayaan'),
          dueLabel: const Value('Today'),
          dirty: const Value(false),
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
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-4',
          title: 'Clean kitchen',
          assigneeId: const Value('mom'),
          dueLabel: const Value('Tomorrow'),
          recurring: const Value(true),
          dirty: const Value(false),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
        TasksCompanion.insert(
          id: 'task-5',
          title: 'Pay internet bill',
          assigneeId: const Value('dad'),
          dueLabel: const Value('Fri'),
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
          colorValue: 0xFF4A78DD,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'mom',
          nestId: 'local',
          name: 'Sara',
          role: const Value('Mom'),
          initials: 'S',
          colorValue: 0xFFE56B9A,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'ayaan',
          nestId: 'local',
          name: 'Ayaan',
          role: const Value('Son'),
          initials: 'A',
          colorValue: 0xFF3CB371,
          dirty: const Value(false),
          updatedAt: Value(now),
        ),
        NestMembersCompanion.insert(
          id: 'noor',
          nestId: 'local',
          name: 'Noor',
          role: const Value('Daughter'),
          initials: 'N',
          colorValue: 0xFFF29B4A,
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
