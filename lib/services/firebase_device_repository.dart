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
    return _reference.child(device.id).update(device.toMap());
  }

  @override
  Future<void> seedDevicesIfEmpty(List<SmartDevice> devices) async {
    final snapshot = await _reference.get();
    final value = snapshot.value;
    final existingDevices = value is Map ? value : const <Object?, Object?>{};
    final updates = <String, Object?>{};

    for (final device in devices) {
      final rawDevice = existingDevices[device.id];

      if (rawDevice is! Map) {
        updates[device.id] = device.toMap();
        continue;
      }

      // Repair identity metadata only. Operational fields are deliberately
      // excluded because Flutter and the ESP32 may update them concurrently.
      if (rawDevice['id']?.toString() != device.id) {
        updates['${device.id}/id'] = device.id;
      }

      final storedName = rawDevice['name']?.toString();
      if (storedName == null ||
          storedName.trim().isEmpty ||
          storedName == device.id) {
        updates['${device.id}/name'] = device.name;
      }

      if (rawDevice['type']?.toString() != device.type.name) {
        updates['${device.id}/type'] = device.type.name;
      }

      if (rawDevice['connectionType']?.toString() !=
          device.connectionType.name) {
        updates['${device.id}/connectionType'] = device.connectionType.name;
      }
    }

    if (updates.isNotEmpty) {
      await _reference.update(updates);
    }
  }

  @override
  Future<void> dispose() async {}
}
