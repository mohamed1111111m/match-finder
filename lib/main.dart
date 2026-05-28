import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/services/notification_service.dart';
import 'core/utils/logger.dart';
import 'features/auth/data/repositories/demo_auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/chat/data/repositories/demo_chat_repository.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/tournaments/data/repositories/demo_tournament_repository.dart';
import 'features/tournaments/presentation/providers/tournament_provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  AppLogger.init();

  bool demoMode = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kDebugMode) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }

    await NotificationService.instance.initialize();
    AppLogger.info('App started (Firebase mode)');
  } catch (e) {
    demoMode = true;
    AppConfig.enableDemoMode();
    AppLogger.warning('Firebase unavailable — running in DEMO MODE');
  }

  runApp(
    ProviderScope(
      overrides: demoMode ? _buildDemoOverrides() : const [],
      child: const EkoraApp(),
    ),
  );
}

List<Override> _buildDemoOverrides() => [
      authRepositoryProvider.overrideWith((ref) => DemoAuthRepository()),
      tournamentRepositoryProvider
          .overrideWith((ref) => DemoTournamentRepository()),
      chatRepositoryProvider.overrideWith((ref) => DemoChatRepository()),
    ];
