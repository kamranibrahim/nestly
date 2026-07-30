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

  test('dinner shop CTA when meal planned with title', () {
    final summary = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
      dinnerTitle: 'Tacos',
    );

    expect(
      summary.needs.any((n) => n.kind == FamilyNeedKind.meals),
      isTrue,
    );
    final meal = summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.meals);
    expect(meal.title, 'Dinner: Tacos');
    expect(meal.actionLabel, 'Shop');
  });

  test('school due uses Done action', () {
    final summary = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 2,
      dinnerPlannedToday: true,
      eventsToday: 0,
    );

    final school =
        summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.school);
    expect(school.actionLabel, 'Done');
  });

  test('vault expiring soon surfaces on Home needs', () {
    final summary = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
      vaultExpiringSoon: 2,
    );

    final vault =
        summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.vault);
    expect(vault.title, contains('vault'));
    expect(vault.actionLabel, 'Open');
  });

  test('due care ranks above missing dinner and open tasks', () {
    final summary = buildFamilyNeeds(
      openTasks: 3,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 1,
      schoolDue: 0,
      dinnerPlannedToday: false,
      eventsToday: 0,
    );

    expect(summary.needs.first.kind, FamilyNeedKind.care);
    expect(
      summary.needs.map((n) => n.kind).toList(),
      containsAll([
        FamilyNeedKind.care,
        FamilyNeedKind.tasks,
        FamilyNeedKind.meals,
      ]),
    );
    final careIndex =
        summary.needs.indexWhere((n) => n.kind == FamilyNeedKind.care);
    final dinnerIndex =
        summary.needs.indexWhere((n) => n.kind == FamilyNeedKind.meals);
    expect(careIndex, lessThan(dinnerIndex));
  });
}
