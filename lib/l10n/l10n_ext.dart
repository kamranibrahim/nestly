import 'package:flutter/widgets.dart';

import '../data/enums.dart';
import '../data/family_needs.dart';
import '../data/member_roles.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

extension NestlyL10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension CalendarMemberFilterL10n on CalendarMemberFilter {
  String display(AppLocalizations l10n) => switch (this) {
        CalendarMemberFilter.all => l10n.commonAll,
        CalendarMemberFilter.adults => l10n.filterAdults,
        CalendarMemberFilter.kids => l10n.filterKids,
        CalendarMemberFilter.grandparents => l10n.filterGrandparents,
      };
}

extension CalendarBrowseModeL10n on CalendarBrowseMode {
  String display(AppLocalizations l10n) => switch (this) {
        CalendarBrowseMode.month => l10n.calendarBrowseMonth,
        CalendarBrowseMode.week => l10n.calendarBrowseWeek,
        CalendarBrowseMode.agenda => l10n.calendarBrowseAgenda,
      };
}

extension EventRecurrenceL10n on EventRecurrence {
  String display(AppLocalizations l10n) => switch (this) {
        EventRecurrence.none => l10n.eventRecurrenceNone,
        EventRecurrence.daily => l10n.eventRecurrenceDaily,
        EventRecurrence.weekly => l10n.eventRecurrenceWeekly,
        EventRecurrence.monthly => l10n.eventRecurrenceMonthly,
      };
}

extension CareViewModeL10n on CareViewMode {
  String display(AppLocalizations l10n) => switch (this) {
        CareViewMode.due => l10n.careViewDue,
        CareViewMode.category => l10n.careViewCategory,
      };
}

extension CareCategoryL10n on CareCategory {
  String display(AppLocalizations l10n) => switch (this) {
        CareCategory.all => l10n.commonAll,
        CareCategory.elder => l10n.careCategoryElder,
        CareCategory.home => l10n.careCategoryHome,
        CareCategory.pet => l10n.careCategoryPet,
        CareCategory.car => l10n.careCategoryCar,
      };
}

extension SchoolKindL10n on SchoolKind {
  String display(AppLocalizations l10n) => switch (this) {
        SchoolKind.all => l10n.commonAll,
        SchoolKind.school => l10n.schoolKindSchool,
        SchoolKind.sports => l10n.schoolKindSports,
        SchoolKind.pickup => l10n.schoolKindPickup,
        SchoolKind.club => l10n.schoolKindClub,
      };
}

extension ShoppingCategoryL10n on ShoppingCategory {
  String display(AppLocalizations l10n) => switch (this) {
        ShoppingCategory.produce => l10n.shopProduce,
        ShoppingCategory.dairy => l10n.shopDairy,
        ShoppingCategory.meat => l10n.shopMeat,
        ShoppingCategory.bakery => l10n.shopBakery,
        ShoppingCategory.pantry => l10n.shopPantry,
        ShoppingCategory.frozen => l10n.shopFrozen,
        ShoppingCategory.household => l10n.shopHousehold,
        ShoppingCategory.general => l10n.shopGeneral,
        ShoppingCategory.meals => l10n.shopMeals,
      };
}

extension ShoppingListFilterL10n on ShoppingListFilter {
  String display(AppLocalizations l10n) {
    if (isAll) return l10n.commonAll;
    return ShoppingCategory.parse(label).display(l10n);
  }
}

extension ExpenseCategoryL10n on ExpenseCategory {
  String display(AppLocalizations l10n) => switch (this) {
        ExpenseCategory.groceries => l10n.expenseGroceries,
        ExpenseCategory.transport => l10n.expenseTransport,
        ExpenseCategory.kids => l10n.expenseKids,
        ExpenseCategory.home => l10n.expenseHome,
        ExpenseCategory.dining => l10n.expenseDining,
        ExpenseCategory.health => l10n.expenseHealth,
        ExpenseCategory.general => l10n.expenseGeneral,
      };
}

extension VaultFolderL10n on VaultFolder {
  String display(AppLocalizations l10n) => switch (this) {
        VaultFolder.family => l10n.vaultFamily,
        VaultFolder.health => l10n.vaultHealth,
        VaultFolder.house => l10n.vaultHouse,
        VaultFolder.work => l10n.vaultWork,
        VaultFolder.car => l10n.vaultCar,
        VaultFolder.finance => l10n.vaultFinance,
        VaultFolder.ids => l10n.vaultIds,
      };
}

extension TaskDueLabelL10n on TaskDueLabel {
  String display(AppLocalizations l10n) => switch (this) {
        TaskDueLabel.today => l10n.taskDueToday,
        TaskDueLabel.tomorrow => l10n.taskDueTomorrow,
        TaskDueLabel.in7Days => l10n.taskDueIn7Days,
      };
}

