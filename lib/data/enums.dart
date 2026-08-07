/// Shared Casaio enums — storage labels stay stable for Drift / Firestore.
library;

// ---------------------------------------------------------------------------
// Calendar
// ---------------------------------------------------------------------------

enum CalendarBrowseMode { month, week }

enum CalendarMemberFilter {
  all('All'),
  adults('Adults'),
  kids('Kids'),
  grandparents('Grandparents');

  const CalendarMemberFilter(this.label);
  final String label;

  static const pills = values;
}

// ---------------------------------------------------------------------------
// Care / school
// ---------------------------------------------------------------------------

enum CareViewMode {
  due('Due'),
  category('By category');

  const CareViewMode(this.label);
  final String label;
}

enum CareCategory {
  all('All'),
  elder('Elder'),
  home('Home'),
  pet('Pet'),
  car('Car');

  const CareCategory(this.label);
  final String label;

  bool get isAll => this == all;

  static CareCategory parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final cat in values) {
      if (cat.label.toLowerCase() == value || cat.name == value) return cat;
    }
    return all;
  }

  static const stored = [elder, home, pet, car];
}

enum CareItemAction { edit, snooze, skip, delete }

enum SchoolKind {
  all('All'),
  school('School'),
  sports('Sports'),
  pickup('Pickup'),
  club('Club');

  const SchoolKind(this.label);
  final String label;

  bool get isAll => this == all;

  static SchoolKind parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final kind in values) {
      if (kind.label.toLowerCase() == value || kind.name == value) return kind;
    }
    return all;
  }

  static const stored = [school, sports, pickup, club];
}

enum SchoolItemAction { calendar, snooze, skip, delete }

// ---------------------------------------------------------------------------
// Shopping / expenses / vault
// ---------------------------------------------------------------------------

enum ShoppingCategory {
  produce('Produce'),
  dairy('Dairy'),
  meat('Meat'),
  bakery('Bakery'),
  pantry('Pantry'),
  frozen('Frozen'),
  household('Household'),
  general('General'),
  meals('Meals');

  const ShoppingCategory(this.label);
  final String label;

  static const listValues = values;

  static ShoppingCategory parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final cat in values) {
      if (cat.label.toLowerCase() == value || cat.name == value) return cat;
    }
    return general;
  }
}

enum ShoppingListFilter {
  all('All'),
  produce('Produce'),
  dairy('Dairy'),
  meat('Meat'),
  bakery('Bakery'),
  pantry('Pantry'),
  frozen('Frozen'),
  household('Household'),
  general('General'),
  meals('Meals');

  const ShoppingListFilter(this.label);
  final String label;

  bool get isAll => this == all;

  ShoppingCategory? get asCategory {
    if (isAll) return null;
    return ShoppingCategory.parse(label);
  }

  static ShoppingListFilter fromCategory(ShoppingCategory category) {
    return parse(category.label);
  }

  static ShoppingListFilter parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final filter in values) {
      if (filter.label.toLowerCase() == value || filter.name == value) {
        return filter;
      }
    }
    return all;
  }
}

enum ExpenseCategory {
  groceries('Groceries'),
  transport('Transport'),
  kids('Kids'),
  home('Home'),
  dining('Dining'),
  health('Health'),
  general('General');

  const ExpenseCategory(this.label);
  final String label;

  static ExpenseCategory parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final cat in values) {
      if (cat.label.toLowerCase() == value || cat.name == value) return cat;
    }
    return general;
  }
}

enum VaultFolder {
  family('Family'),
  health('Health'),
  house('House'),
  work('Work'),
  car('Car'),
  finance('Finance'),
  ids('IDs');

  const VaultFolder(this.label);
  final String label;

  static const allLabel = 'All';

  static VaultFolder parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final folder in values) {
      if (folder.label.toLowerCase() == value || folder.name == value) {
        return folder;
      }
    }
    return family;
  }

  static bool isAll(String category) =>
      category.trim().isEmpty || category.trim().toLowerCase() == 'all';
}

enum VaultUploadStatus {
  local('local', 'Local'),
  uploading('uploading', 'Uploading'),
  synced('synced', 'Synced'),
  failed('failed', 'Failed');

