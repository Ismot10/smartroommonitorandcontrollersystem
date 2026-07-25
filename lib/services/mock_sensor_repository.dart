import 'dart:async';
import 'dart:math';

import '../models/sensor_data.dart';
import 'mock_data_service.dart';
import 'sensor_repository.dart';

class MockSensorRepository implements SensorRepository {
  MockSensorRepository()
      : _currentData = MockDataService().sensors {
    _startSimulation();
  }

  final Random _random = Random();
  final StreamController<SensorData> _controller =
  StreamController<SensorData>.broadcast();

  SensorData _currentData;
  Timer? _timer;

  void _startSimulation() {
    _controller.add(_currentData);

    _timer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        _currentData = _currentData.copyWith(
          temperature: _bounded(
            _currentData.temperature +
                _randomRange(-0.3, 0.3),
            20,
            38,
          ),
          humidity: _bounded(
            _currentData.humidity +
                _randomRange(-0.8, 0.8),
            30,
            90,
          ),
          gas: _bounded(
            _currentData.gas +
                _randomRange(-5, 5),
            100,
            700,
          ),
          lightLevel: _bounded(
            _currentData.lightLevel +
                _randomRange(-15, 15),
            0,
            1000,
          ),
          updatedAt: DateTime.now(),
        );

        _controller.add(_currentData);
      },
    );
  }

  double _randomRange(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  double _bounded(
      double value,
      double minimum,
      double maximum,
      ) {
    return value.clamp(minimum, maximum).toDouble();
  }

  @override
  Stream<SensorData> watchSensors() => _controller.stream;

  @override
  Future<SensorData> getSensors() async => _currentData;

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    await _controller.close();
  }
}