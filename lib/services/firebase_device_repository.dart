import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/smart_device.dart';
import 'device_repository.dart';

class FirebaseDeviceRepository implements DeviceRepository {
  FirebaseDeviceRepository({FirebaseDatabase? database})
    : _reference = (database ?? FirebaseDatabase.instance).ref(
        FirebasePaths.devices,
      );

  final DatabaseReference _reference;

  @override
  Stream<List<SmartDevice>> watchDevices() {
    return _reference.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return <SmartDevice>[];
      }

      final devices = <SmartDevice>[];
      for (final entry in value.entries) {
        if (entry.value is Map) {
          devices.add(
            SmartDevice.fromMap(entry.key.toString(), entry.value as Map),
          );
        }
      }
      return devices;
    });
  }

  @override
  Future<List<SmartDevice>> getDevices() async {
    final snapshot = await _reference.get();
    final value = snapshot.value;
    if (value is! Map) {
      return <SmartDevice>[];
    }

    return value.entries
        .where((entry) => entry.value is Map)
        .map(
          (entry) =>
              SmartDevice.fromMap(entry.key.toString(), entry.value as Map),
        )
        .toList();
  }

  @override
  Future<void> saveDevice(SmartDevice device) {
    return _reference.child(device.id).set(device.toMap());
  }

  @override
  Future<void> seedDevicesIfEmpty(List<SmartDevice> devices) async {
    final snapshot = await _reference.get();
    if (snapshot.exists) {
      return;
    }

    await _reference.set({
      for (final device in devices) device.id: device.toMap(),
    });
  }

  @override
  Future<void> dispose() async {}
}
