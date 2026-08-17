import '../models/device_schedule.dart';

abstract interface class ScheduleRepository {
  Stream<List<DeviceSchedule>> watchSchedules();
  Future<DeviceSchedule> create(DeviceSchedule schedule);
  Future<void> save(DeviceSchedule schedule);
  Future<void> delete(String id);
  Future<void> dispose();
}