  const VaultUploadStatus(this.storage, this.displayLabel);
  final String storage;
  final String displayLabel;

  static const all = values;

  static VaultUploadStatus parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final status in values) {
      if (status.storage == value || status.name == value) return status;
    }
    return local;
  }

  static VaultUploadStatus coerce(Object status) {
    if (status is VaultUploadStatus) return status;
    return parse('$status');
  }

  static String label(Object status) => coerce(status).displayLabel;

  static bool needsUpload(Object status) {
    final value = coerce(status);
    return value == local || value == failed;
  }
}

// ---------------------------------------------------------------------------
// Tasks / meals / scan / emergency
// ---------------------------------------------------------------------------

enum TaskDueLabel {
  today('Today'),
  tomorrow('Tomorrow'),
  in7Days('In 7 days');

  const TaskDueLabel(this.label);
  final String label;

  TaskDueLabel get next => switch (this) {
    today => tomorrow,
    tomorrow => in7Days,
    in7Days => today,
  };

  static TaskDueLabel? tryParse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final due in values) {
      if (due.label.toLowerCase() == value || due.name.toLowerCase() == value) {
        return due;
      }
    }
    return null;
  }

  static TaskDueLabel parse(String raw) => tryParse(raw) ?? today;

  DateTime dueDate({required DateTime now}) {
    final todayDate = DateTime(now.year, now.month, now.day);
    return switch (this) {
      today => todayDate,
      tomorrow => todayDate.add(const Duration(days: 1)),
      in7Days => todayDate.add(const Duration(days: 7)),
    };
  }

  static DateTime? dueDateFor(String label, {required DateTime now}) {
    return tryParse(label)?.dueDate(now: now);
  }
}

enum MealsEntry { browse, planWeek, addDinnerToday }

enum ScanDraftKind {
  event,
  expense,
  bill,
  task;

  String get label => '${name[0].toUpperCase()}${name.substring(1)}';

  static ScanDraftKind? tryParse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final kind in values) {
      if (kind.name == value) return kind;
    }
    return null;
  }

  static ScanDraftKind parse(String raw) => tryParse(raw) ?? event;
}

enum EmergencyIcon {
  phone,
  doctor,
  hospital,
  warning,
  blood,
  shield,
  info;

  static EmergencyIcon parse(String raw) {
    final value = raw.trim().toLowerCase();
    for (final icon in values) {
      if (icon.name == value) return icon;
    }
    return info;
  }
}

// ---------------------------------------------------------------------------
// Navigation / notifications / timeline / home
// ---------------------------------------------------------------------------

enum NotificationDestination {
  bills('bills'),
  care('care'),
  school('school'),
  calendar('calendar'),
  tasks('tasks');

  const NotificationDestination(this.payload);
  final String payload;

  static NotificationDestination? tryParse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'bills':
      case 'budget':
        return bills;
      case 'care':
        return care;
      case 'school':
        return school;
      case 'calendar':
      case 'event':
      case 'events':
        return calendar;
      case 'tasks':
      case 'task':
        return tasks;
      default:
        return null;
    }
  }
}

enum CasaioDeepLink {
  home,
  calendar,
  tasks,
  meals,
  shopping;

  static CasaioDeepLink parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'calendar':
        return calendar;
      case 'tasks':
        return tasks;
      case 'meals':
      case 'dinner':
        return meals;
      case 'shopping':
        return shopping;
      case 'home':
      case '':
      default:
        return home;
    }
  }
}

enum TimelineModule {
  all('All'),
  tasks('Tasks'),
  shopping('Lists'),
  care('Care'),
  meals('Meals'),
  vault('Vault'),
  school('School'),
  other('Other');

  const TimelineModule(this.label);
  final String label;
}

enum FamilyNeedKind {
  tasks,
  shopping,
  bills,
  care,
  school,
  meals,
  calendar,
  vault,
}

enum WidgetHeroKind { quiet, tasks, event, dinner }

enum PendingAdd { none, event, task, shopping }

enum LocatorFilter { all, fresh, stale }
