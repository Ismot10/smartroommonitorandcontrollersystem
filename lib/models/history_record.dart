import 'sensor_data.dart';

class HistoryRecord {
  const HistoryRecord({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.lightLevel,
    required this.motionDetected,
    required this.raining,
    required this.createdAt,
  });

  final String id;
  final double temperature;
  final double humidity;
  final double gas;
  final double lightLevel;
  final bool motionDetected;
  final bool raining;
  final DateTime createdAt;

  factory HistoryRecord.fromSensorData(
      SensorData data,
      ) {
    return HistoryRecord(
      id: data.updatedAt.microsecondsSinceEpoch.toString(),
      temperature: data.temperature,
      humidity: data.humidity,
      gas: data.gas,
      lightLevel: data.lightLevel,
      motionDetected: data.motionDetected,
      raining: data.raining,
      createdAt: data.updatedAt,
    );
  }

  factory HistoryRecord.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    return HistoryRecord(
      id: id,
      temperature: _toDouble(map['temperature']),
      humidity: _toDouble(map['humidity']),
      gas: _toDouble(map['gas']),
      lightLevel: _toDouble(map['lightLevel']),
      motionDetected: map['motionDetected'] == true,
      raining: map['raining'] == true,
      createdAt: _toDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'gas': gas,
      'lightLevel': lightLevel,
      'motionDetected': motionDetected,
      'raining': raining,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value?.toString() ?? '',
    ) ??
        0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return DateTime.now();
  }
}