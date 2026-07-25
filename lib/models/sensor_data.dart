class SensorData {
  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.gas,
    required this.motionDetected,
    required this.raining,
    required this.lightLevel,
    required this.updatedAt,
  });

  final double temperature;
  final double humidity;
  final double gas;
  final bool motionDetected;
  final bool raining;
  final double lightLevel;
  final DateTime updatedAt;

  factory SensorData.initial() {
    return SensorData(
      temperature: 27.6,
      humidity: 58.2,
      gas: 212,
      motionDetected: false,
      raining: false,
      lightLevel: 312,
      updatedAt: DateTime.now(),
    );
  }

  factory SensorData.fromMap(Map<dynamic, dynamic> map) {
    return SensorData(
      temperature: _toDouble(map['temperature']),
      humidity: _toDouble(map['humidity']),
      gas: _toDouble(map['gas']),
      motionDetected: map['motion'] == true,
      raining: map['rain'] == true,
      lightLevel: _toDouble(map['lightLevel']),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'gas': gas,
      'motion': motionDetected,
      'rain': raining,
      'lightLevel': lightLevel,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? gas,
    bool? motionDetected,
    bool? raining,
    double? lightLevel,
    DateTime? updatedAt,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      gas: gas ?? this.gas,
      motionDetected: motionDetected ?? this.motionDetected,
      raining: raining ?? this.raining,
      lightLevel: lightLevel ?? this.lightLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now();
  }
}