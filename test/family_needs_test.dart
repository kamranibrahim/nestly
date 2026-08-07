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
    expect(summary.needs.first.variant, FamilyNeedVariant.quietDay);
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
    expect(meal.variant, FamilyNeedVariant.dinnerPlanned);
    expect(meal.dinnerTitle, 'Tacos');
    expect(meal.action, FamilyNeedAction.shop);
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
    expect(school.action, FamilyNeedAction.done);
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
    expect(vault.count, 2);
    expect(vault.action, FamilyNeedAction.review);
  });

  test('caps needs list at five highest priority items', () {
    final summary = buildFamilyNeeds(
      openTasks: 2,
      openShopping: 3,
      unpaidBillsDueSoon: 1,
      careDue: 1,
      schoolDue: 1,
      dinnerPlannedToday: false,
      eventsToday: 2,
      vaultExpiringSoon: 1,
      grocerySuggestions: 4,
    );

    expect(summary.needs, hasLength(5));
    expect(summary.needs.first.kind, FamilyNeedKind.care);
    expect(
      summary.needs.map((n) => n.kind),
      isNot(contains(FamilyNeedKind.calendar)),
    );
  });

  test('restock suggestions only when shopping list is empty', () {
    final withOpen = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 2,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
      grocerySuggestions: 5,
    );
    expect(
      withOpen.needs.where((n) => n.kind == FamilyNeedKind.shopping),
      hasLength(1),
    );
    expect(
      withOpen.needs.firstWhere((n) => n.kind == FamilyNeedKind.shopping).variant,
      FamilyNeedVariant.standard,
    );

    final restock = buildFamilyNeeds(
      openTasks: 0,
      openShopping: 0,
      unpaidBillsDueSoon: 0,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
      grocerySuggestions: 5,
    );
    expect(
      restock.needs.firstWhere((n) => n.kind == FamilyNeedKind.shopping).variant,
      FamilyNeedVariant.grocerySuggestions,
    );
  });

  test('singular counts for one task and one bill', () {
    final summary = buildFamilyNeeds(
      openTasks: 1,
      openShopping: 0,
      unpaidBillsDueSoon: 1,
      careDue: 0,
      schoolDue: 0,
      dinnerPlannedToday: true,
      eventsToday: 0,
    );

    expect(
      summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.tasks).count,
      1,
    );
    expect(
      summary.needs.firstWhere((n) => n.kind == FamilyNeedKind.bills).count,
      1,
    );
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
