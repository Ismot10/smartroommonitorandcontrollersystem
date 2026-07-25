import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/sensor_data.dart';
import '../services/sensor_repository.dart';

class SensorProvider extends ChangeNotifier {
  SensorProvider({
    required SensorRepository repository,
  }) : _repository = repository;

  final SensorRepository _repository;

  StreamSubscription<SensorData>? _subscription;

  SensorData _data = SensorData.initial();
  bool _isLoading = true;
  String? _error;

  SensorData get data => _data;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasEmergency =>
      _data.gas >= 450;

  bool get hasWarning =>
      _data.temperature >= 30 ||
          _data.lightLevel <= 100;

  String get roomStatus {
    if (hasEmergency) {
      return 'Emergency';
    }

    if (hasWarning) {
      return 'Attention needed';
    }

    return 'All systems normal';
  }

  Future<void> start() async {
    await _subscription?.cancel();

    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription = _repository.watchSensors().listen(
          (sensorData) {
        _data = sensorData;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}