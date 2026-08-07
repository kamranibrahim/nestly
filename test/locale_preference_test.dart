import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/locale_preference.dart';
import 'package:nestly/l10n/app_localizations.dart';
import 'package:nestly/l10n/test_app.dart';

void main() {
  group('LocalePreference.resolve', () {
    test('explicit english always wins', () {
      expect(
        LocalePreference.resolve(
          preference: LocalePreference.english,
          deviceLocale: const Locale('ar'),
        ),
        const Locale('en'),
      );
    });

    test('explicit arabic always wins', () {
      expect(
        LocalePreference.resolve(
          preference: LocalePreference.arabic,
          deviceLocale: const Locale('en'),
        ),
        const Locale('ar'),
      );
    });

    test('system follows arabic device', () {
      expect(
        LocalePreference.resolve(
          preference: LocalePreference.system,
          deviceLocale: const Locale('ar', 'SA'),
        ),
        const Locale('ar'),
      );
    });

    test('system falls back to english for other devices', () {
      expect(
        LocalePreference.resolve(
          preference: LocalePreference.system,
          deviceLocale: const Locale('fr'),
        ),
        const Locale('en'),
      );
    });

    test('parse storage values', () {
      expect(LocalePreference.parse('ar'), LocalePreference.arabic);
      expect(LocalePreference.parse('en'), LocalePreference.english);
      expect(LocalePreference.parse('system'), LocalePreference.system);
      expect(LocalePreference.parse(null), LocalePreference.system);
      expect(LocalePreference.parse('nope'), LocalePreference.system);
    });
  });

  testWidgets('arabic locale is RTL', (tester) async {
    late TextDirection direction;
    await tester.pumpWidget(
      CasaioTestApp(
        locale: const Locale('ar'),
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return Text(AppLocalizations.of(context).tabHome);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(direction, TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);
  });
}
