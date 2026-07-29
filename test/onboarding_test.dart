import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/screens/onboarding/onboarding_screen.dart';

Future<void> _settleFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('onboarding shows first page and advances', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await _settleFrames(tester);

    expect(find.textContaining('Perfectly Organize'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Family, Simplified'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await _settleFrames(tester);

    expect(find.textContaining('AI That Organizes'), findsOneWidget);
    expect(find.text('School PTA Meeting'), findsOneWidget);

    await database.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('skip marks onboarding seen', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await _settleFrames(tester);

    await tester.tap(find.text('Skip'));
    await _settleFrames(tester);

    expect(await database.getMeta('onboardingSeen'), '1');

    await database.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
