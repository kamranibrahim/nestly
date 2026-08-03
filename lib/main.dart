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
import 'navigation/app_navigator.dart';
import 'screens/auth_gate.dart';
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
      child: const NestlyApp(),
    ),
  );
}

class NestlyApp extends StatefulWidget {
  const NestlyApp({super.key});

  @override
  State<NestlyApp> createState() => _NestlyAppState();
}

class _NestlyAppState extends State<NestlyApp> {
  @override
  void initState() {
    super.initState();
    NestHomeWidget.bindLaunchHandling(openNestlyUri);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Nestly',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const AuthGate(),
    );
  }
}
