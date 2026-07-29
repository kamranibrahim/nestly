import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/family_needs.dart';

void main() {
  test('quiet summary surfaces open work and missing dinner', () {
    final summary = buildFamilyNeeds(
      openTasks: 2,
      openShopping: 0,
      unpaidBillsDueSoon: 1,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: false,
      eventsToday: 1,
    );

    expect(summary.needs.length, greaterThanOrEqualTo(3));
    expect(
      summary.needs.any((n) => n.kind == FamilyNeedKind.tasks),
      isTrue,
    );
    expect(
      summary.needs.any((n) => n.kind == FamilyNeedKind.meals),
      isTrue,
    );
  });

  test('quiet day when nothing is pending', () {
    final summary = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
    );

    expect(summary.needs, hasLength(1));
    expect(summary.needs.first.kind, FamilyNeedKind.calendar);
    expect(summary.needs.first.title, 'Quiet day');
  });

  test('restock suggestion when list empty but habits due', () {
    final summary = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
      grocerySuggestions: 3,
    );

    expect(
      summary.needs.any((n) => n.kind == FamilyNeedKind.shopping),
      isTrue,
    );
    expect(
      summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.shopping).title,
      contains('Restock'),
    );
  });
}
