import '../models/smart_device.dart';

abstract interface class DeviceRepository {
  Stream<List<SmartDevice>> watchDevices();

  Future<List<SmartDevice>> getDevices();

  Future<void> saveDevice(SmartDevice device);

  Future<void> seedDevicesIfEmpty(List<SmartDevice> devices);

  Future<void> dispose();
}
