import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/config/environment.dart';
import 'firebase_options.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/services/demo_doctor_seeder.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

const _envString =
String.fromEnvironment('ENV', defaultValue: 'development');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

// Temporary demo data setup.
  await seedDemoDoctors();

  final env = environmentFromString(_envString);
  final config = AppConfig.forEnvironment(env);

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const HomeDocApp(),
    ),
  );
}