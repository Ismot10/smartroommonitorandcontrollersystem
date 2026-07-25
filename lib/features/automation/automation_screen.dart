import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/automation_rule.dart';
import '../../providers/automation_provider.dart';

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider =
    context.watch<AutomationProvider>();

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
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
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  16,
                  22,
                  120,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const _AutomationHeader(),

                      const SizedBox(height: 22),

                      _AutomationHero(
                        masterEnabled:
                        provider.masterEnabled,
                        enabledRules:
                        provider.enabledRuleCount,
                        activeRules:
                        provider.activeRuleCount,
                        totalRules:
                        provider.rules.length,
                        onMasterChanged:
                        provider.toggleMaster,
                      ),

                      const SizedBox(height: 30),

                      const _SectionHeader(
                        title: 'Smart rules',
                        subtitle:
                        'Rules respond automatically to your live sensor data.',
                      ),

                      const SizedBox(height: 15),

                      ...provider.rules.map(
                            (rule) => Padding(
                          padding:
                          const EdgeInsets.only(
                            bottom: 15,
                          ),
                          child: _AutomationRuleCard(
                            rule: rule,
                            isActive:
                            provider.isRuleActive(
                              rule.id,
                            ),
                            onToggle: (value) {
                              provider.toggleRule(
                                rule.id,
                                value,
                              );
                            },
                            onEdit: () {
                              _showRuleEditor(
                                context,
                                rule,
                              );
                            },
                            onTest: () {
                              provider.runRuleTest(
                                rule.id,
                              );

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${rule.title} test completed.',
                                  ),
                                  behavior:
                                  SnackBarBehavior
                                      .floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Row(
                        children: [
                          Expanded(
                            child: _SectionHeader(
                              title:
                              'Recent activity',
                              subtitle:
                              'Actions performed by your automation rules.',
                            ),
                          ),
                          if (provider.events.isNotEmpty)
                            TextButton(
                              onPressed:
                              provider.clearActivity,
                              child:
                              const Text('Clear'),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      if (provider.events.isEmpty)
                        const _EmptyActivityCard()
                      else
                        ...provider.events
                            .take(8)
                            .map(
                              (event) => Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              bottom: 12,
                            ),
                            child:
                            _AutomationEventCard(
                              event: event,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showRuleEditor(
      BuildContext context,
      AutomationRule rule,
      ) async {
    var draftThreshold =
        rule.triggerValue ?? 0;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor:
      AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32),
        ),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            final range =
            _sliderRange(rule.type);

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  8,
                  22,
                  24 +
                      MediaQuery.viewInsetsOf(
                        context,
                      ).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration:
                            BoxDecoration(
                              color:
                              _accentForRule(
                                rule.type,
                              ).withValues(
                                alpha: 0.14,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(18),
                            ),
                            child: Icon(
                              _iconForRule(
                                rule.type,
                              ),
                              color:
                              _accentForRule(
                                rule.type,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  rule.title,
                                  style: Theme.of(
                                    context,
                                  )
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                    fontWeight:
                                    FontWeight
                                        .w800,
                                  ),
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                const Text(
                                  'Automation rule settings',
                                  style: TextStyle(
                                    color: AppColors
                                        .lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      SwitchListTile.adaptive(
                        contentPadding:
                        EdgeInsets.zero,
                        title: const Text(
                          'Enable this rule',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                        subtitle: const Text(
                          'Allow this rule to perform automatic actions.',
                        ),
                        value: rule.enabled,
                        onChanged: (value) {
                          context
                              .read<
                              AutomationProvider>()
                              .toggleRule(
                            rule.id,
                            value,
                          );
                        },
                      ),

                      if (range != null) ...[
                        const SizedBox(height: 18),

                        const Text(
                          'Trigger threshold',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          _thresholdDescription(
                            rule.type,
                          ),
                          style: const TextStyle(
                            color: AppColors
                                .lightTextSecondary,
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
                          child: Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                            decoration:
                            BoxDecoration(
                              color:
                              _accentForRule(
                                rule.type,
                              ).withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                            ),
                            child: Text(
                              '${_formatThreshold(draftThreshold)} ${rule.unit}',
                              style: TextStyle(
                                color:
                                _accentForRule(
                                  rule.type,
                                ),
                                fontSize: 26,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Slider(
                          min: range.$1,
                          max: range.$2,
                          divisions: range.$3,
                          value: draftThreshold
                              .clamp(
                            range.$1,
                            range.$2,
                          )
                              .toDouble(),
                          activeColor:
                          _accentForRule(
                            rule.type,
                          ),
                          label:
                          '${_formatThreshold(draftThreshold)} ${rule.unit}',
                          onChanged: (value) {
                            setModalState(() {
                              draftThreshold =
                                  value;
                            });
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      const Text(
                        'Automatic actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        rule.actions.map(
                              (action) {
                            return Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration:
                              BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                BorderRadius
                                    .circular(18),
                              ),
                              child: Row(
                                mainAxisSize:
                                MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons
                                        .check_circle_rounded,
                                    color: AppColors
                                        .safe,
                                    size: 17,
                                  ),
                                  const SizedBox(
                                    width: 7,
                                  ),
                                  Text(
                                    action,
                                    style:
                                    const TextStyle(
                                      fontSize: 12,
                                      fontWeight:
                                      FontWeight
                                          .w700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ).toList(),
                      ),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: () {
                            if (range != null) {
                              context
                                  .read<
                                  AutomationProvider>()
                                  .updateThreshold(
                                rule.id,
                                draftThreshold,
                              );
                            }

                            Navigator.pop(
                              sheetContext,
                            );
                          },
                          style:
                          FilledButton.styleFrom(
                            backgroundColor:
                            AppColors.primaryDark,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                            ),
                          ),
                          child: const Text(
                            'Save rule',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static (double, double, int)?
  _sliderRange(
      AutomationRuleType type,
      ) {
    switch (type) {
      case AutomationRuleType.temperatureFan:
        return (18, 40, 22);

      case AutomationRuleType.lowLight:
        return (0, 1000, 20);

      case AutomationRuleType.gasEmergency:
        return (100, 1000, 18);

      case AutomationRuleType.motionSecurity:
      case AutomationRuleType.rainCurtain:
        return null;
    }
  }

  static String _thresholdDescription(
      AutomationRuleType type,
      ) {
    switch (type) {
      case AutomationRuleType.temperatureFan:
        return 'The virtual fan turns on when temperature reaches this value.';

      case AutomationRuleType.lowLight:
        return 'The room light turns on when light intensity falls below this value.';

      case AutomationRuleType.gasEmergency:
        return 'Emergency actions start when the gas reading reaches this value.';

      case AutomationRuleType.motionSecurity:
        return '';

      case AutomationRuleType.rainCurtain:
        return '';
    }
  }

  static String _formatThreshold(
      double value,
      ) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }
}

class _AutomationHeader extends StatelessWidget {
  const _AutomationHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Automation',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(
                  fontWeight:
                  FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Intelligent responses for comfort, safety and security.',
                style: TextStyle(
                  color: AppColors
                      .lightTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.8,
            ),
            borderRadius:
            BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _AutomationHero extends StatelessWidget {
  const _AutomationHero({
    required this.masterEnabled,
    required this.enabledRules,
    required this.activeRules,
    required this.totalRules,
    required this.onMasterChanged,
  });

  final bool masterEnabled;
  final int enabledRules;
  final int activeRules;
  final int totalRules;
  final ValueChanged<bool> onMasterChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(34),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: masterEnabled
              ? const [
            Color(0xFF176B4A),
            Color(0xFF42A15A),
            Color(0xFF8BCD4C),
          ]
              : const [
            Color(0xFF777E79),
            Color(0xFFA2A7A3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (
                masterEnabled
                    ? AppColors.primaryDark
                    : AppColors.offline
            ).withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'SMART AUTOMATION',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              Switch.adaptive(
                value: masterEnabled,
                onChanged: onMasterChanged,
                activeTrackColor:
                Colors.white38,
                activeThumbColor:
                Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 19),
          Text(
            masterEnabled
                ? 'Your room is thinking ahead.'
                : 'Automation is currently paused.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              height: 1.14,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            masterEnabled
                ? '$enabledRules of $totalRules rules are enabled.'
                : 'Manual device controls remain available.',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroValue(
                  value: '$enabledRules',
                  label: 'Enabled',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroValue(
                  value: '$activeRules',
                  label: 'Active now',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  const _HeroValue({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(alpha: 0.16),
        borderRadius:
        BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AutomationRuleCard
    extends StatelessWidget {
  const _AutomationRuleCard({
    required this.rule,
    required this.isActive,
    required this.onToggle,
    required this.onEdit,
    required this.onTest,
  });

  final AutomationRule rule;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    final accent =
    _accentForRule(rule.type);

    return AnimatedContainer(
      duration:
      const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: rule.enabled ? 0.84 : 0.58,
        ),
        borderRadius:
        BorderRadius.circular(28),
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.55)
              : Colors.white.withValues(
            alpha: 0.9,
          ),
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? accent.withValues(alpha: 0.13)
                : Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 22,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: 0.13,
                  ),
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: Icon(
                  _iconForRule(rule.type),
                  color: accent,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            rule.title,
                            style: Theme.of(
                              context,
                            )
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .w800,
                            ),
                          ),
                        ),
                        Switch.adaptive(
                          value: rule.enabled,
                          onChanged: onToggle,
                        ),
                      ],
                    ),
                    Text(
                      rule.description,
                      style: const TextStyle(
                        color: AppColors
                            .lightTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _RuleStatusChip(
                text: isActive
                    ? 'ACTIVE NOW'
                    : rule.enabled
                    ? 'READY'
                    : 'DISABLED',
                color: isActive
                    ? accent
                    : rule.enabled
                    ? AppColors.safe
                    : AppColors.offline,
              ),

              if (rule.triggerValue !=
                  null) ...[
                const SizedBox(width: 8),
                _RuleStatusChip(
                  text:
                  '${_formatRuleThreshold(rule.triggerValue!)} ${rule.unit}',
                  color:
                  AppColors.lightText,
                ),
              ],

              const Spacer(),

              TextButton.icon(
                onPressed: onTest,
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: const Text('Test'),
              ),

              IconButton(
                onPressed: onEdit,
                tooltip: 'Edit rule',
                icon: const Icon(
                  Icons.tune_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatRuleThreshold(
      double value,
      ) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

class _RuleStatusChip extends StatelessWidget {
  const _RuleStatusChip({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius:
        BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}

class _AutomationEventCard
    extends StatelessWidget {
  const _AutomationEventCard({
    required this.event,
  });

  final AutomationEvent event;

  @override
  Widget build(BuildContext context) {
    final accent =
    _severityColor(event.severity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(alpha: 0.8),
        borderRadius:
        BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(
            alpha: 0.9,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color:
              accent.withValues(alpha: 0.12),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Icon(
              event.isTest
                  ? Icons.science_rounded
                  : Icons.bolt_rounded,
              color: accent,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontWeight:
                          FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      DateFormat('h:mm a')
                          .format(
                        event.createdAt,
                      ),
                      style: const TextStyle(
                        color: AppColors
                            .lightTextSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  event.message,
                  style: const TextStyle(
                    color: AppColors
                        .lightTextSecondary,
                    height: 1.45,
                  ),
                ),
                if (event.isTest) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'TEST EVENT',
                    style: TextStyle(
                      color: AppColors
                          .accentPurple,
                      fontSize: 9,
                      fontWeight:
                      FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivityCard
    extends StatelessWidget {
  const _EmptyActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color:
        Colors.white.withValues(alpha: 0.75),
        borderRadius:
        BorderRadius.circular(26),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.history_toggle_off_rounded,
            color: AppColors.primaryDark,
            size: 31,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'No automation activity yet',
                  style: TextStyle(
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Activity will appear when a rule runs or when you test one.',
                  style: TextStyle(
                    color: AppColors
                        .lightTextSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight:
            FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color:
            AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

IconData _iconForRule(
    AutomationRuleType type,
    ) {
  switch (type) {
    case AutomationRuleType.temperatureFan:
      return Icons.thermostat_rounded;

    case AutomationRuleType.lowLight:
      return Icons.lightbulb_outline_rounded;

    case AutomationRuleType.motionSecurity:
      return Icons.security_rounded;

    case AutomationRuleType.rainCurtain:
      return Icons.water_drop_rounded;

    case AutomationRuleType.gasEmergency:
      return Icons.warning_amber_rounded;
  }
}

Color _accentForRule(
    AutomationRuleType type,
    ) {
  switch (type) {
    case AutomationRuleType.temperatureFan:
      return AppColors.temperature;

    case AutomationRuleType.lowLight:
      return AppColors.accentYellow;

    case AutomationRuleType.motionSecurity:
      return AppColors.accentPurple;

    case AutomationRuleType.rainCurtain:
      return AppColors.rain;

    case AutomationRuleType.gasEmergency:
      return AppColors.danger;
  }
}

Color _severityColor(
    AutomationSeverity severity,
    ) {
  switch (severity) {
    case AutomationSeverity.info:
      return AppColors.primaryDark;

    case AutomationSeverity.warning:
      return AppColors.warning;

    case AutomationSeverity.critical:
      return AppColors.danger;
  }
}