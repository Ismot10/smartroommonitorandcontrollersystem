import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/smart_device.dart';
import '../../providers/device_provider.dart';

class DeviceDetailScreen extends StatelessWidget {
  const DeviceDetailScreen({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceProvider>().byId(deviceId);

    if (device == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Device not found')),
      );
    }

    final accentColor = _deviceAccent(device.type);
    final icon = _deviceIcon(device.type);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.lightBackground,
              accentColor.withValues(alpha: 0.08),
              const Color(0xFFF8F2E7),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: device.isPhysical
                            ? AppColors.primaryLight.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        device.connectionLabel,
                        style: TextStyle(
                          color: device.isPhysical
                              ? AppColors.primaryDark
                              : AppColors.lightText,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  device.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _deviceDescription(device.type),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                _DeviceHero(
                  device: device,
                  icon: icon,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 22),
                _ControlSheet(
                  child: _buildControls(context: context, device: device),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls({
    required BuildContext context,
    required SmartDevice device,
  }) {
    final provider = context.read<DeviceProvider>();

    switch (device.type) {
      case DeviceType.whiteLight:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Power',
              subtitle: 'Turn the room light on or off.',
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: device.isOn,
              onChanged: (value) {
                provider.setPower(device.id, value);
              },
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryDark,
              title: const Text(
                'Room light',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(device.isOn ? 'Currently on' : 'Currently off'),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: 'Brightness',
              subtitle: 'Adjust light intensity.',
            ),
            Slider(
              value: device.brightness.toDouble(),
              min: 0,
              max: 100,
              activeColor: AppColors.accentYellow,
              onChanged: (value) {
                provider.setBrightness(device.id, value.round());
              },
            ),
            _ValueCaption('${device.brightness}% brightness'),
          ],
        );

      case DeviceType.rgbLight:
        final presets = <int>[
          0xFF75B83B,
          0xFF7656E8,
          0xFF4A90E2,
          0xFFFFC857,
          0xFFE84D4D,
          0xFF36C8CC,
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Power',
              subtitle: 'Control decorative mood lighting.',
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: device.isOn,
              onChanged: (value) {
                provider.setPower(device.id, value);
              },
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryDark,
              title: const Text(
                'Aurora RGB light',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(device.isOn ? 'Active' : 'Inactive'),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: 'Brightness',
              subtitle: 'Set the lighting intensity.',
            ),
            Slider(
              value: device.brightness.toDouble(),
              min: 0,
              max: 100,
              activeColor: Color(device.rgbColor),
              onChanged: (value) {
                provider.setBrightness(device.id, value.round());
              },
            ),
            _ValueCaption('${device.brightness}% brightness'),
            const SizedBox(height: 18),
            _SectionTitle(
              title: 'Preset colours',
              subtitle: 'Choose an elegant ambience quickly.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presets.map((colorValue) {
                final selected = device.rgbColor == colorValue;
                return GestureDetector(
                  onTap: () {
                    provider.setRgbColor(device.id, colorValue);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Color(colorValue),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? Colors.black : Colors.white,
                        width: selected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(colorValue).withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: selected
                        ? const Icon(Icons.check_rounded, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        );

      case DeviceType.curtain:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Curtain position',
              subtitle: 'Open or close your smart curtain.',
            ),
            const SizedBox(height: 18),
            SegmentedButton<CurtainPosition>(
              style: ButtonStyle(
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(vertical: 18),
                ),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
              segments: const [
                ButtonSegment(
                  value: CurtainPosition.open,
                  label: Text('Open'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment(
                  value: CurtainPosition.closed,
                  label: Text('Closed'),
                  icon: Icon(Icons.nightlight_round),
                ),
              ],
              selected: {device.curtainPosition},
              onSelectionChanged: (selection) {
                provider.setCurtainPosition(selection.first);
              },
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.info_outline_rounded,
              title: 'Automation ready',
              description:
                  'This curtain can later respond automatically to rain or lighting conditions.',
            ),
          ],
        );

      case DeviceType.buzzer:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Alarm control',
              subtitle: 'Use the buzzer for safety alerts.',
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: device.isOn,
              onChanged: (value) {
                provider.setPower(device.id, value);
              },
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.danger,
              title: const Text(
                'Safety alarm',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                device.isOn ? 'Alarm is active' : 'Alarm is silent',
              ),
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.warning_amber_rounded,
              title: 'Emergency usage',
              description:
                  'This buzzer will be triggered automatically later when gas or security events occur.',
            ),
          ],
        );

      case DeviceType.fan:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Fan power',
              subtitle: 'This is currently a digital twin device.',
            ),
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: device.isOn,
              onChanged: (value) {
                provider.setPower(device.id, value);
              },
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primaryDark,
              title: const Text(
                'Climate fan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(device.isOn ? 'Fan is on' : 'Fan is off'),
            ),
            const SizedBox(height: 10),
            _SectionTitle(
              title: 'Speed',
              subtitle:
                  'Simulated speed control for future hardware connection.',
            ),
            Slider(
              value: device.brightness.toDouble(),
              min: 0,
              max: 100,
              activeColor: AppColors.primaryDark,
              onChanged: (value) {
                provider.setBrightness(device.id, value.round());
              },
            ),
            _ValueCaption('${device.brightness}% speed'),
          ],
        );

