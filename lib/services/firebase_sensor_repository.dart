import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/sensor_data.dart';
import 'sensor_repository.dart';

class FirebaseSensorRepository implements SensorRepository {
  FirebaseSensorRepository({FirebaseDatabase? database})
    : _reference = (database ?? FirebaseDatabase.instance).ref(
        FirebasePaths.sensors,
      );

  final DatabaseReference _reference;

  @override
  Stream<SensorData> watchSensors() {
    return _reference.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return SensorData.fromMap(value);
      }
      return SensorData.initial();
    });
  }

  @override
  Future<SensorData> getSensors() async {
    final snapshot = await _reference.get();
    final value = snapshot.value;

    if (value is Map) {
      return SensorData.fromMap(value);
    }

    final initial = SensorData.initial();
    await _reference.set(initial.toMap());
    return initial;
  }

  @override
  Future<void> dispose() async {}
}
