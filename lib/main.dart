import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/db/app_database.dart';
import 'data/nest_home_widget.dart';
import 'data/notification_service.dart';
import 'data/telemetry.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'navigation/app_navigator.dart';
import 'screens/auth_gate.dart';
import 'state/locale_ui.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NestlyTelemetry.init();

  // Must be registered before runApp (FlutterFire requirement).
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await NestHomeWidget.ensureConfigured();

  final database = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const CasaioApp(),
    ),
  );
}

class CasaioApp extends ConsumerStatefulWidget {
  const CasaioApp({super.key});

  @override
  ConsumerState<CasaioApp> createState() => _CasaioAppState();
}

class _CasaioAppState extends ConsumerState<CasaioApp> {
  @override
  void initState() {
    super.initState();
    NestHomeWidget.bindLaunchHandling(openCasaioUri);
  }

  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(localePreferenceProvider);
    final resolved = LocalePreference.resolve(
      preference: preference,
      deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      locale: preference.materialLocale,
      supportedLocales: LocalePreference.supported,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: AppTheme.light(arabic: resolved.languageCode == 'ar'),
      builder: (context, child) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        );
      },
      home: const AuthGate(),
    );
  }
}
