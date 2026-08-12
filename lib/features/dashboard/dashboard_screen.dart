import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../core/widgets/device_card.dart';
import '../../core/widgets/sensor_card.dart';
import '../../models/smart_device.dart';
import '../../models/automation_rule.dart';
import '../../models/device_schedule.dart';
import '../../providers/automation_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/system_status_provider.dart';
import '../../providers/schedule_provider.dart';
import '../devices/device_detail_screen.dart';
import '../history/history_screen.dart';
import '../schedules/schedules_screen.dart';

String _repeatLabel(List<int> weekdays) {
  if (weekdays.isEmpty) return 'Once';
  if (weekdays.length == 7) return 'Every day';
  if (weekdays.length == 5 && const [1, 2, 3, 4, 5].every(weekdays.contains)) {
    return 'Weekdays';
  }
  if (weekdays.length == 2 && const [6, 7].every(weekdays.contains)) {
    return 'Weekends';
  }
  const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return weekdays.map((day) => names[day - 1]).join(', ');
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onDevicesTap,
    required this.onAlertsTap,
    required this.onAutomationTap,
    required this.onProfileTap,
    super.key,
  });

  final VoidCallback onDevicesTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onAutomationTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final sensorProvider = context.watch<SensorProvider>();

    final deviceProvider = context.watch<DeviceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final alertProvider = context.watch<AlertProvider>();
    final systemStatus = context.watch<SystemStatusProvider>();
    final automationProvider = context.watch<AutomationProvider>();
    final scheduleProvider = context.watch<ScheduleProvider>();

    final sensors = sensorProvider.data;
    final devices = deviceProvider.devices;

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
          bottom: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _DashboardHeader(
                      roomStatus: sensorProvider.roomStatus,
                      roomName: settingsProvider.roomName,
                      displayName: settingsProvider.displayName,
                      unreadAlertCount: alertProvider.unreadCount,
                      systemOnline: systemStatus.isOnline,
                      lastSeenLabel: systemStatus.lastSeenLabel,
                      onAlertsTap: onAlertsTap,
                      onProfileTap: onProfileTap,
                    ),

                    if (sensorProvider.isLoading ||
                        sensorProvider.error != null) ...[
                      const SizedBox(height: 18),
                      AsyncStatusCard(
                        isLoading: sensorProvider.isLoading,
                        error: sensorProvider.error,
                        loadingMessage: 'Loading live room data…',
                        errorTitle: 'Live sensor data is unavailable',
                        onRetry: sensorProvider.start,
                      ),
                    ],

                    const SizedBox(height: 26),

                    _TemperatureHero(
                      temperature: sensors.temperature,
                      humidity: sensors.humidity,
                      updatedAt: sensors.updatedAt,
                      roomStatus: sensorProvider.roomStatus,
                      gasDetected: sensors.gas >= 450,
                      raining: sensors.raining,
                      motionDetected: sensors.motionDetected,
                      isDark: sensors.lightLevel <= 100,
                    ),

                    const SizedBox(height: 28),

                    _SectionHeader(
                      title: 'Live environment',
                      actionText: 'View history',
                      onAction: () {
                        _openHistoryScreen(context);
                      },
                    ),

                    const SizedBox(height: 15),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 13,
                      crossAxisSpacing: 13,
                      childAspectRatio: 1.03,
                      children: [
                        SensorCard(
                          title: 'Temperature',
                          value: '${sensors.temperature.toStringAsFixed(1)}°C',
                          subtitle: _temperatureDescription(
                            sensors.temperature,
                          ),
                          icon: Icons.thermostat_rounded,
                          accentColor: AppColors.temperature,
                        ),
                        SensorCard(
                          title: 'Humidity',
                          value: '${sensors.humidity.toStringAsFixed(1)}%',
                          subtitle: _humidityDescription(sensors.humidity),
                          icon: Icons.water_drop_rounded,
                          accentColor: AppColors.humidity,
                        ),

                        SensorCard(
                          title: 'Smoke / Gas',
                          value: '${sensors.gas.toStringAsFixed(0)} ppm',
                          subtitle: sensors.gas >= 450
                              ? 'Danger detected'
                              : 'Air is safe',
                          icon: Icons.cloud_rounded,
                          accentColor: sensors.gas >= 450
                              ? AppColors.danger
                              : AppColors.gas,
                        ),

                        SensorCard(
                          title: 'Motion',
                          value: sensors.motionDetected ? 'Detected' : 'Clear',
                          subtitle: sensors.motionDetected
                              ? 'Activity in room'
                              : 'No recent movement',
                          icon: Icons.directions_walk_rounded,
                          accentColor: AppColors.motion,
                        ),

                        SensorCard(
                          title: 'Rain',
                          value: sensors.raining ? 'Raining' : 'Dry',
                          subtitle: sensors.raining
                              ? 'Curtain protection'
                              : 'No rainfall',
                          icon: Icons.water_rounded,
                          accentColor: AppColors.rain,
                        ),

                        SensorCard(
                          title: 'Room light',
                          value: '${sensors.lightLevel.toStringAsFixed(0)} lux',
                          subtitle: _lightDescription(sensors.lightLevel),
                          icon: Icons.wb_sunny_rounded,
                          accentColor: AppColors.light,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    _SectionHeader(
                      title: 'Quick controls',
                      actionText: 'All devices',
                      onAction: onDevicesTap,
                    ),

                    const SizedBox(height: 15),

                    GridView.builder(
                      itemCount: devices.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 13,
                            crossAxisSpacing: 13,
                            childAspectRatio: 1.05,
                          ),
                      itemBuilder: (context, index) {
                        final device = devices[index];

                        return DeviceCard(
                          device: device,
                          icon: _deviceIcon(device.type),
                          onToggle: () {
                            deviceProvider.toggle(device.id);
                          },
                          onOpen: () => _openDeviceDetail(context, device.id),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    _DashboardOverviewGrid(
                      automation: automationProvider,
                      schedule: scheduleProvider.upcoming,
                      alerts: alertProvider.alerts,
                      unreadCount: alertProvider.unreadCount,
                      onAutomationTap: onAutomationTap,
                      onSchedulesTap: () => _openSchedulesScreen(context),
                      onAlertsTap: onAlertsTap,
                    ),

                    const SizedBox(height: 30),

                    _RecentActivitySection(
                      events: alertProvider.alerts.take(3).toList(),
                      onViewAll: () => _openHistoryScreen(context),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openHistoryScreen(BuildContext context) {
    /*
     * AutomationProvider and HistoryProvider are
     * currently created inside the /home route.
     *
     * A newly pushed MaterialPageRoute is a separate
     * Navigator route, so we explicitly forward the
     * existing provider instances to HistoryScreen.
     *
     * ChangeNotifierProvider.value does not create
     * or dispose these existing objects.
     */

    final historyProvider = context.read<HistoryProvider>();

    final automationProvider = context.read<AutomationProvider>();

    final deviceProvider = context.read<DeviceProvider>();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<HistoryProvider>.value(
                value: historyProvider,
              ),
              ChangeNotifierProvider<AutomationProvider>.value(
                value: automationProvider,
              ),
              ChangeNotifierProvider<DeviceProvider>.value(
                value: deviceProvider,
              ),
            ],
            child: const HistoryScreen(),
          );
        },
      ),
    );
  }

  static void _openDeviceDetail(BuildContext context, String deviceId) {
    final devices = context.read<DeviceProvider>();
    final schedules = context.read<ScheduleProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: devices),
            ChangeNotifierProvider<ScheduleProvider>.value(value: schedules),
          ],
          child: DeviceDetailScreen(deviceId: deviceId),
        ),
      ),
    );
  }

  static void _openSchedulesScreen(BuildContext context) {
    final devices = context.read<DeviceProvider>();
    final schedules = context.read<ScheduleProvider>();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceProvider>.value(value: devices),
            ChangeNotifierProvider<ScheduleProvider>.value(value: schedules),
          ],
          child: const SchedulesScreen(),
        ),
      ),
    );
  }

  static String _humidityDescription(double humidity) {
    if (humidity < 30) {
      return 'Air is dry';
    }

    if (humidity <= 65) {
      return 'Comfortable';
    }

    return 'High humidity';
  }

  static String _temperatureDescription(double temperature) {
    if (temperature >= 30) return 'Warm room';
    if (temperature <= 20) return 'Cool room';
    return 'Comfortable';
  }

  static String _lightDescription(double lux) {
    if (lux < 100) {
      return 'Low light';
    }

    if (lux < 500) {
      return 'Soft daylight';
    }

    return 'Bright room';
  }

  static IconData _deviceIcon(DeviceType type) {
    return switch (type) {
      DeviceType.whiteLight => Icons.lightbulb_rounded,
      DeviceType.rgbLight => Icons.palette_rounded,
      DeviceType.curtain => Icons.curtains_rounded,
      DeviceType.buzzer => Icons.notifications_active_rounded,
      DeviceType.fan => Icons.air_rounded,
      DeviceType.doorLock => Icons.lock_rounded,
    };
  }
}

