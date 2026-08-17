import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/automation_rule.dart';
import '../services/notification_service.dart';
import '../services/firebase_system_status_repository.dart';
import '../services/system_status_repository.dart';
import 'alert_provider.dart';
import 'sensor_provider.dart';
import 'settings_provider.dart';

class NotificationCoordinator extends ChangeNotifier {
  NotificationCoordinator({
    NotificationService? service,
    SystemStatusRepository? systemStatusRepository,
  }) : _service = service ?? NotificationService.instance,
       _systemStatusRepository =
           systemStatusRepository ?? FirebaseSystemStatusRepository() {
    _systemSubscription = _systemStatusRepository.watchOnline().listen(
      _handleOnlineStatus,
    );
  }

  final NotificationService _service;
  final SystemStatusRepository _systemStatusRepository;
  StreamSubscription<bool?>? _systemSubscription;
  final Set<String> _seenAlertIds = {};

  AlertProvider? _alerts;
  SensorProvider? _sensors;
  SettingsProvider? _settings;
  bool _alertsInitialized = false;
  String? _lastSensorError;
  bool? _wasOnline;

  void updateDependencies({
    required AlertProvider alerts,
    required SensorProvider sensors,
    required SettingsProvider settings,
  }) {
    if (!identical(_alerts, alerts)) {
      _alerts?.removeListener(_handleAlerts);
      _alerts = alerts;
      _alerts?.addListener(_handleAlerts);
      _alertsInitialized = false;
      _handleAlerts();
    }

    if (!identical(_sensors, sensors)) {
      _sensors?.removeListener(_handleSensorStatus);
      _sensors = sensors;
      _sensors?.addListener(_handleSensorStatus);
      _lastSensorError = sensors.error;
    }

    _settings = settings;
  }

  void _handleAlerts() {
    final provider = _alerts;
    if (provider == null || !provider.hasLoaded) {
      return;
    }
    final alerts = provider.alerts;

    if (!_alertsInitialized) {
      _seenAlertIds.addAll(alerts.map((alert) => alert.id));
      _alertsInitialized = true;
      return;
    }

    for (final alert in alerts.reversed) {
      if (!_seenAlertIds.add(alert.id) || !_shouldNotify(alert)) {
        continue;
      }
      unawaited(_service.showAlert(alert));
    }
  }

  bool _shouldNotify(AutomationEvent alert) {
    final settings = _settings;
    if (settings == null || !settings.notificationsEnabled) {
      return false;
    }

    if (alert.severity == AutomationSeverity.critical) {
      return settings.criticalAlertsEnabled;
    }

    return settings.automationAlertsEnabled;
  }

  void _handleSensorStatus() {
    final error = _sensors?.error;
    final becameOffline = error != null && _lastSensorError == null;
    _lastSensorError = error;

    final settings = _settings;
    if (becameOffline &&
        settings != null &&
        settings.notificationsEnabled &&
        settings.systemAlertsEnabled) {
      unawaited(_service.showSystemOffline());
    }
  }

  void _handleOnlineStatus(bool? online) {
    if (online == null) return;
    final becameOffline = online == false && _wasOnline == true;
    _wasOnline = online;

    final settings = _settings;
    if (becameOffline &&
        settings != null &&
        settings.notificationsEnabled &&
        settings.systemAlertsEnabled) {
      unawaited(_service.showSystemOffline());
    }
  }

  @override
  void dispose() {
    _alerts?.removeListener(_handleAlerts);
    _sensors?.removeListener(_handleSensorStatus);
    _systemSubscription?.cancel();
    _systemStatusRepository.dispose();
    super.dispose();
  }
}
