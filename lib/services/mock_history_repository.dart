import 'dart:async';
import 'dart:math';

import '../models/history_record.dart';
import 'history_repository.dart';

class MockHistoryRepository
    implements HistoryRepository {
  MockHistoryRepository()
      : _records = _createDemoHistory();

  final List<HistoryRecord> _records;

  final StreamController<List<HistoryRecord>>
  _controller =
  StreamController<List<HistoryRecord>>.broadcast();

  @override
  Future<List<HistoryRecord>> getRecords() async {
    return List.unmodifiable(_records);
  }

  @override
  Stream<List<HistoryRecord>> watchRecords() {
    return _controller.stream;
  }

  @override
  Future<void> addRecord(
      HistoryRecord record,
      ) async {
    final alreadyExists = _records.any(
          (existing) =>
      existing.id == record.id ||
          existing.createdAt ==
              record.createdAt,
    );

    if (alreadyExists) {
      return;
    }

    _records.add(record);

    _records.sort(
          (first, second) => first.createdAt.compareTo(
        second.createdAt,
      ),
    );

    // Keep a practical maximum for local demo mode.
    if (_records.length > 1000) {
      _records.removeRange(
        0,
        _records.length - 1000,
      );
    }

    _emit();
  }

  @override
  Future<void> clearRecords() async {
    _records.clear();
    _emit();
  }

  void _emit() {
    if (_controller.isClosed) {
      return;
    }

    _controller.add(
      List.unmodifiable(_records),
    );
  }

  @override
  Future<void> dispose() async {
    await _controller.close();
  }

  static List<HistoryRecord>
  _createDemoHistory() {
    final random = Random(2101027);
    final records = <HistoryRecord>[];

    final now = DateTime.now();

    // One record every 30 minutes for seven days.
    const totalRecords = 7 * 48;

    for (var index = totalRecords - 1;
    index >= 0;
    index--) {
      final timestamp = now.subtract(
        Duration(minutes: index * 30),
      );

      final hour =
          timestamp.hour + timestamp.minute / 60;

      final dailyWave =
      sin((hour / 24) * pi * 2);

      final weeklyWave = sin(
        (index / totalRecords) * pi * 4,
      );

      final temperature =
          27.0 +
              dailyWave * 2.4 +
              weeklyWave * 0.7 +
              random.nextDouble() * 0.8;

      final humidity =
          59.0 -
              dailyWave * 7.0 +
              random.nextDouble() * 3.5;

      final gas =
          185.0 +
              random.nextDouble() * 55 +
              (index % 93 == 0 ? 110 : 0);

      final daylight = max(
        20.0,
        sin(
          ((hour - 6) / 12) * pi,
        ) *
            620,
      );

      final lightLevel =
          daylight + random.nextDouble() * 35;

      records.add(
        HistoryRecord(
          id: timestamp
              .microsecondsSinceEpoch
              .toString(),
          temperature: temperature,
          humidity: humidity,
          gas: gas,
          lightLevel: lightLevel,
          motionDetected:
          random.nextDouble() > 0.76,
          raining:
          random.nextDouble() > 0.93,
          createdAt: timestamp,
        ),
      );
    }

    return records;
  }
}