class _AnimatedSystemCard extends StatefulWidget {
  const _AnimatedSystemCard({
    required this.online,
    required this.lastSeenLabel,
    required this.hasError,
  });

  final bool? online;
  final String lastSeenLabel;
  final bool hasError;

  @override
  State<_AnimatedSystemCard> createState() => _AnimatedSystemCardState();
}

class _AnimatedSystemCardState extends State<_AnimatedSystemCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _AnimatedSystemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.online != widget.online) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.online == true) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.online;
    final color = online == true
        ? AppColors.safe
        : online == false
        ? AppColors.danger
        : AppColors.warning;
    final value = widget.hasError
        ? 'Unavailable'
        : online == true
        ? 'Online'
        : online == false
        ? 'Offline'
        : 'Checking';
    final icon = online == true
        ? Icons.wifi_rounded
        : online == false
        ? Icons.wifi_off_rounded
        : Icons.sync_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: online == true ? 0.10 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final pulse = 1 + (_pulseController.value * 0.07);
              return Transform.scale(scale: pulse, child: child);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(icon, key: ValueKey(icon), color: color, size: 21),
              ),
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.18),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              maxLines: 1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'System',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              widget.hasError ? 'Heartbeat unavailable' : widget.lastSeenLabel,
              key: ValueKey('${widget.hasError}-${widget.lastSeenLabel}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.roomStatus,
    required this.roomName,
    required this.displayName,
    required this.unreadAlertCount,
    required this.systemOnline,
    required this.lastSeenLabel,
    required this.onAlertsTap,
    required this.onProfileTap,
  });

  final String roomStatus;
  final String roomName;
  final String displayName;
  final int unreadAlertCount;
  final bool? systemOnline;
  final String lastSeenLabel;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aurora Smart Living',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                roomName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 5),

              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _HeaderStatus(
                    color: _statusColor(roomStatus),
                    label: roomStatus,
                  ),
                  _HeaderStatus(
                    color: systemOnline == true
                        ? AppColors.safe
                        : systemOnline == false
                        ? AppColors.danger
                        : AppColors.warning,
                    label: systemOnline == true
                        ? 'ESP32 Online • $lastSeenLabel'
                        : systemOnline == false
                        ? 'ESP32 Offline • $lastSeenLabel'
                        : 'Checking ESP32',
                  ),
                ],
              ),
            ],
          ),
        ),

        SizedBox(
          width: 49,
          height: 49,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: IconButton(
                    tooltip: 'Open alerts',
                    onPressed: onAlertsTap,
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ),
              ),
              if (unreadAlertCount > 0)
                Positioned(
                  right: -4,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      unreadAlertCount > 99 ? '99+' : '$unreadAlertCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        Semantics(
          button: true,
          label: 'Open profile',
          child: InkWell(
            onTap: onProfileTap,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primaryDark,
              child: Text(
                _initials(displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return 'AU';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _statusColor(String roomStatus) {
    switch (roomStatus) {
      case 'Emergency':
        return AppColors.danger;

      case 'Attention needed':
        return AppColors.warning;

      default:
        return AppColors.safe;
    }
  }
}

class _DashboardOverviewGrid extends StatelessWidget {
  const _DashboardOverviewGrid({
    required this.automation,
    required this.schedule,
    required this.alerts,
    required this.unreadCount,
    required this.onAutomationTap,
    required this.onSchedulesTap,
    required this.onAlertsTap,
  });

  final AutomationProvider automation;
  final DeviceSchedule? schedule;
  final List<AutomationEvent> alerts;
  final int unreadCount;
  final VoidCallback onAutomationTap;
  final VoidCallback onSchedulesTap;
  final VoidCallback onAlertsTap;

  @override
  Widget build(BuildContext context) {
    final criticalCount = alerts
        .where(
          (event) =>
              !event.isRead &&
              event.displaySeverity == AutomationSeverity.critical,
        )
        .length;
    final cards = [
      _OverviewCard(
        icon: Icons.auto_awesome_rounded,
        accent: automation.masterEnabled ? AppColors.safe : AppColors.offline,
        eyebrow: 'SMART AUTOMATION',
        title: automation.masterEnabled ? 'Automation ON' : 'Automation OFF',
        description:
            '${automation.enabledRuleCount} rules enabled • ${automation.activeRuleCount} active',
        action: 'View automation',
        onTap: onAutomationTap,
      ),
      _OverviewCard(
        icon: Icons.schedule_rounded,
        accent: AppColors.accentPurple,
        eyebrow: 'NEXT SCHEDULE',
        title: schedule?.name ?? 'No upcoming schedule',
        description: schedule == null
            ? 'Create a timed device action'
            : '${schedule!.actionLabel} ${schedule!.deviceName} • '
                  '${DateFormat.jm().format(schedule!.nextOccurrence()!)} • '
                  '${_repeatLabel(schedule!.weekdays)}',
        action: 'View schedules',
        onTap: onSchedulesTap,
      ),
      _OverviewCard(
        icon: criticalCount > 0
            ? Icons.warning_amber_rounded
            : Icons.notifications_rounded,
        accent: criticalCount > 0 ? AppColors.danger : AppColors.accentBlue,
        eyebrow: 'ALERT CENTRE',
        title: '$criticalCount Critical • $unreadCount Unread',
        description: criticalCount > 0
            ? 'Immediate attention required'
            : 'Room alerts and notifications',
        action: 'View alerts',
        onTap: onAlertsTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        return GridView.builder(
          itemCount: cards.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 13,
            crossAxisSpacing: 13,
            childAspectRatio: columns == 1 ? 2.25 : 1.55,
          ),
          itemBuilder: (_, index) => cards[index],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.accent,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.action,
    required this.onTap,
  });
  final IconData icon;
  final Color accent;
  final String eyebrow;
  final String title;
  final String description;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      eyebrow,
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$action →',
                style: TextStyle(color: accent, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.events, required this.onViewAll});
  final List<AutomationEvent> events;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionHeader(
          title: 'Recent activity',
          actionText: 'View all activity',
          onAction: onViewAll,
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          const _ActivityEmptyCard()
        else
          ...events.map(
            (event) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primaryLight,
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.displayTitle,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.lightTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat.jm().format(event.createdAt),
                    style: const TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ActivityEmptyCard extends StatelessWidget {
  const _ActivityEmptyCard();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.76),
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Text(
      'No recent activity. Your room is operating normally.',
      style: TextStyle(color: AppColors.lightTextSecondary),
    ),
  );
}

class _HeaderStatus extends StatelessWidget {
  const _HeaderStatus({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TemperatureHero extends StatelessWidget {
  const _TemperatureHero({
    required this.temperature,
    required this.humidity,
    required this.updatedAt,
    required this.roomStatus,
    required this.gasDetected,
    required this.raining,
    required this.motionDetected,
    required this.isDark,
  });

  final double temperature;
  final double humidity;
  final DateTime updatedAt;
  final String roomStatus;
  final bool gasDetected;
  final bool raining;
  final bool motionDetected;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF237C5B), Color(0xFF75B83B), Color(0xFFAEDB72)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 32,
            offset: const Offset(0, 17),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.home_rounded, color: Colors.white),

              SizedBox(width: 8),

              const Text(
                'ROOM STATUS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),

              Spacer(),

              const Spacer(),
              Icon(
                gasDetected
                    ? Icons.warning_amber_rounded
                    : Icons.verified_user_rounded,
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            gasDetected
                ? 'Attention required — gas detected'
                : roomStatus == 'Attention needed'
                ? 'Your room needs attention'
                : 'Everything looks good',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                temperature.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 66,
                  height: 0.9,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -4,
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 7),
                child: Text(
                  '°C',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const Spacer(),

              Container(
                width: 63,
                height: 63,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _temperatureIcon(temperature),
                  color: AppColors.accentYellow,
                  size: 31,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroCondition(label: gasDetected ? 'Gas detected' : 'No gas'),
              _HeroCondition(label: raining ? 'Rain' : 'No rain'),
              _HeroCondition(label: motionDetected ? 'Motion' : 'No motion'),
              _HeroCondition(label: isDark ? 'Dark' : 'Bright'),
            ],
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.water_drop_outlined,
                  color: Colors.white,
                  size: 18,
                ),

                const SizedBox(width: 7),

                Text(
                  '${humidity.toStringAsFixed(0)}% humidity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const Spacer(),

                Text(
                  'Updated ${DateFormat('h:mm a').format(updatedAt)}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _temperatureIcon(double temperature) {
    if (temperature >= 30) {
      return Icons.local_fire_department_rounded;
    }

    if (temperature <= 20) {
      return Icons.ac_unit_rounded;
    }

    return Icons.wb_sunny_rounded;
  }
}

class _HeroCondition extends StatelessWidget {
  const _HeroCondition({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),

        TextButton(onPressed: onAction, child: Text(actionText)),
      ],
    );
  }
}
