import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/db/app_database.dart';
import 'package:nestly/main.dart';

void main() {
  testWidgets('Nestly home shows family hub and feature tiles', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    await database.ensureSeeded();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(database)],
        child: const NestlyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('The Ibrahims'), findsWidgets);
    expect(find.text('Lists'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tasks'), findsWidgets);

    // Close Drift streams before the test binding checks for pending timers.
    await database.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
