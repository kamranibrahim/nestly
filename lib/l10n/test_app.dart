import 'package:flutter/material.dart';

import 'app_localizations.dart';

/// Shared [MaterialApp] wrapper so widget tests include gen-l10n delegates.
class CasaioTestApp extends StatelessWidget {
  const CasaioTestApp({
    super.key,
    required this.home,
    this.locale = const Locale('en'),
  });

  final Widget home;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );
  }
}