      case DeviceType.doorLock:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Door access',
              subtitle: 'Control virtual locking behaviour.',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.setDoorLockState(DoorLockState.locked);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          device.doorLockState == DoorLockState.locked
                          ? AppColors.primaryDark
                          : Colors.white,
                      foregroundColor:
                          device.doorLockState == DoorLockState.locked
                          ? Colors.white
                          : AppColors.lightText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.lock_rounded),
                    label: const Text('Lock'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      provider.setDoorLockState(DoorLockState.unlocked);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          device.doorLockState == DoorLockState.unlocked
                          ? AppColors.accentYellow
                          : Colors.white,
                      foregroundColor:
                          device.doorLockState == DoorLockState.unlocked
                          ? Colors.black
                          : AppColors.lightText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    icon: const Icon(Icons.lock_open_rounded),
                    label: const Text('Unlock'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _InfoCard(
              icon: Icons.shield_outlined,
              title: 'Digital twin mode',
              description:
                  'This screen already supports future real door-lock hardware with no UI redesign required.',
            ),
          ],
        );
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

  static String _deviceDescription(DeviceType type) {
    switch (type) {
      case DeviceType.whiteLight:
        return 'Elegant lighting control for your room.';
      case DeviceType.rgbLight:
        return 'Set ambience, colour and brightness beautifully.';
      case DeviceType.curtain:
        return 'Control daylight and privacy with one touch.';
      case DeviceType.buzzer:
        return 'Safety alarm and emergency response device.';
      case DeviceType.fan:
        return 'Virtual climate fan ready for future integration.';
      case DeviceType.doorLock:
        return 'Virtual smart door access and security control.';
    }
  }
}

class _DeviceHero extends StatelessWidget {
  const _DeviceHero({
    required this.device,
    required this.icon,
    required this.accentColor,
  });

  final SmartDevice device;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 310,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.95),
            accentColor.withValues(alpha: 0.60),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.30),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: 22,
            child: Text(
              _heroLabel(device),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, size: 86, color: Colors.white),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    device.isOn
                        ? Icons.check_circle
                        : Icons.pause_circle_outline,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _heroStatus(device),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _heroLabel(SmartDevice device) {
    switch (device.type) {
      case DeviceType.whiteLight:
        return 'SMART LIGHT CONTROL';
      case DeviceType.rgbLight:
        return 'AURORA RGB LIGHTING';
      case DeviceType.curtain:
        return 'AUTOMATED CURTAIN';
      case DeviceType.buzzer:
        return 'SAFETY ALARM';
      case DeviceType.fan:
        return 'CLIMATE FAN';
      case DeviceType.doorLock:
        return 'SMART ACCESS CONTROL';
    }
  }

  static String _heroStatus(SmartDevice device) {
    switch (device.type) {
      case DeviceType.whiteLight:
        return device.isOn
            ? 'White light is active'
            : 'White light is turned off';
      case DeviceType.rgbLight:
        return device.isOn
            ? 'RGB ambience is active'
            : 'RGB ambience is turned off';
      case DeviceType.curtain:
        return device.curtainPosition == CurtainPosition.open
            ? 'Curtain is currently open'
            : 'Curtain is currently closed';
      case DeviceType.buzzer:
        return device.isOn ? 'Alarm is active' : 'Alarm is silent';
      case DeviceType.fan:
        return device.isOn ? 'Fan is running' : 'Fan is idle';
      case DeviceType.doorLock:
        return device.doorLockState == DoorLockState.locked
            ? 'Door is locked'
            : 'Door is unlocked';
    }
  }
}

class _ControlSheet extends StatelessWidget {
  const _ControlSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

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
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.lightTextSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ValueCaption extends StatelessWidget {
  const _ValueCaption(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: const TextStyle(
        color: AppColors.lightTextSecondary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    height: 1.5,
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.78),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: AppColors.lightText),
        ),
      ),
    );
  }
}
