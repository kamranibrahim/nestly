import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/widgets/invite_family_sheet.dart';

void main() {
  group('normalizeInviteCode', () {
    test('uppercases and strips spaces/dashes', () {
      expect(normalizeInviteCode('ab cd-ef'), 'ABCDEF');
    });

    test('truncates past six characters', () {
      expect(normalizeInviteCode('ABCDEFGH'), 'ABCDEF');
    });

    test('empty paste stays empty', () {
      expect(normalizeInviteCode('   ---  '), '');
    });
  });

  group('inviteShareText', () {
    test('includes code and nest name', () {
      final text = inviteShareText(inviteCode: 'ABC123', nestName: 'Smith Nest');
      expect(text, contains('Smith Nest'));
      expect(text, contains('ABC123'));
      expect(text, contains('Have an invite code'));
      expect(text, contains(nestlyInviteMarketingUrl));
    });

    test('falls back when nest name blank', () {
      final text = inviteShareText(inviteCode: 'XYZ999', nestName: '  ');
      expect(text, contains('our family nest'));
      expect(text, contains('XYZ999'));
    });
  });

  testWidgets('invite sheet shows code and share actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showInviteFamilySheet(
                  context,
                  inviteCode: 'ab-cd ef',
                  nestName: 'Demo Nest',
                ),
                child: const Text('Open invite'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open invite'));
    await tester.pumpAndSettle();

    expect(find.text('Invite family'), findsOneWidget);
    expect(find.text('ABCDEF'), findsOneWidget);
    expect(find.text('Share invite'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
  });

  testWidgets('post-create invite sheet offers skip', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => showInviteFamilySheet(
                  context,
                  inviteCode: 'NESTLY',
                  isPostCreate: true,
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Nest ready'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });
}
