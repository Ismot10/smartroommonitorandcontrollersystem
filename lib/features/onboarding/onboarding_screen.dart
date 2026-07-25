import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() {
    return _OnboardingScreenState();
  }
}

class _OnboardingScreenState
    extends State<OnboardingScreen> {
  final PageController _pageController =
  PageController();

  int _currentPage = 0;

  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      icon: Icons.sensors_rounded,
      title: 'See your room\nat a glance.',
      description:
      'Monitor temperature, humidity, smoke, motion, '
          'rain and light conditions in real time.',
      startColor: Color(0xFF176B4A),
      endColor: Color(0xFF75B83B),
    ),
    _OnboardingItem(
      icon: Icons.tune_rounded,
      title: 'Control every\ndetail beautifully.',
      description:
      'Manage lights, RGB ambience, curtains, alarms, '
          'fan and door access from one place.',
      startColor: Color(0xFF5B45C8),
      endColor: Color(0xFF9C7AF2),
    ),
    _OnboardingItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Automation that\nprotects and helps.',
      description:
      'Create intelligent rules for comfort, safety, '
          'security and emergency response.',
      startColor: Color(0xFFD98425),
      endColor: Color(0xFFFFC857),
    ),
  ];

  bool get _isLastPage {
    return _currentPage == _items.length - 1;
  }

  Future<void> _finishOnboarding() async {
    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      'hasSeenOnboarding',
      true,
    );

    if (!mounted) {
      return;
    }

    context.go('/login');
  }

  Future<void> _nextPage() async {
    if (_isLastPage) {
      await _finishOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              Color(0xFFEAF3DD),
              Color(0xFFF7EFDF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  12,
                  14,
                  0,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Aurora',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _finishOnboarding,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _items.length,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    return _OnboardingPage(
                      item: _items[index],
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _items.length,
                      (index) {
                    final isSelected =
                        index == _currentPage;

                    return AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 250),
                      width: isSelected ? 28 : 8,
                      height: 8,
                      margin:
                      const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.primaryDark
                            .withValues(alpha: 0.2),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  0,
                  22,
                  24,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: FilledButton(
                    onPressed: _nextPage,
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(22),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLastPage
                              ? 'Get started'
                              : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.arrow_forward_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.item,
  });

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        22,
        20,
        22,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.startColor,
                    item.endColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(38),
                boxShadow: [
                  BoxShadow(
                    color: item.startColor.withValues(
                      alpha: 0.24,
                    ),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -55,
                    right: -50,
                    child: Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.10,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -45,
                    left: -35,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(
                          alpha: 0.08,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: 0.16,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(
                            alpha: 0.24,
                          ),
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: 72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 34),

          Text(
            item.title,
            style: Theme.of(context)
                .textTheme
                .headlineLarge
                ?.copyWith(
              fontSize: 37,
              height: 1.1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),

          const SizedBox(height: 15),

          Text(
            item.description,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(
              color: AppColors.lightTextSecondary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.startColor,
    required this.endColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color startColor;
  final Color endColor;
}