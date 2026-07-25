import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/automation_rule.dart';
import '../models/automation_settings_snapshot.dart';
import '../models/sensor_data.dart';
import '../models/smart_device.dart';
import '../services/automation_repository.dart';
import 'alert_provider.dart';
import 'device_provider.dart';
import 'sensor_provider.dart';

class AutomationProvider extends ChangeNotifier {
  AutomationProvider({AutomationRepository? repository})
    : _repository = repository,
      _rules = List.of(defaultRules);

  static List<AutomationRule> get defaultRules => [
    const AutomationRule(
      id: 'temperatureFan',
      title: 'Climate comfort',
      description: 'Turn on the virtual fan when the room becomes hot.',
      type: AutomationRuleType.temperatureFan,
      enabled: true,
      triggerValue: 30,
      resetValue: 20,
      unit: '°C',
      actions: [
        'Turn on Climate Fan',
        'Set fan speed to 70%',
        'Record automation event',
      ],
    ),
    const AutomationRule(
      id: 'lowLight',
      title: 'Adaptive lighting',
      description: 'Turn on the room light when the room becomes dark.',
      type: AutomationRuleType.lowLight,
      enabled: true,
      triggerValue: 100,
      unit: 'lux',
      actions: ['Turn on Room Light', 'Record lighting event'],
    ),
    const AutomationRule(
      id: 'motionSecurity',
      title: 'Motion security',
      description: 'Respond automatically when movement is detected.',
      type: AutomationRuleType.motionSecurity,
      enabled: true,
      actions: [
        'Turn on Room Light',
        'Lock virtual Door Lock',
        'Create security alert',
      ],
    ),
    const AutomationRule(
      id: 'rainCurtain',
      title: 'Rain protection',
      description: 'Close the curtain automatically during rainfall.',
      type: AutomationRuleType.rainCurtain,
      enabled: true,
      actions: ['Close Smart Curtain', 'Record weather event'],
    ),
    const AutomationRule(
      id: 'gasEmergency',
      title: 'Gas emergency response',
      description: 'Activate immediate safety actions when gas rises.',
      type: AutomationRuleType.gasEmergency,
      enabled: true,
      triggerValue: 450,
      unit: 'ppm',
      actions: [
        'Activate Safety Alarm',
        'Turn on Room Light',
        'Change RGB Light to red',
        'Unlock virtual Door Lock',
        'Create emergency alert',
      ],
    ),
  ];

  final AutomationRepository? _repository;
  final List<AutomationRule> _rules;
  final Set<String> _activeRuleIds = {};
  StreamSubscription<AutomationSettingsSnapshot?>? _settingsSubscription;

  SensorProvider? _sensorProvider;
  DeviceProvider? _deviceProvider;
  AlertProvider? _alertProvider;

  bool _masterEnabled = true;
  bool _evaluationQueued = false;
  DateTime? _lastEvaluatedTimestamp;

  bool get masterEnabled => _masterEnabled;

  List<AutomationRule> get rules => List.unmodifiable(_rules);

  List<AutomationEvent> get events => _alertProvider?.alerts ?? const [];

  int get enabledRuleCount => _rules.where((rule) => rule.enabled).length;

  int get activeRuleCount => _activeRuleIds.length;

  AutomationRule? byId(String id) {
    for (final rule in _rules) {
      if (rule.id == id) {
        return rule;
      }
    }

    return null;
  }

  bool isRuleActive(String id) {
    return _activeRuleIds.contains(id);
  }

  void updateDependencies({
    required SensorProvider sensorProvider,
    required DeviceProvider deviceProvider,
    required AlertProvider alertProvider,
  }) {
    _sensorProvider = sensorProvider;
    _deviceProvider = deviceProvider;

    if (!identical(_alertProvider, alertProvider)) {
      _alertProvider?.removeListener(_handleAlertsChanged);
      _alertProvider = alertProvider;
      _alertProvider?.addListener(_handleAlertsChanged);
    }

    _queueEvaluation();
  }

  void _handleAlertsChanged() {
    notifyListeners();
  }

