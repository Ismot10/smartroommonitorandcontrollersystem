import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/async_status_card.dart';
import '../../models/smart_device.dart';
import '../../providers/device_provider.dart';
import '../../providers/schedule_provider.dart';
import 'device_detail_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceProvider = context.watch<DeviceProvider>();
    final devices = deviceProvider.devices;

    final physicalCount = devices.where((d) => d.isPhysical).length;
    final virtualCount = devices.where((d) => !d.isPhysical).length;

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
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const _DevicesHeader(),
                    if (deviceProvider.isLoading ||
                        deviceProvider.error != null) ...[
                      const SizedBox(height: 18),
                      AsyncStatusCard(
                        isLoading: deviceProvider.isLoading,
                        error: deviceProvider.error,
                        loadingMessage: 'Loading your smart devices…',
                        errorTitle: 'Devices could not be refreshed',
                        onRetry: deviceProvider.start,
                      ),
                    ],
                    const SizedBox(height: 22),
                    _DevicesHero(
                      totalDevices: devices.length,
                      physicalCount: physicalCount,
                      virtualCount: virtualCount,
                    ),
                    const SizedBox(height: 28),
                    _SectionHeader(
                      title: 'All devices',
                      subtitle: 'Tap any device to open its control page.',
                    ),
                    const SizedBox(height: 14),
                    ...devices.map(
                      (device) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _DeviceShowcaseCard(device: device),
                      ),
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
}

class _DevicesHeader extends StatelessWidget {
  const _DevicesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Elegant control for every connected and virtual device.',
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
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
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.devices_other_rounded,
            color: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }
}

class _DevicesHero extends StatelessWidget {
  const _DevicesHero({
    required this.totalDevices,
    required this.physicalCount,
    required this.virtualCount,
  });

  final int totalDevices;
  final int physicalCount;
  final int virtualCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B4A), Color(0xFF3E9A56), Color(0xFF86C64A)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SMART DEVICE ECOSYSTEM',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Icon(Icons.hub_rounded, color: Colors.white, size: 34),
              const SizedBox(width: 14),
              Text(
                '$totalDevices devices',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStatChip(
                  title: 'Connected',
                  value: '$physicalCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatChip(title: 'Virtual', value: '$virtualCount'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _DeviceShowcaseCard extends StatelessWidget {
  const _DeviceShowcaseCard({required this.device});

  final SmartDevice device;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<DeviceProvider>();
    final scheduleProvider = context.read<ScheduleProvider>();
    final accent = _deviceAccent(device.type);
    final icon = _deviceIcon(device.type);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<DeviceProvider>.value(value: provider),
                  ChangeNotifierProvider<ScheduleProvider>.value(
                    value: scheduleProvider,
                  ),
                ],
                child: DeviceDetailScreen(deviceId: device.id),
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.90)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              _MiniIllustration(icon: icon, accentColor: accent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _deviceSubtitle(device),
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusBadge(
                          text: device.connectionLabel,
                          color: device.isPhysical
                              ? AppColors.primaryDark
                              : AppColors.accentBlue,
                          backgroundColor: device.isPhysical
                              ? AppColors.primaryLight.withValues(alpha: 0.55)
                              : AppColors.accentBlue.withValues(alpha: 0.10),
                        ),
                        _StatusBadge(
                          text: _stateLabel(device),
                          color: AppColors.lightText,
                          backgroundColor: Colors.black.withValues(alpha: 0.05),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                children: [
                  if (device.type == DeviceType.doorLock)
                    Switch.adaptive(
                      value: device.doorLockState == DoorLockState.locked,
                      onChanged: (value) {
                        provider.setDoorLockState(
                          value ? DoorLockState.locked : DoorLockState.unlocked,
                        );
                      },
                    )
                  else
                    Switch.adaptive(
                      value: device.isOn,
                      onChanged: (value) {
                        provider.setPower(device.id, value);
                      },
                    ),
                  const SizedBox(height: 20),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.lightTextSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _deviceAccent(DeviceType type) {
    switch (type) {
      case DeviceType.whiteLight:
        return AppColors.accentYellow;
      case DeviceType.rgbLight:
        return AppColors.accentPurple;
      case DeviceType.curtain:
        return AppColors.primaryDark;
      case DeviceType.buzzer:
        return AppColors.danger;
      case DeviceType.fan:
        return AppColors.accentBlue;
      case DeviceType.doorLock:
        return AppColors.primary;
    }
  }

  static IconData _deviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.whiteLight:
        return Icons.lightbulb_rounded;
      case DeviceType.rgbLight:
        return Icons.palette_rounded;
      case DeviceType.curtain:
        return Icons.curtains_rounded;
      case DeviceType.buzzer:
        return Icons.notifications_active_rounded;
      case DeviceType.fan:
        return Icons.air_rounded;
      case DeviceType.doorLock:
        return Icons.lock_rounded;
    }
  }

  static String _deviceSubtitle(SmartDevice device) {
    switch (device.type) {
      case DeviceType.whiteLight:
        return 'Brightness-managed room lighting';
      case DeviceType.rgbLight:
        return 'Colour ambience and decorative mood';
      case DeviceType.curtain:
        return 'Open or close with smooth control';
      case DeviceType.buzzer:
        return 'Emergency warning and alert output';
      case DeviceType.fan:
        return 'Digital twin for future climate control';
      case DeviceType.doorLock:
        return 'Digital twin for room access security';
    }
  }

  static String _stateLabel(SmartDevice device) {
    switch (device.type) {
      case DeviceType.curtain:
        return device.curtainPosition == CurtainPosition.open
            ? 'Open'
            : 'Closed';
      case DeviceType.doorLock:
        return device.doorLockState == DoorLockState.locked
            ? 'Locked'
            : 'Unlocked';
      default:
        return device.isOn ? 'Active' : 'Inactive';
    }
  }
}

class _MiniIllustration extends StatelessWidget {
  const _MiniIllustration({required this.icon, required this.accentColor});

  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 128,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.95),
            accentColor.withValues(alpha: 0.55),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -18,
            right: -12,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -14,
            left: -10,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.45,
        ),
      ),
    );
  }
}
