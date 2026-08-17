import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/automation_rule.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    _initialized = true;
  }

  Future<void> showAlert(AutomationEvent event) async {
    await initialize();
    final isCritical = event.displaySeverity == AutomationSeverity.critical;
    final isWarning = event.displaySeverity == AutomationSeverity.warning;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        isCritical ? 'aurora_critical' : 'aurora_activity',
        isCritical ? 'Critical safety alerts' : 'Smart room activity',
        channelDescription: isCritical
            ? 'Urgent gas and safety notifications'
            : 'Automation, motion, rain, and schedule notifications',
        importance: isCritical ? Importance.max : Importance.high,
        priority: isCritical ? Priority.max : Priority.high,
        category: isCritical
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.status,
        enableVibration: true,
        playSound: true,
        color: isCritical
            ? const Color(0xFFE84D4D)
            : isWarning
            ? const Color(0xFFFFB547)
            : const Color(0xFF167A55),
        styleInformation: BigTextStyleInformation(
          event.message,
          contentTitle: event.displayTitle,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _plugin.show(
      id: event.id.hashCode & 0x7fffffff,
      title: event.displayTitle,
      body: event.message,
      notificationDetails: details,
      payload: 'alert:${event.id}',
    );
  }

  Future<void> showSystemOffline() async {
    await initialize();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'aurora_system',
        'System status',
        channelDescription: 'ESP32 and Aurora connectivity notifications',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.error,
        color: Color(0xFFE84D4D),
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 900001,
      title: 'ESP32 gateway offline',
      body: 'Aurora stopped receiving live smart-room sensor data.',
      notificationDetails: details,
      payload: 'system:offline',
    );
  }
}
