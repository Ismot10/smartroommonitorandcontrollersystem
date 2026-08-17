import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/automation_rule.dart';
import '../models/device_schedule.dart';
import '../services/schedule_repository.dart';
import 'alert_provider.dart';
import 'device_provider.dart';

class ScheduleProvider extends ChangeNotifier with WidgetsBindingObserver {
  ScheduleProvider({required ScheduleRepository repository})
    : _repository = repository;

  final ScheduleRepository _repository;
  final List<DeviceSchedule> _schedules = [];
  StreamSubscription<List<DeviceSchedule>>? _subscription;
  Timer? _timer;
  DeviceProvider? _devices;
  AlertProvider? _alerts;
  bool _checking = false;
  bool _observingLifecycle = false;
  bool _isLoading = true;
  String? _error;

  List<DeviceSchedule> get schedules => List.unmodifiable(_schedules);
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<DeviceSchedule> forDevice(String deviceId) =>
      _schedules.where((schedule) => schedule.deviceId == deviceId).toList();

  DeviceSchedule? get upcoming {
    final enabled = _schedules.where((schedule) => schedule.enabled).toList();
    enabled.sort((a, b) {
      final first = a.nextOccurrence();
      final second = b.nextOccurrence();
      if (first == null) return 1;
      if (second == null) return -1;
      return first.compareTo(second);
    });
    return enabled.isEmpty ? null : enabled.first;
  }

  void updateDependencies(DeviceProvider devices, AlertProvider alerts) {
    _devices = devices;
    _alerts = alerts;
  }

  Future<void> start() async {
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    await _subscription?.cancel();
    _subscription = _repository.watchSchedules().listen(
      (incoming) {
        _isLoading = false;
        _error = null;
        _schedules
          ..clear()
          ..addAll(incoming);
        notifyListeners();
        unawaited(_checkDueSchedules());
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => unawaited(_checkDueSchedules()),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkDueSchedules());
    }
  }

  Future<void> create({
    required String name,
    required String deviceId,
    required String deviceName,
    required bool turnOn,
    required int hour,
    required int minute,
    required List<int> weekdays,
    int? level,
  }) async {
    final now = DateTime.now();
    await _repository.create(
      DeviceSchedule(
        id: '',
        name: name.trim(),
        deviceId: deviceId,
        deviceName: deviceName,
        turnOn: turnOn,
        hour: hour,
        minute: minute,
        weekdays: List.of(weekdays)..sort(),
        level: level,
        enabled: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> update(DeviceSchedule schedule) =>
      _repository.save(schedule.copyWith(updatedAt: DateTime.now()));

  Future<void> setEnabled(DeviceSchedule schedule, bool enabled) =>
      update(schedule.copyWith(enabled: enabled));

  Future<void> delete(String id) => _repository.delete(id);

  Future<void> _checkDueSchedules() async {
    if (_checking || _devices == null) return;
    _checking = true;
    try {
      final now = DateTime.now();
      for (final schedule in List<DeviceSchedule>.of(_schedules)) {
        if (!schedule.enabled || !_isDue(schedule, now)) {
          continue;
        }

        final last = schedule.lastExecutedAt;
        if (last != null &&
            last.year == now.year &&
            last.month == now.month &&
            last.day == now.day &&
            last.hour == now.hour &&
            last.minute == now.minute) {
          continue;
        }

        final executed = await _execute(schedule);
        if (!executed) continue;
        final completed = schedule.copyWith(
          enabled: schedule.repeats,
          lastExecutedAt: now,
          updatedAt: now,
        );
        await _repository.save(completed);
        await _alerts?.add(
          AutomationEvent(
            id: now.microsecondsSinceEpoch.toString(),
            ruleId: 'schedule',
            title: 'Scheduled action completed',
            message:
                '${schedule.name}: ${schedule.actionLabel} '
                '${schedule.deviceName}.',
            createdAt: now,
            severity: AutomationSeverity.info,
            isTest: false,
          ),
        );
      }
    } finally {
      _checking = false;
    }
  }

  bool _isDue(DeviceSchedule schedule, DateTime now) {
    if (schedule.weekdays.isNotEmpty &&
        !schedule.weekdays.contains(now.weekday)) {
      return false;
    }

    final dueAt = DateTime(
      now.year,
      now.month,
      now.day,
      schedule.hour,
      schedule.minute,
    );
    final lateness = now.difference(dueAt);
    return !lateness.isNegative && lateness <= const Duration(minutes: 2);
  }

  Future<bool> _execute(DeviceSchedule schedule) async {
    final devices = _devices!;
    final device = devices.byId(schedule.deviceId);
    if (device == null) return false;

    return devices.applyScheduledState(
      deviceId: schedule.deviceId,
      turnOn: schedule.turnOn,
      level: schedule.level,
    );
  }

  @override
  void dispose() {
    if (_observingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _timer?.cancel();
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
