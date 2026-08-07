import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/l10n/test_app.dart';
import 'package:nestly/screens/app_shell.dart';

Future<void> _pumpUntilHome(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text('Lists').evaluate().isNotEmpty) {
      // Clear staggered Appear timers on Home.
      await tester.pump(const Duration(milliseconds: 800));
      return;
    }
  }
}

void main() {
  testWidgets('Casaio home shows family hub and feature tiles', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await database.ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const CasaioTestApp(home: AppShell()),
      ),
    );
    await _pumpUntilHome(tester);

    expect(find.text('Lists'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is Tooltip && (w).message == 'Home',
      ),
      findsOneWidget,
    );
    expect(find.text('Tasks'), findsWidgets);
    expect(find.text('Today snapshot'), findsOneWidget);
    expect(find.textContaining('Hello'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
    await database.close();
  });
}
