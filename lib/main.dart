import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_user_profile_repository.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.setPersistenceCacheSizeBytes(20 * 1024 * 1024);
  }

  await NotificationService.instance.initialize();

  final authService = FirebaseAuthService(
    firebaseAuth: firebase_auth.FirebaseAuth.instance,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider()..load(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService: authService),
        ),
        ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
          create: (_) => SettingsProvider(
            profileRepository: FirebaseUserProfileRepository(),
          )..load(),
          update: (_, auth, settings) {
            final provider =
                settings ??
                (SettingsProvider(
                  profileRepository: FirebaseUserProfileRepository(),
                )..load());

            provider.bindUser(
              uid: auth.userId,
              email: auth.userEmail,
              authDisplayName: auth.displayName,
            );
            return provider;
          },
        ),
      ],
      child: const SmartRoomApp(),
    ),
  );
}
