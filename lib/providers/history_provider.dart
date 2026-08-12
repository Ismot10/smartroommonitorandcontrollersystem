import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/history_record.dart';
import '../models/sensor_data.dart';
import '../services/history_repository.dart';

enum HistoryRange { today, sevenDays, thirtyDays }

enum HistoryMetric { temperature, humidity, gas, light }

class HistoryProvider extends ChangeNotifier {
  HistoryProvider({required HistoryRepository repository})
    : _repository = repository;

  final HistoryRepository _repository;

  StreamSubscription<List<HistoryRecord>>? _subscription;

  final List<HistoryRecord> _records = [];

  HistoryRange _selectedRange = HistoryRange.today;

  HistoryMetric _selectedMetric = HistoryMetric.temperature;

  bool _isLoading = true;
  String? _error;
  DateTime? _lastCapturedAt;
  bool _captureQueued = false;

  List<HistoryRecord> get records => List.unmodifiable(_records);

  HistoryRange get selectedRange => _selectedRange;

  HistoryMetric get selectedMetric => _selectedMetric;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> start() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final initialRecords = await _repository.getRecords();

      _replaceRecords(initialRecords);

      await _subscription?.cancel();

      _subscription = _repository.watchRecords().listen(
        _replaceRecords,
        onError: (Object error) {
          _error = error.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (error) {
      _error = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void captureSensorData(SensorData data) {
    final lastCapturedAt = _lastCapturedAt;
    if (_lastCapturedAt == data.updatedAt ||
        _captureQueued ||
        (lastCapturedAt != null &&
            data.updatedAt.difference(lastCapturedAt) <
                const Duration(minutes: 5))) {
      return;
    }

    _captureQueued = true;

    scheduleMicrotask(() async {
      _captureQueued = false;

      if (_lastCapturedAt == data.updatedAt) {
        return;
      }

      _lastCapturedAt = data.updatedAt;

      await _repository.addRecord(HistoryRecord.fromSensorData(data));
    });
  }

  void setRange(HistoryRange range) {
    if (_selectedRange == range) {
      return;
    }

    _selectedRange = range;
    notifyListeners();
  }

  void setMetric(HistoryMetric metric) {
    if (_selectedMetric == metric) {
      return;
    }

    _selectedMetric = metric;
    notifyListeners();
  }

  List<HistoryRecord> get filteredRecords {
    final startTime = rangeStart;

    return _records
        .where((record) => record.createdAt.isAfter(startTime))
        .toList();
  }

  DateTime get rangeStart {
    final now = DateTime.now();
    return switch (_selectedRange) {
      HistoryRange.today => DateTime(now.year, now.month, now.day),
      HistoryRange.sevenDays => now.subtract(const Duration(days: 7)),
      HistoryRange.thirtyDays => now.subtract(const Duration(days: 30)),
    };
  }

  double valueForRecord(HistoryRecord record) {
    return switch (_selectedMetric) {
      HistoryMetric.temperature => record.temperature,
      HistoryMetric.humidity => record.humidity,
      HistoryMetric.gas => record.gas,
      HistoryMetric.light => record.lightLevel,
    };
  }

  String get metricTitle {
    return switch (_selectedMetric) {
      HistoryMetric.temperature => 'Temperature',
      HistoryMetric.humidity => 'Humidity',
      HistoryMetric.gas => 'Smoke / Gas',
      HistoryMetric.light => 'Light intensity',
    };
  }

  String get metricUnit {
    return switch (_selectedMetric) {
      HistoryMetric.temperature => '°C',
      HistoryMetric.humidity => '%',
      HistoryMetric.gas => 'ppm',
      HistoryMetric.light => 'lux',
    };
  }

  double get averageValue {
    final values = filteredRecords.map(valueForRecord).toList();

    if (values.isEmpty) {
      return 0;
    }

    final total = values.fold<double>(0, (sum, value) => sum + value);

    return total / values.length;
  }

  double get minimumValue {
    final values = filteredRecords.map(valueForRecord).toList();

    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((first, second) => first < second ? first : second);
  }

  double get maximumValue {
    final values = filteredRecords.map(valueForRecord).toList();

    if (values.isEmpty) {
      return 0;
    }

    return values.reduce((first, second) => first > second ? first : second);
  }

  double get trendValue {
    final visible = filteredRecords;

    if (visible.length < 2) {
      return 0;
    }

    return valueForRecord(visible.last) - valueForRecord(visible.first);
  }

  int get motionEventCount {
    return _countRisingEdges(
      filteredRecords,
      (record) => record.motionDetected,
    );
  }

  int get rainEventCount {
    return _countRisingEdges(filteredRecords, (record) => record.raining);
  }

  int get gasAlertCount {
    return _countRisingEdges(filteredRecords, (record) => record.gas >= 450);
  }

  double get averageTemperature {
    return _average(filteredRecords.map((record) => record.temperature));
  }

  double get averageHumidity {
    return _average(filteredRecords.map((record) => record.humidity));
  }

  static int _countRisingEdges(
    List<HistoryRecord> records,
    bool Function(HistoryRecord record) isActive,
  ) {
    var count = 0;
    var wasActive = false;
    for (final record in records) {
      final active = isActive(record);
      if (active && !wasActive) count++;
      wasActive = active;
    }
    return count;
  }

  static double _average(Iterable<double> values) {
    var total = 0.0;
    var count = 0;
    for (final value in values) {
      total += value;
      count++;
    }
    return count == 0 ? 0 : total / count;
  }

  Future<void> clearHistory() async {
    await _repository.clearRecords();
  }

  void _replaceRecords(List<HistoryRecord> incoming) {
    _records
      ..clear()
      ..addAll(incoming)
      ..sort((first, second) => first.createdAt.compareTo(second.createdAt));

    _isLoading = false;
    _error = null;

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
