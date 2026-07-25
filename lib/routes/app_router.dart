import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/authentication/forgot_password_screen.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/registration_screen.dart';
import '../features/dashboard/main_shell.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../core/constants/app_config.dart';
import '../providers/automation_provider.dart';
import '../providers/alert_provider.dart';
import '../providers/device_provider.dart';
import '../providers/history_provider.dart';
import '../providers/sensor_provider.dart';
import '../services/firebase_device_repository.dart';
import '../services/firebase_alert_repository.dart';
import '../services/firebase_automation_repository.dart';
import '../services/firebase_history_repository.dart';
import '../services/firebase_sensor_repository.dart';
import '../services/mock_history_repository.dart';
import '../services/mock_sensor_repository.dart';
import '../services/sensor_repository.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      builder: (context, state) {
        return const OnboardingScreen();
      },
    ),

    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) {
        return const LoginScreen();
      },
    ),

    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) {
        return const RegistrationScreen();
      },
    ),

    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) {
        return const ForgotPasswordScreen();
      },
    ),

    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) {
        final SensorRepository sensorRepository = AppConfig.useMockData
            ? MockSensorRepository()
            : FirebaseSensorRepository();

        return MultiProvider(
          providers: [
            ChangeNotifierProvider<SensorProvider>(
              create: (_) =>
                  SensorProvider(repository: sensorRepository)..start(),
            ),
            ChangeNotifierProvider<DeviceProvider>(
              create: (_) => DeviceProvider(
                repository: AppConfig.useMockData
                    ? null
                    : FirebaseDeviceRepository(),
              )..start(),
            ),
            ChangeNotifierProvider<AlertProvider>(
              create: (_) => AlertProvider(
                repository: AppConfig.useMockData
                    ? null
                    : FirebaseAlertRepository(),
              )..start(),
            ),
          ],
          child:
              ChangeNotifierProxyProvider3<
                SensorProvider,
                DeviceProvider,
                AlertProvider,
                AutomationProvider
              >(
                create: (_) => AutomationProvider(
                  repository: AppConfig.useMockData
                      ? null
                      : FirebaseAutomationRepository(
                          defaults: AutomationProvider.defaultRules,
                        ),
                )..start(),
                update:
                    (
                      _,
                      sensorProvider,
                      deviceProvider,
                      alertProvider,
                      automationProvider,
                    ) {
                      final provider =
                          automationProvider ??
                          (AutomationProvider(
                            repository: AppConfig.useMockData
                                ? null
                                : FirebaseAutomationRepository(
                                    defaults: AutomationProvider.defaultRules,
                                  ),
                          )..start());

                      provider.updateDependencies(
                        sensorProvider: sensorProvider,
                        deviceProvider: deviceProvider,
                        alertProvider: alertProvider,
                      );

                      return provider;
                    },
                child:
                    ChangeNotifierProxyProvider<
                      SensorProvider,
                      HistoryProvider
                    >(
                      create: (_) {
                        return HistoryProvider(
                          repository: AppConfig.useMockData
                              ? MockHistoryRepository()
                              : FirebaseHistoryRepository(),
                        )..start();
                      },
                      update: (_, sensorProvider, historyProvider) {
                        final provider =
                            historyProvider ??
                            (HistoryProvider(
                              repository: AppConfig.useMockData
                                  ? MockHistoryRepository()
                                  : FirebaseHistoryRepository(),
                            )..start());

                        provider.captureSensorData(sensorProvider.data);

                        return provider;
                      },
                      child: const MainShell(),
                    ),
              ),
        );
      },
    ),
  ],
);
