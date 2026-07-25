import '../models/sensor_data.dart';

abstract interface class SensorRepository {
  Stream<SensorData> watchSensors();

  Future<SensorData> getSensors();

  Future<void> dispose();
}