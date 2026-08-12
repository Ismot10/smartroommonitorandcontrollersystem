import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../core/widgets/device_card.dart';
import '../../core/widgets/sensor_card.dart';
import '../../models/smart_device.dart';
import '../../providers/automation_provider.dart';
import '../../providers/alert_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/settings_provider.dart';
import '../history/history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.onDevicesTap,
    required this.onAlertsTap,
    required this.onProfileTap,
    super.key,
  });

  final VoidCallback onDevicesTap;
  final VoidCallback onAlertsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final sensorProvider = context.watch<SensorProvider>();

    final deviceProvider = context.watch<DeviceProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final alertProvider = context.watch<AlertProvider>();

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

                        const SensorCard(
                          title: 'System',
                          value: 'Online',
                          subtitle: 'ESP32 data gateway',
                          icon: Icons.wifi_rounded,
                          accentColor: AppColors.safe,
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
                      itemCount: devices.length >= 4 ? 4 : devices.length,
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
                        );
                      },
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

  static String _humidityDescription(double humidity) {
    if (humidity < 30) {
      return 'Air is dry';
    }

    if (humidity <= 65) {
      return 'Comfortable';
    }

    return 'High humidity';
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.roomStatus,
    required this.roomName,
    required this.displayName,
    required this.unreadAlertCount,
    required this.onAlertsTap,
    required this.onProfileTap,
  });

  final String roomStatus;
  final String roomName;
  final String displayName;
  final int unreadAlertCount;
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
              Text(
                roomName,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),

              const SizedBox(height: 5),

              Row(
                children: [
                  CircleAvatar(
                    radius: 5,
                    backgroundColor: _statusColor(roomStatus),
                  ),

                  const SizedBox(width: 8),

                  Flexible(
                    child: Text(
                      roomStatus,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _TemperatureHero extends StatelessWidget {
  const _TemperatureHero({
    required this.temperature,
    required this.humidity,
    required this.updatedAt,
  });

  final double temperature;
  final double humidity;
  final DateTime updatedAt;

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
          const Row(
            children: [
              Icon(Icons.thermostat_rounded, color: Colors.white),

              SizedBox(width: 8),

              Text(
                'INDOOR CLIMATE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),

              Spacer(),

              Icon(Icons.wifi_rounded, color: Colors.white, size: 19),
            ],
          ),

          const SizedBox(height: 25),

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
