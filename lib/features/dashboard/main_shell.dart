import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/connection_provider.dart';
import '../alerts/alerts_screen.dart';
import '../automation/automation_screen.dart';
import '../devices/devices_screen.dart';
import '../settings/profile_screen.dart';
import 'dashboard_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final connection = context.watch<ConnectionProvider>();
    final screens = <Widget>[
      DashboardScreen(
        onDevicesTap: () {
          setState(() => _selectedIndex = 1);
        },
        onAlertsTap: () {
          setState(() => _selectedIndex = 3);
        },
        onProfileTap: () {
          setState(() => _selectedIndex = 4);
        },
      ),
      const DevicesScreen(),
      const AutomationScreen(),
      const AlertsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          _ConnectionBanner(connection: connection),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.devices_other_outlined),
                selectedIcon: Icon(Icons.devices_other_rounded),
                label: 'Devices',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome_rounded),
                label: 'Automation',
              ),
              NavigationDestination(
                icon: Icon(Icons.notifications_none_rounded),
                selectedIcon: Icon(Icons.notifications_rounded),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({required this.connection});

  final ConnectionProvider connection;

  @override
  Widget build(BuildContext context) {
    final status = connection.status;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: switch (status) {
        CloudConnectionStatus.online => const SizedBox.shrink(
          key: ValueKey('online'),
        ),
        CloudConnectionStatus.connecting => const _ConnectionMessage(
          key: ValueKey('connecting'),
          icon: Icons.cloud_sync_rounded,
          title: 'Connecting to Aurora Cloud…',
          backgroundColor: AppColors.warning,
        ),
        CloudConnectionStatus.offline => _ConnectionMessage(
          key: const ValueKey('offline'),
          icon: Icons.cloud_off_rounded,
          title: 'You’re offline — changes will sync automatically.',
          subtitle: _lastOnlineText(connection.lastConnectedAt),
          backgroundColor: AppColors.danger,
        ),
        CloudConnectionStatus.reconnected => const _ConnectionMessage(
          key: ValueKey('reconnected'),
          icon: Icons.cloud_done_rounded,
          title: 'Back online — syncing latest changes.',
          backgroundColor: AppColors.safe,
        ),
      },
    );
  }

  static String? _lastOnlineText(DateTime? value) {
    if (value == null) {
      return 'Waiting for an internet connection';
    }

    return 'Last online ${DateFormat.jm().format(value)}';
  }
}

class _ConnectionMessage extends StatelessWidget {
  const _ConnectionMessage({
    required this.icon,
    required this.title,
    required this.backgroundColor,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 9, 18, 10),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 21),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (statusNeedsProgress(title))
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool statusNeedsProgress(String message) {
    return message.startsWith('Connecting') ||
        message.startsWith('Back online');
  }
}
