import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroommonitorandcontrollersystem/models/device_schedule.dart';
import 'package:smartroommonitorandcontrollersystem/models/smart_device.dart';
import 'package:smartroommonitorandcontrollersystem/providers/alert_provider.dart';
import 'package:smartroommonitorandcontrollersystem/providers/device_provider.dart';
import 'package:smartroommonitorandcontrollersystem/providers/schedule_provider.dart';
import 'package:smartroommonitorandcontrollersystem/services/device_repository.dart';
import 'package:smartroommonitorandcontrollersystem/services/schedule_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schedule metadata round-trips with action and level', () {
    final now = DateTime.now();
    final schedule = DeviceSchedule(
      id: 'one',
      name: 'Evening light',
      deviceId: 'whiteLight',
      deviceName: 'Room Light',
      turnOn: true,
      level: 70,
      hour: 19,
      minute: 0,
      weekdays: const [1, 2, 3, 4, 5, 6, 7],
      enabled: true,
      createdAt: now,
      updatedAt: now,
    );

    final restored = DeviceSchedule.fromMap('one', schedule.toMap());
    expect(restored.name, 'Evening light');
    expect(restored.action, 'on');
    expect(restored.actionLabel, 'Turn ON at 70%');
    expect(restored.level, 70);
  });

  test(
    'due schedule writes the existing device repository and completes',
    () async {
      final now = DateTime.now();
      final deviceRepository = _DeviceRepository();
      final devices = DeviceProvider(repository: deviceRepository);
      await devices.start();

      final scheduleRepository = _ScheduleRepository();
      final schedules = ScheduleProvider(repository: scheduleRepository);
      schedules.updateDependencies(devices, AlertProvider());
      await schedules.start();

      scheduleRepository.emit([
        DeviceSchedule(
          id: 'due',
          name: 'Evening light',
          deviceId: 'whiteLight',
          deviceName: 'Room Light',
          turnOn: true,
          level: 70,
          hour: now.hour,
          minute: now.minute,
          weekdays: [now.weekday],
          enabled: true,
          createdAt: now,
          updatedAt: now,
        ),
      ]);

      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(deviceRepository.saved?.isOn, isTrue);
      expect(deviceRepository.saved?.brightness, 70);
      expect(scheduleRepository.saved?.lastExecutedAt, isNotNull);

      schedules.dispose();
      devices.dispose();
    },
  );
}

class _DeviceRepository implements DeviceRepository {
  final controller = StreamController<List<SmartDevice>>();
  SmartDevice? saved;

  @override
  Future<List<SmartDevice>> getDevices() async => const [];

  @override
  Future<void> saveDevice(SmartDevice device) async => saved = device;

  @override
  Future<void> seedDevicesIfEmpty(List<SmartDevice> devices) async {}

  @override
  Stream<List<SmartDevice>> watchDevices() => controller.stream;

  @override
  Future<void> dispose() => controller.close();
}

class _ScheduleRepository implements ScheduleRepository {
  final controller = StreamController<List<DeviceSchedule>>();
  DeviceSchedule? saved;

  void emit(List<DeviceSchedule> value) => controller.add(value);

  @override
  Future<DeviceSchedule> create(DeviceSchedule schedule) async => schedule;

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> save(DeviceSchedule schedule) async => saved = schedule;

  @override
  Stream<List<DeviceSchedule>> watchSchedules() => controller.stream;

  @override
  Future<void> dispose() => controller.close();
}