  Future<void> start() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    await _settingsSubscription?.cancel();
    var receivedInitialValue = false;
    _settingsSubscription = repository.watchSettings().listen((snapshot) {
      if (snapshot == null) {
        if (!receivedInitialValue) {
          receivedInitialValue = true;
          unawaited(_persistSettings());
        }
        return;
      }

      receivedInitialValue = true;
      _masterEnabled = snapshot.masterEnabled;
      _rules
        ..clear()
        ..addAll(snapshot.rules);
      _lastEvaluatedTimestamp = null;
      notifyListeners();
      _queueEvaluation();
    });
  }

  void toggleMaster(bool value) {
    if (_masterEnabled == value) {
      return;
    }

    _masterEnabled = value;

    if (!value) {
      _activeRuleIds.clear();
    }

    _lastEvaluatedTimestamp = null;

    notifyListeners();
    unawaited(_persistSettings());
    _queueEvaluation();
  }

  void toggleRule(String id, bool enabled) {
    final index = _rules.indexWhere((rule) => rule.id == id);

    if (index == -1) {
      return;
    }

    if (_rules[index].enabled == enabled) {
      return;
    }

    _rules[index] = _rules[index].copyWith(enabled: enabled);

    if (!enabled) {
      _activeRuleIds.remove(id);
    }

    _lastEvaluatedTimestamp = null;

    notifyListeners();
    unawaited(_persistSettings());
    _queueEvaluation();
  }

  void updateThreshold(String id, double value) {
    final index = _rules.indexWhere((rule) => rule.id == id);

    if (index == -1) {
      return;
    }

    _rules[index] = _rules[index].copyWith(triggerValue: value);

    _lastEvaluatedTimestamp = null;

    notifyListeners();
    unawaited(_persistSettings());
    _queueEvaluation();
  }

  void clearActivity() {
    final alertProvider = _alertProvider;
    if (alertProvider != null) {
      unawaited(alertProvider.clear());
    }
  }

  void runRuleTest(String id) {
    final rule = byId(id);
    final deviceProvider = _deviceProvider;

    if (rule == null || deviceProvider == null) {
      return;
    }

    _executeActivation(rule: rule, devices: deviceProvider);

    _addEvent(
      rule: rule,
      message: 'Test completed successfully. ${_activationMessage(rule)}',
      severity: _severityForRule(rule.type),
      isTest: true,
    );

    notifyListeners();
  }

  void _queueEvaluation() {
    if (_evaluationQueued) {
      return;
    }

    _evaluationQueued = true;

    scheduleMicrotask(() {
      _evaluationQueued = false;
      _evaluateCurrentSensorData();
    });
  }

  void _evaluateCurrentSensorData() {
    final sensorProvider = _sensorProvider;
    final deviceProvider = _deviceProvider;

    if (sensorProvider == null || deviceProvider == null) {
      return;
    }

    final sensors = sensorProvider.data;

    if (_lastEvaluatedTimestamp == sensors.updatedAt) {
      return;
    }

    _lastEvaluatedTimestamp = sensors.updatedAt;

    if (!_masterEnabled) {
      return;
    }

    var activityChanged = false;

    for (final rule in _rules) {
      if (!rule.enabled) {
        continue;
      }

      final triggered = _isTriggered(rule: rule, sensors: sensors);

      final wasActive = _activeRuleIds.contains(rule.id);

      if (triggered && !wasActive) {
        _activeRuleIds.add(rule.id);

        _executeActivation(rule: rule, devices: deviceProvider);

        _addEvent(
          rule: rule,
          message: _activationMessage(rule),
          severity: _severityForRule(rule.type),
          isTest: false,
        );

        activityChanged = true;
      } else if (!triggered && wasActive) {
        _activeRuleIds.remove(rule.id);

        final resetMessage = _executeReset(
          rule: rule,
          sensors: sensors,
          devices: deviceProvider,
        );

        if (resetMessage != null) {
          _addEvent(
            rule: rule,
            message: resetMessage,
            severity: AutomationSeverity.info,
            isTest: false,
          );
        }

        activityChanged = true;
      }
    }

    if (activityChanged) {
      notifyListeners();
    }
  }

  bool _isTriggered({
    required AutomationRule rule,
    required SensorData sensors,
  }) {
    switch (rule.type) {
      case AutomationRuleType.temperatureFan:
        return sensors.temperature >= (rule.triggerValue ?? 30);

      case AutomationRuleType.lowLight:
        return sensors.lightLevel <= (rule.triggerValue ?? 100);

      case AutomationRuleType.motionSecurity:
        return sensors.motionDetected;

      case AutomationRuleType.rainCurtain:
        return sensors.raining;

      case AutomationRuleType.gasEmergency:
        return sensors.gas >= (rule.triggerValue ?? 450);
    }
  }

  void _executeActivation({
    required AutomationRule rule,
    required DeviceProvider devices,
  }) {
    switch (rule.type) {
      case AutomationRuleType.temperatureFan:
        _setPowerIfNeeded(devices, 'fan', true);

        _setBrightnessIfNeeded(devices, 'fan', 70);
        break;

      case AutomationRuleType.lowLight:
        _setPowerIfNeeded(devices, 'whiteLight', true);
        break;

      case AutomationRuleType.motionSecurity:
        _setPowerIfNeeded(devices, 'whiteLight', true);

        _setDoorIfNeeded(devices, DoorLockState.locked);
        break;

      case AutomationRuleType.rainCurtain:
        _setCurtainIfNeeded(devices, CurtainPosition.closed);
        break;

      case AutomationRuleType.gasEmergency:
        _setPowerIfNeeded(devices, 'buzzer', true);

        _setPowerIfNeeded(devices, 'whiteLight', true);

        _setPowerIfNeeded(devices, 'rgbLight', true);

        _setRgbIfNeeded(devices, 0xFFE84D4D);

        _setDoorIfNeeded(devices, DoorLockState.unlocked);
        break;
    }
  }

  String? _executeReset({
    required AutomationRule rule,
    required SensorData sensors,
    required DeviceProvider devices,
  }) {
    switch (rule.type) {
      case AutomationRuleType.temperatureFan:
        final resetTemperature = rule.resetValue ?? 20;

        if (sensors.temperature <= resetTemperature) {
          _setPowerIfNeeded(devices, 'fan', false);

          return 'Temperature returned below '
              '${resetTemperature.toStringAsFixed(0)}°C. '
              'The climate fan was turned off.';
        }

        return null;

      case AutomationRuleType.lowLight:
        _setPowerIfNeeded(devices, 'whiteLight', false);

        return 'Room brightness recovered. '
            'The automatic room light was turned off.';

      case AutomationRuleType.motionSecurity:
        return 'Motion is no longer detected. '
            'The room remains secured.';

      case AutomationRuleType.rainCurtain:
        return 'Rain is no longer detected. '
            'The curtain remains closed for protection.';

      case AutomationRuleType.gasEmergency:
        _setPowerIfNeeded(devices, 'buzzer', false);

        return 'Gas level returned to the safe range. '
            'The emergency alarm was silenced.';
    }
  }

  String _activationMessage(AutomationRule rule) {
    switch (rule.type) {
      case AutomationRuleType.temperatureFan:
        return 'High temperature detected. '
            'The virtual fan was activated at 70% speed.';

      case AutomationRuleType.lowLight:
        return 'Low room brightness detected. '
            'The white room light was turned on.';

      case AutomationRuleType.motionSecurity:
        return 'Motion detected. The room light was '
            'turned on and the virtual door was locked.';

      case AutomationRuleType.rainCurtain:
        return 'Rain detected. The smart curtain '
            'was closed automatically.';

      case AutomationRuleType.gasEmergency:
        return 'Dangerous gas level detected. Alarm, '
            'emergency lighting and door-unlock actions '
            'were activated.';
    }
  }

  AutomationSeverity _severityForRule(AutomationRuleType type) {
    switch (type) {
      case AutomationRuleType.temperatureFan:
      case AutomationRuleType.lowLight:
      case AutomationRuleType.rainCurtain:
        return AutomationSeverity.info;

      case AutomationRuleType.motionSecurity:
        return AutomationSeverity.warning;

      case AutomationRuleType.gasEmergency:
        return AutomationSeverity.critical;
    }
  }

  void _addEvent({
    required AutomationRule rule,
    required String message,
    required AutomationSeverity severity,
    required bool isTest,
  }) {
    final now = DateTime.now();

    final event = AutomationEvent(
      id: now.microsecondsSinceEpoch.toString(),
      ruleId: rule.id,
      title: rule.title,
      message: message,
      createdAt: now,
      severity: severity,
      isTest: isTest,
    );

    unawaited(_alertProvider?.add(event));
  }

  Future<void> _persistSettings() async {
    await _repository?.saveSettings(
      AutomationSettingsSnapshot(
        masterEnabled: _masterEnabled,
        rules: _rules,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _setPowerIfNeeded(DeviceProvider provider, String id, bool value) {
    final device = provider.byId(id);

    if (device != null && device.isOn != value) {
      provider.setPower(id, value);
    }
  }

  void _setBrightnessIfNeeded(DeviceProvider provider, String id, int value) {
    final device = provider.byId(id);

    if (device != null && device.brightness != value) {
      provider.setBrightness(id, value);
    }
  }

  void _setRgbIfNeeded(DeviceProvider provider, int color) {
    final device = provider.byId('rgbLight');

    if (device != null && device.rgbColor != color) {
      provider.setRgbColor('rgbLight', color);
    }
  }

  void _setCurtainIfNeeded(DeviceProvider provider, CurtainPosition position) {
    final device = provider.byId('curtain');

    if (device != null && device.curtainPosition != position) {
      provider.setCurtainPosition(position);
    }
  }

  void _setDoorIfNeeded(DeviceProvider provider, DoorLockState state) {
    final device = provider.byId('doorLock');

    if (device != null && device.doorLockState != state) {
      provider.setDoorLockState(state);
    }
  }

  @override
  void dispose() {
    _alertProvider?.removeListener(_handleAlertsChanged);
    _settingsSubscription?.cancel();
    _repository?.dispose();
    super.dispose();
  }
}
