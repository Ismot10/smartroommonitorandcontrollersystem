import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/automation_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/sensor_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final settingsProvider = context.watch<SettingsProvider>();

    final themeProvider = context.watch<ThemeProvider>();

    final sensorProvider = context.watch<SensorProvider>();

    final deviceProvider = context.watch<DeviceProvider>();

    final automationProvider = context.watch<AutomationProvider>();

    final devices = deviceProvider.devices;

    final physicalCount = devices.where((device) => device.isPhysical).length;

    final virtualCount = devices.where((device) => !device.isPhysical).length;

    final activeCount = devices.where((device) => device.isOn).length;

    final systemOnline = sensorProvider.error == null;

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
                    _ProfileHeader(
                      onSettingsTap: () {
                        _openQuickSettings(context);
                      },
                    ),

                    const SizedBox(height: 22),

                    _ProfileHero(
                      displayName: settingsProvider.displayName,
                      email: authProvider.userEmail ?? 'demo@aurora.com',
                      roomName: settingsProvider.roomName,
                      onEdit: () {
                        _openProfileEditor(context);
                      },
                    ),

                    const SizedBox(height: 22),

                    _DeviceSummaryCard(
                      activeCount: activeCount,
                      physicalCount: physicalCount,
                      virtualCount: virtualCount,
                    ),

                    const SizedBox(height: 30),

                    const _SectionTitle(
                      title: 'Room & system',
                      subtitle:
                          'Manage your room identity and connection status.',
                    ),

                    const SizedBox(height: 14),

                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: Icons.home_rounded,
                          iconColor: AppColors.primaryDark,
                          title: 'Room name',
                          subtitle: settingsProvider.roomName,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            _openRoomEditor(context);
                          },
                        ),

                        _SettingsDivider(),

                        _SettingsTile(
                          icon: systemOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          iconColor: systemOnline
                              ? AppColors.safe
                              : AppColors.danger,
                          title: 'ESP32 gateway',
                          subtitle: systemOnline
                              ? 'Online • Last update ${DateFormat('h:mm a').format(sensorProvider.data.updatedAt)}'
                              : 'Connection unavailable',
                          trailing: _StatusBadge(
                            text: systemOnline ? 'ONLINE' : 'OFFLINE',
                            color: systemOnline
                                ? AppColors.safe
                                : AppColors.danger,
                          ),
                        ),

                        _SettingsDivider(),

                        _SettingsTile(
                          icon: Icons.cloud_outlined,
                          iconColor: AppColors.accentBlue,
                          title: 'Data source',
                          subtitle: AppConfig.useMockData
                              ? 'Local mock sensor stream'
                              : 'Firebase Realtime Database',
                          trailing: _StatusBadge(
                            text: AppConfig.useMockData ? 'DEMO' : 'LIVE',
                            color: AppConfig.useMockData
                                ? AppColors.warning
                                : AppColors.safe,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const _SectionTitle(
                      title: 'Preferences',
                      subtitle:
                          'Personalise appearance, alerts and interaction.',
                    ),

                    const SizedBox(height: 14),

                    _SettingsGroup(
                      children: [
                        _ToggleSettingsTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: AppColors.accentPurple,
                          title: 'Dark mode',
                          subtitle: 'Use the dark Aurora appearance',
                          value: themeProvider.isDarkMode,
                          onChanged: themeProvider.setDarkMode,
                        ),

                        _SettingsDivider(),

                        _SettingsTile(
                          icon: Icons.notifications_active_rounded,
                          iconColor: AppColors.accentYellow,
                          title: 'Notifications',
                          subtitle: settingsProvider.notificationsEnabled
                              ? 'Critical, automation and system alerts'
                              : 'Notifications are disabled',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _StatusBadge(
                                text: settingsProvider.notificationsEnabled
                                    ? 'ON'
                                    : 'OFF',
                                color: settingsProvider.notificationsEnabled
                                    ? AppColors.safe
                                    : AppColors.offline,
                              ),
                              const SizedBox(width: 5),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () {
                            _openNotificationSettings(context);
                          },
                        ),

                        _SettingsDivider(),

                        _ToggleSettingsTile(
                          icon: Icons.vibration_rounded,
                          iconColor: AppColors.accentBlue,
                          title: 'Haptic feedback',
                          subtitle: 'Vibrate after important control actions',
                          value: settingsProvider.hapticFeedbackEnabled,
                          onChanged: settingsProvider.setHapticFeedbackEnabled,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const _SectionTitle(
                      title: 'Automation settings',
                      subtitle:
                          'Control automatic behaviour and safety thresholds.',
                    ),

                    const SizedBox(height: 14),

                    _SettingsGroup(
                      children: [
                        _ToggleSettingsTile(
                          icon: Icons.auto_awesome_rounded,
                          iconColor: AppColors.primaryDark,
                          title: 'Master automation',
                          subtitle: automationProvider.masterEnabled
                              ? '${automationProvider.enabledRuleCount} rules enabled'
                              : 'All automatic rules are paused',
                          value: automationProvider.masterEnabled,
                          onChanged: automationProvider.toggleMaster,
                        ),

                        _SettingsDivider(),

                        _SettingsTile(
                          icon: Icons.tune_rounded,
                          iconColor: AppColors.temperature,
                          title: 'Sensor thresholds',
                          subtitle: _thresholdSummary(automationProvider),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            _openThresholdSettings(context);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const _SectionTitle(
                      title: 'Account & project',
                      subtitle: 'Account access and application information.',
                    ),

                    const SizedBox(height: 14),

                    _SettingsGroup(
                      children: [
                        _SettingsTile(
                          icon: Icons.account_circle_rounded,
                          iconColor: AppColors.primaryDark,
                          title: 'Account',
                          subtitle: authProvider.userEmail ?? 'demo@aurora.com',
                          trailing: _StatusBadge(
                            text: AppConfig.useFirebaseAuth
                                ? 'FIREBASE'
                                : 'DEMO',
                            color: AppConfig.useFirebaseAuth
                                ? AppColors.safe
                                : AppColors.warning,
                          ),
                        ),

                        _SettingsDivider(),

                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: AppColors.accentPurple,
                          title: 'About Aurora',
                          subtitle: 'Smart Room Monitor & Controller System',
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            _openAboutSheet(context);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: OutlinedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () {
                                _confirmLogout(context);
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: BorderSide(
                            color: AppColors.danger.withValues(alpha: 0.45),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(21),
                          ),
                        ),
                        icon: authProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.logout_rounded),
                        label: const Text(
                          'Sign out',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Center(
                      child: Text(
                        'Aurora Smart Living • Version 1.0.0',
                        style: TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
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

  static String _thresholdSummary(AutomationProvider provider) {
    final temperature = provider.byId('temperatureFan');

    final light = provider.byId('lowLight');

    final gas = provider.byId('gasEmergency');

    final temperatureValue = temperature?.triggerValue ?? 30;

    final lightValue = light?.triggerValue ?? 100;

    final gasValue = gas?.triggerValue ?? 450;

    return '${temperatureValue.toStringAsFixed(0)}°C • '
        '${lightValue.toStringAsFixed(0)} lux • '
        '${gasValue.toStringAsFixed(0)} ppm';
  }

  static Future<void> _openProfileEditor(BuildContext context) async {
    final settings = context.read<SettingsProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return _TextEditorSheet(
          initialValue: settings.displayName,
          icon: Icons.person_rounded,
          title: 'Edit profile',
          subtitle: 'Update the name shown throughout Aurora.',
          fieldLabel: 'Display name',
          fieldIcon: Icons.person_outline,
          saveLabel: 'Save profile',
          onSave: settings.setDisplayName,
        );
      },
    );
  }

  static Future<void> _openRoomEditor(BuildContext context) async {
    final settings = context.read<SettingsProvider>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return _TextEditorSheet(
          initialValue: settings.roomName,
          icon: Icons.home_rounded,
          title: 'Room information',
          subtitle: 'Choose the name shown on your dashboard.',
          fieldLabel: 'Room name',
          fieldIcon: Icons.meeting_room,
          saveLabel: 'Save room',
          onSave: settings.setRoomName,
        );
      },
    );
  }

  static Future<void> _openQuickSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Consumer2<ThemeProvider, SettingsProvider>(
          builder: (context, theme, settings, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHeader(
                      icon: Icons.settings_rounded,
                      title: 'Quick settings',
                      subtitle:
                          'Adjust Aurora’s most-used preferences instantly.',
                    ),
                    const SizedBox(height: 20),
                    _SheetToggle(
                      title: 'Dark mode',
                      subtitle: 'Use the dark Aurora appearance',
                      value: theme.isDarkMode,
                      onChanged: theme.setDarkMode,
                    ),
                    _SheetToggle(
                      title: 'Allow notifications',
                      subtitle: 'Receive safety and smart-room updates',
                      value: settings.notificationsEnabled,
                      onChanged: settings.setNotificationsEnabled,
                    ),
                    _SheetToggle(
                      title: 'Haptic feedback',
                      subtitle: 'Vibrate after important control actions',
                      value: settings.hapticFeedbackEnabled,
                      onChanged: settings.setHapticFeedbackEnabled,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _openNotificationSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHeader(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notification preferences',
                      subtitle: 'Choose which Aurora events should notify you.',
                    ),

                    const SizedBox(height: 20),

                    _SheetToggle(
                      title: 'Allow notifications',
                      subtitle: 'Master notification control',
                      value: settings.notificationsEnabled,
                      onChanged: settings.setNotificationsEnabled,
                    ),

                    _SheetToggle(
                      title: 'Critical emergencies',
                      subtitle: 'Gas and immediate safety events',
                      value: settings.criticalAlertsEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: settings.setCriticalAlertsEnabled,
                    ),

                    _SheetToggle(
                      title: 'Automation activity',
                      subtitle: 'Rules, devices and automatic actions',
                      value: settings.automationAlertsEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: settings.setAutomationAlertsEnabled,
                    ),

                    _SheetToggle(
                      title: 'System status',
                      subtitle: 'ESP32 connectivity and service updates',
                      value: settings.systemAlertsEnabled,
                      enabled: settings.notificationsEnabled,
                      onChanged: settings.setSystemAlertsEnabled,
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _openThresholdSettings(BuildContext context) async {
    final automation = context.read<AutomationProvider>();

    final temperatureRule = automation.byId('temperatureFan');

    final lightRule = automation.byId('lowLight');

    final gasRule = automation.byId('gasEmergency');

    var temperature = temperatureRule?.triggerValue ?? 30;

    var light = lightRule?.triggerValue ?? 100;

    var gas = gasRule?.triggerValue ?? 450;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHeader(
                      icon: Icons.tune_rounded,
                      title: 'Sensor thresholds',
                      subtitle:
                          'Adjust when Aurora should activate automatic responses.',
                    ),

                    const SizedBox(height: 24),

                    _ThresholdSlider(
                      title: 'Fan temperature',
                      description:
                          'Turn on the virtual fan above this temperature.',
                      icon: Icons.thermostat_rounded,
                      color: AppColors.temperature,
                      value: temperature,
                      minimum: 18,
                      maximum: 40,
                      divisions: 22,
                      unit: '°C',
                      onChanged: (value) {
                        setModalState(() {
                          temperature = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    _ThresholdSlider(
                      title: 'Low-light level',
                      description: 'Turn on the room light below this value.',
                      icon: Icons.lightbulb_rounded,
                      color: AppColors.accentYellow,
                      value: light,
                      minimum: 0,
                      maximum: 1000,
                      divisions: 20,
                      unit: 'lux',
                      onChanged: (value) {
                        setModalState(() {
                          light = value;
                        });
                      },
                    ),

                    const SizedBox(height: 18),

                    _ThresholdSlider(
                      title: 'Gas emergency level',
                      description:
                          'Activate emergency actions at this gas level.',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.danger,
                      value: gas,
                      minimum: 100,
                      maximum: 1000,
                      divisions: 18,
                      unit: 'ppm',
                      onChanged: (value) {
                        setModalState(() {
                          gas = value;
                        });
                      },
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: () {
                          automation.updateThreshold(
                            'temperatureFan',
                            temperature,
                          );

                          automation.updateThreshold('lowLight', light);

                          automation.updateThreshold('gasEmergency', gas);

                          Navigator.pop(sheetContext);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Save thresholds',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Future<void> _openAboutSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHeader(
                  icon: Icons.home_rounded,
                  title: 'Aurora Smart Living',
                  subtitle: 'Smart Room Monitor & Controller System',
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Text(
                    'Aurora is an app-focused IoT platform '
                    'for monitoring environmental conditions, '
                    'controlling smart devices, applying '
                    'automation rules and responding to '
                    'safety emergencies.',
                    style: TextStyle(
                      color: AppColors.lightTextSecondary,
                      height: 1.55,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                const _AboutTechnology(
                  icon: Icons.phone_android_rounded,
                  title: 'Flutter application',
                  description: 'Modern mobile interface and device control.',
                ),

                const _AboutTechnology(
                  icon: Icons.memory_rounded,
                  title: 'ESP32 gateway',
                  description:
                      'Sensor monitoring and physical-device communication.',
                ),

                const _AboutTechnology(
                  icon: Icons.cloud_rounded,
                  title: 'Firebase',
                  description:
                      'Authentication, real-time data, alerts and history.',
                ),

                const _AboutTechnology(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Smart automation',
                  description:
                      'Comfort, security and emergency-response rules.',
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will return to the Aurora login screen.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign out'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await context.read<AuthProvider>().signOut();

    if (!context.mounted) {
      return;
    }

    context.go('/login');
  }
}

class _TextEditorSheet extends StatefulWidget {
  const _TextEditorSheet({
    required this.initialValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.fieldLabel,
    required this.fieldIcon,
    required this.saveLabel,
    required this.onSave,
  });

  final String initialValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final String fieldLabel;
  final IconData fieldIcon;
  final String saveLabel;
  final Future<void> Function(String value) onSave;

  @override
  State<_TextEditorSheet> createState() => _TextEditorSheetState();
}

class _TextEditorSheetState extends State<_TextEditorSheet> {
  late final TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _controller.text.trim();

    if (value.isEmpty || _isSaving) {
      return;
    }

    setState(() => _isSaving = true);
    await widget.onSave(value);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          8,
          22,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHeader(
              icon: widget.icon,
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !_isSaving,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: widget.fieldLabel,
                prefixIcon: Icon(widget.fieldIcon),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.saveLabel,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.onSettingsTap});

  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile & Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Personalise Aurora and manage your smart room.',
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onSettingsTap,
            child: const SizedBox(
              width: 50,
              height: 50,
              child: Icon(Icons.settings_rounded, color: AppColors.primaryDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.displayName,
    required this.email,
    required this.roomName,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final String roomName;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(displayName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF176B4A), Color(0xFF42A15A), Color(0xFF8BCD4C)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.23),
            blurRadius: 31,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -45,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onEdit,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 21),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 5,
                      backgroundColor: Color(0xFFC8FF96),
                    ),
                    const SizedBox(width: 7),
                    const Text(
                      'SYSTEM READY',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
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
}

class _DeviceSummaryCard extends StatelessWidget {
  const _DeviceSummaryCard({
    required this.activeCount,
    required this.physicalCount,
    required this.virtualCount,
  });

  final int activeCount;
  final int physicalCount;
  final int virtualCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _DeviceSummaryValue(
              value: '$activeCount',
              label: 'Active',
              color: AppColors.safe,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _DeviceSummaryValue(
              value: '$physicalCount',
              label: 'Physical',
              color: AppColors.primaryDark,
            ),
          ),
          const _VerticalDivider(),
          Expanded(
            child: _DeviceSummaryValue(
              value: '$virtualCount',
              label: 'Virtual',
              color: AppColors.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSummaryValue extends StatelessWidget {
  const _DeviceSummaryValue({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 42,
      color: Colors.black.withValues(alpha: 0.07),
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
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.79),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              _SettingsIcon(icon: icon, color: iconColor),
              const SizedBox(width: 14),
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
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 10), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSettingsTile extends StatelessWidget {
  const _ToggleSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          _SettingsIcon(icon: icon, color: iconColor),
          const SizedBox(width: 14),
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
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.lightTextSecondary,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 76,
      endIndent: 17,
      color: Colors.black.withValues(alpha: 0.06),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.primaryLight.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetToggle extends StatelessWidget {
  const _SheetToggle({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          color: enabled ? null : AppColors.offline,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? AppColors.lightTextSecondary : AppColors.offline,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  const _ThresholdSlider({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.unit,
    required this.onChanged,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final double value;
  final double minimum;
  final double maximum;
  final int divisions;
  final String unit;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.77),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Slider(
            value: value.clamp(minimum, maximum).toDouble(),
            min: minimum,
            max: maximum,
            divisions: divisions,
            activeColor: color,
            label: '${value.toStringAsFixed(0)} $unit',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _AboutTechnology extends StatelessWidget {
  const _AboutTechnology({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(21),
        ),
        child: Row(
          children: [
            Container(
              width: 41,
              height: 41,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.lightTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
