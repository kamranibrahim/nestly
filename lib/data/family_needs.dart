/// Quiet, local-only “what does our family need today?” — no model calls.
class FamilyNeed {
  const FamilyNeed({
    required this.title,
    required this.detail,
    required this.kind,
    this.actionLabel = 'Open',
  });

  final String title;
  final String detail;
  final FamilyNeedKind kind;
  /// Short CTA shown on Home (e.g. Done, Open list).
  final String actionLabel;
}

enum FamilyNeedKind { tasks, shopping, bills, care, school, meals, calendar }

class FamilyNeedsSummary {
  const FamilyNeedsSummary(this.needs);

  final List<FamilyNeed> needs;

  bool get isEmpty => needs.isEmpty;
}

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
}) {
  final needs = <FamilyNeed>[];

  if (openTasks > 0) {
    needs.add(
      FamilyNeed(
        title: '$openTasks open task${openTasks == 1 ? '' : 's'}',
        detail: 'Finish one now or open the list',
        kind: FamilyNeedKind.tasks,
        actionLabel: 'Done',
      ),
    );
  }
  if (openShopping > 0) {
    needs.add(
      FamilyNeed(
        title: '$openShopping grocery item${openShopping == 1 ? '' : 's'} left',
        detail: 'Check them off on the shared list',
        kind: FamilyNeedKind.shopping,
        actionLabel: 'Open list',
      ),
    );
  } else if (grocerySuggestions > 0) {
    needs.add(
      FamilyNeed(
        title:
            'Restock $grocerySuggestions usual item${grocerySuggestions == 1 ? '' : 's'}',
        detail: 'Based on what you buy often',
        kind: FamilyNeedKind.shopping,
        actionLabel: 'Restock',
      ),
    );
  }
  if (unpaidBillsDueSoon > 0) {
    needs.add(
      FamilyNeed(
        title:
            '$unpaidBillsDueSoon bill${unpaidBillsDueSoon == 1 ? '' : 's'} due soon',
        detail: 'Mark paid when you’ve settled them',
        kind: FamilyNeedKind.bills,
        actionLabel: 'Paid',
      ),
    );
  }
  if (careDue > 0) {
    needs.add(
      FamilyNeed(
        title: '$careDue care item${careDue == 1 ? '' : 's'} due',
        detail: 'Mark done when finished',
        kind: FamilyNeedKind.care,
        actionLabel: 'Done',
      ),
    );
  }
  if (schoolDue > 0) {
    needs.add(
      FamilyNeed(
        title:
            '$schoolDue school / pickup${schoolDue == 1 ? '' : 's'} due',
        detail: 'Confirm who’s covering the run',
        kind: FamilyNeedKind.school,
        actionLabel: 'Open',
      ),
    );
  }
  if (!dinnerPlannedToday) {
    needs.add(
      const FamilyNeed(
        title: 'No dinner planned today',
        detail: 'Add a meal — ingredients can go to the list',
        kind: FamilyNeedKind.meals,
        actionLabel: 'Plan',
      ),
    );
  } else if (dinnerTitle != null && dinnerTitle.trim().isNotEmpty) {
    needs.add(
      FamilyNeed(
        title: 'Dinner: ${dinnerTitle.trim()}',
        detail: 'Push ingredients to the grocery list',
        kind: FamilyNeedKind.meals,
        actionLabel: 'Shop',
      ),
    );
  }
  if (eventsToday == 0 && needs.isEmpty) {
    needs.add(
      const FamilyNeed(
        title: 'Quiet day',
        detail: 'Nothing urgent — a good time to plan ahead',
        kind: FamilyNeedKind.calendar,
        actionLabel: 'Calendar',
      ),
    );
  } else if (eventsToday > 0) {
    needs.add(
      FamilyNeed(
        title: '$eventsToday event${eventsToday == 1 ? '' : 's'} today',
        detail: 'Open Calendar so nobody is surprised',
        kind: FamilyNeedKind.calendar,
        actionLabel: 'View',
      ),
    );
  }

  return FamilyNeedsSummary(needs.take(5).toList());
}
