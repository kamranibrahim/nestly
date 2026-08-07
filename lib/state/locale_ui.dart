import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/locale_preference.dart';
import '../data/nest_home_widget.dart';
import '../providers/providers.dart';

export '../data/locale_preference.dart' show LocalePreference;

/// Persisted language preference (not autoDispose — lives for the app session).
class LocaleController extends StateNotifier<LocalePreference> {
  LocaleController(this._db, {this.onChanged}) : super(LocalePreference.system) {
    _hydrate();
  }

  final AppDatabase _db;
  final Future<void> Function()? onChanged;
  bool _ready = false;

  bool get ready => _ready;

  Future<void> _hydrate() async {
    final stored = await _db.getMeta(LocalePreference.metaKey);
    if (!mounted) return;
    state = LocalePreference.parse(stored);
    _ready = true;
  }

  Future<void> setPreference(LocalePreference preference) async {
    if (state == preference && _ready) return;
    state = preference;
    _ready = true;
    await _db.setMeta(LocalePreference.metaKey, preference.storage);
    await onChanged?.call();
  }

  Locale resolve([Locale? deviceLocale]) {
    return LocalePreference.resolve(
      preference: state,
      deviceLocale:
          deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale,
    );
  }
}

final localePreferenceProvider =
    StateNotifierProvider<LocaleController, LocalePreference>((ref) {
  return LocaleController(
    ref.watch(databaseProvider),
    onChanged: () async {
      try {
        await ref.read(notificationServiceProvider).rescheduleReminders();
      } catch (_) {}
      try {
        final nest = ref.read(nestInfoProvider).valueOrNull;
        await NestHomeWidget.publishFromDatabase(
          ref.read(databaseProvider),
          nestName: nest?.name,
        );
      } catch (_) {}
    },
  );
});

final resolvedAppLocaleProvider = Provider<Locale>((ref) {
  final preference = ref.watch(localePreferenceProvider);
  return LocalePreference.resolve(
    preference: preference,
    deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
  );
});
