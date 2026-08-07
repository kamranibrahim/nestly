import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import 'db/app_database.dart';
import 'locale_preference.dart';

/// Resolve persisted language preference + device locale to [AppLocalizations].
Future<AppLocalizations> resolvedAppLocalizations(AppDatabase db) async {
  final pref = LocalePreference.parse(await db.getMeta(LocalePreference.metaKey));
  return lookupAppLocalizations(
    LocalePreference.resolve(
      preference: pref,
      deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
    ),
  );
}
