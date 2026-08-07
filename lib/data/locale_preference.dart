import 'package:flutter/widgets.dart';

/// In-app language override. Stored on [AppDatabase] syncMeta as `appLocale`.
enum LocalePreference {
  system('system'),
  english('en'),
  arabic('ar');

  const LocalePreference(this.storage);

  final String storage;

  static const metaKey = 'appLocale';

  static const supported = [Locale('en'), Locale('ar')];

  /// `null` means MaterialApp should follow the device locale.
  Locale? get materialLocale => switch (this) {
        system => null,
        english => const Locale('en'),
        arabic => const Locale('ar'),
      };

  static LocalePreference parse(String? raw) {
    switch (raw?.trim().toLowerCase()) {
      case 'en':
      case 'english':
        return english;
      case 'ar':
      case 'arabic':
        return arabic;
      case 'system':
      case '':
      case null:
        return system;
      default:
        return system;
    }
  }

  /// Explicit en/ar always wins. System follows the device when it is en or ar,
  /// otherwise English.
  static Locale resolve({
    required LocalePreference preference,
    required Locale deviceLocale,
  }) {
    switch (preference) {
      case LocalePreference.english:
        return const Locale('en');
      case LocalePreference.arabic:
        return const Locale('ar');
      case LocalePreference.system:
        if (deviceLocale.languageCode.toLowerCase() == 'ar') {
          return const Locale('ar');
        }
        return const Locale('en');
    }
  }
}