extension TimelineModuleL10n on TimelineModule {
  String display(AppLocalizations l10n) => switch (this) {
        TimelineModule.all => l10n.timelineAll,
        TimelineModule.tasks => l10n.timelineTasks,
        TimelineModule.shopping => l10n.timelineLists,
        TimelineModule.care => l10n.timelineCare,
        TimelineModule.meals => l10n.timelineMeals,
        TimelineModule.vault => l10n.timelineVault,
        TimelineModule.school => l10n.timelineSchool,
        TimelineModule.other => l10n.timelineOther,
      };
}

extension LocatorFilterL10n on LocatorFilter {
  String display(AppLocalizations l10n) => switch (this) {
        LocatorFilter.all => l10n.locatorAll,
        LocatorFilter.fresh => l10n.locatorFresh,
        LocatorFilter.stale => l10n.locatorStale,
      };
}

extension ScanDraftKindL10n on ScanDraftKind {
  String display(AppLocalizations l10n) => switch (this) {
        ScanDraftKind.event => l10n.scanKindEvent,
        ScanDraftKind.expense => l10n.scanKindExpense,
        ScanDraftKind.bill => l10n.scanKindBill,
        ScanDraftKind.task => l10n.scanKindTask,
      };
}

String localizedMemberRole(String role, AppLocalizations l10n) {
  switch (MemberRoles.normalize(role)) {
    case MemberRoles.adult:
      return l10n.roleAdult;
    case MemberRoles.coParent:
      return l10n.roleCoParent;
    case MemberRoles.kid:
      return l10n.roleKid;
    case MemberRoles.grandparent:
      return l10n.roleGrandparent;
    default:
      return l10n.roleMember;
  }
}

extension FamilyNeedL10n on FamilyNeed {
  String titleFor(AppLocalizations l10n) {
    switch (variant) {
      case FamilyNeedVariant.quietDay:
        return l10n.needQuietDay;
      case FamilyNeedVariant.dinnerMissing:
        return l10n.needDinnerMissing;
      case FamilyNeedVariant.dinnerPlanned:
        return l10n.needDinnerPlanned(dinnerTitle?.trim() ?? '');
      case FamilyNeedVariant.grocerySuggestions:
        return l10n.needRestock(count);
      case FamilyNeedVariant.standard:
        switch (kind) {
          case FamilyNeedKind.care:
            return l10n.needCareDue(count);
          case FamilyNeedKind.school:
            return l10n.needSchoolDue(count);
          case FamilyNeedKind.bills:
            return l10n.needBillsDue(count);
          case FamilyNeedKind.tasks:
            return l10n.needTasksOpen(count);
          case FamilyNeedKind.shopping:
            return l10n.needShoppingLeft(count);
          case FamilyNeedKind.vault:
            return count == 1 ? l10n.needVaultOne : l10n.needVaultMany(count);
          case FamilyNeedKind.calendar:
            return l10n.needEventsToday(count);
          case FamilyNeedKind.meals:
            return l10n.needDinnerMissing;
        }
    }
  }

  String detailFor(AppLocalizations l10n) {
    switch (variant) {
      case FamilyNeedVariant.quietDay:
        return l10n.needQuietDetail;
      case FamilyNeedVariant.dinnerMissing:
        return l10n.needDinnerMissingDetail;
      case FamilyNeedVariant.dinnerPlanned:
        return l10n.needDinnerPlannedDetail;
      case FamilyNeedVariant.grocerySuggestions:
        return l10n.needRestockDetail;
      case FamilyNeedVariant.standard:
        switch (kind) {
          case FamilyNeedKind.care:
            return l10n.needCareDetail;
          case FamilyNeedKind.school:
            return l10n.needSchoolDetail;
          case FamilyNeedKind.bills:
            return l10n.needBillsDetail;
          case FamilyNeedKind.tasks:
            return l10n.needTasksDetail;
          case FamilyNeedKind.shopping:
            return l10n.needShoppingDetail;
          case FamilyNeedKind.vault:
            return l10n.needVaultDetail;
          case FamilyNeedKind.calendar:
            return l10n.needEventsDetail;
          case FamilyNeedKind.meals:
            return l10n.needDinnerMissingDetail;
        }
    }
  }

  String actionFor(AppLocalizations l10n) => switch (action) {
        FamilyNeedAction.done => l10n.commonDone,
        FamilyNeedAction.paid => l10n.commonPaid,
        FamilyNeedAction.openList => l10n.needShoppingOpenList,
        FamilyNeedAction.restock => l10n.commonRestock,
        FamilyNeedAction.review => l10n.commonReview,
        FamilyNeedAction.plan => l10n.commonPlan,
        FamilyNeedAction.shop => l10n.tabShop,
        FamilyNeedAction.calendar => l10n.tabCalendar,
        FamilyNeedAction.view => l10n.commonView,
      };
}
