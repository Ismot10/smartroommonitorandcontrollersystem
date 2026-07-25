import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';

import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() {
    return _SplashScreenState();
  }
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _continueToNextScreen();
  }

  Future<void> _continueToNextScreen() async {
    // Keep the existing splash visible briefly.
    await Future<void>.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) {
      return;
    }

    final authProvider =
    context.read<AuthProvider>();

    // Wait until Firebase restores the previous session.
    await authProvider.waitUntilReady();

    if (!mounted) {
      return;
    }

    if (AppConfig.alwaysShowOnboarding) {
      context.go('/onboarding');
      return;
    }

    final preferences =
    await SharedPreferences.getInstance();

    final hasSeenOnboarding =
        preferences.getBool(
          'hasSeenOnboarding',
        ) ??
            false;

    if (!mounted) {
      return;
    }

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
      return;
    }

    context.go(
      authProvider.isSignedIn
          ? '/home'
          : '/login',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              Color(0xFFE7F2D8),
              Color(0xFFF7F0DD),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),

                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryDark.withValues(
                          alpha: 0.25,
                        ),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Smart living,\nbeautifully controlled.',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(
                    fontSize: 38,
                    height: 1.12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Monitor your room, control connected devices '
                      'and automate everyday comfort.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(
                    color:
                    AppColors.lightTextSecondary,
                    height: 1.6,
                  ),
                ),

                const Spacer(),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.75,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 6,
                        backgroundColor: AppColors.safe,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Preparing your smart room',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}