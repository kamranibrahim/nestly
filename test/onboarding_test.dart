import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/l10n/test_app.dart';
import 'package:nestly/screens/onboarding/onboarding_screen.dart';

Future<void> _settleFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('onboarding shows first page and advances', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const CasaioTestApp(home: OnboardingScreen()),
      ),
    );
    await _settleFrames(tester);

    expect(find.textContaining('Perfectly Organize'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Family, Simplified'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await _settleFrames(tester);

    expect(find.textContaining('Quiet help when'), findsOneWidget);
    expect(find.text('Scan suggestion'), findsOneWidget);
    expect(find.textContaining('Suggested expense'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await database.close();
  });

  testWidgets('skip marks onboarding seen', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const CasaioTestApp(home: OnboardingScreen()),
      ),
    );
    await _settleFrames(tester);

    await tester.tap(find.text('Skip'));
    await _settleFrames(tester);

    expect(await database.getMeta('onboardingSeen'), '1');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await database.close();
  });
}
