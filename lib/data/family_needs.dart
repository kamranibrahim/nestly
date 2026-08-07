import 'enums.dart';

export 'enums.dart' show FamilyNeedKind;

enum FamilyNeedVariant {
  standard,
  grocerySuggestions,
  dinnerMissing,
  dinnerPlanned,
  quietDay,
}

enum FamilyNeedAction {
  done,
  paid,
  openList,
  restock,
  review,
  plan,
  shop,
  calendar,
  view,
}

/// Quiet, local-only “what does our family need today?” — no model calls.
/// Copy is localized at the UI boundary via [FamilyNeedL10n].
class FamilyNeed {
  const FamilyNeed({
    required this.kind,
    required this.action,
    this.count = 0,
    this.dinnerTitle,
    this.variant = FamilyNeedVariant.standard,
    this.priority = 0,
  });

  final FamilyNeedKind kind;
  final FamilyNeedAction action;
  final int count;
  final String? dinnerTitle;
  final FamilyNeedVariant variant;
  final int priority;
}

class FamilyNeedsSummary {
  const FamilyNeedsSummary(this.needs);

  final List<FamilyNeed> needs;

  bool get isEmpty => needs.isEmpty;
}

/// Soft-launch ranking: due care/school/bills before open work, then shopping,
/// vault, dinner gap, and calendar info last.
FamilyNeedsSummary buildFamilyNeeds({
  required int openTasks,
  required int openShopping,
  required int unpaidBillsDueSoon,
  required int careDue,
  required int schoolDue,
  required bool dinnerPlannedToday,
  required int eventsToday,
  int grocerySuggestions = 0,
  String? dinnerTitle,
  int vaultExpiringSoon = 0,
}) {
  final needs = <FamilyNeed>[];

  if (careDue > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.care,
        action: FamilyNeedAction.done,
        count: careDue,
        priority: 100,
      ),
    );
  }
  if (schoolDue > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.school,
        action: FamilyNeedAction.done,
        count: schoolDue,
        priority: 95,
      ),
    );
  }
  if (unpaidBillsDueSoon > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.bills,
        action: FamilyNeedAction.paid,
        count: unpaidBillsDueSoon,
        priority: 90,
      ),
    );
  }
  if (openTasks > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.tasks,
        action: FamilyNeedAction.done,
        count: openTasks,
        priority: 80,
      ),
    );
  }
  if (openShopping > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.shopping,
        action: FamilyNeedAction.openList,
        count: openShopping,
        priority: 70,
      ),
    );
  } else if (grocerySuggestions > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.shopping,
        action: FamilyNeedAction.restock,
        count: grocerySuggestions,
        variant: FamilyNeedVariant.grocerySuggestions,
        priority: 55,
      ),
    );
  }
  if (vaultExpiringSoon > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.vault,
        action: FamilyNeedAction.review,
        count: vaultExpiringSoon,
        priority: 65,
      ),
    );
  }
  if (!dinnerPlannedToday) {
    needs.add(
      const FamilyNeed(
        kind: FamilyNeedKind.meals,
        action: FamilyNeedAction.plan,
        variant: FamilyNeedVariant.dinnerMissing,
        priority: 50,
      ),
    );
  } else if (dinnerTitle != null && dinnerTitle.trim().isNotEmpty) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.meals,
        action: FamilyNeedAction.shop,
        dinnerTitle: dinnerTitle.trim(),
        variant: FamilyNeedVariant.dinnerPlanned,
        priority: 40,
      ),
    );
  }
  if (eventsToday == 0 && needs.isEmpty) {
    needs.add(
      const FamilyNeed(
        kind: FamilyNeedKind.calendar,
        action: FamilyNeedAction.calendar,
        variant: FamilyNeedVariant.quietDay,
        priority: 10,
      ),
    );
  } else if (eventsToday > 0) {
    needs.add(
      FamilyNeed(
        kind: FamilyNeedKind.calendar,
        action: FamilyNeedAction.view,
        count: eventsToday,
        priority: 30,
      ),
    );
  }

  needs.sort((a, b) => b.priority.compareTo(a.priority));
  return FamilyNeedsSummary(needs.take(5).toList());
}
