import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroommonitorandcontrollersystem/models/history_record.dart';
import 'package:smartroommonitorandcontrollersystem/providers/history_provider.dart';
import 'package:smartroommonitorandcontrollersystem/services/history_repository.dart';

void main() {
  test('analytics count event transitions instead of active samples', () async {
    final now = DateTime.now();
    final repository = _HistoryRepository([
      _record(now.subtract(const Duration(minutes: 5))),
      _record(
        now.subtract(const Duration(minutes: 4)),
        motion: true,
        rain: true,
        gas: 500,
      ),
      _record(
        now.subtract(const Duration(minutes: 3)),
        motion: true,
        rain: true,
        gas: 520,
      ),
      _record(now.subtract(const Duration(minutes: 2))),
      _record(now.subtract(const Duration(minutes: 1)), motion: true, gas: 480),
    ]);
    final provider = HistoryProvider(repository: repository);

    await provider.start();

    expect(provider.motionEventCount, 2);
    expect(provider.rainEventCount, 1);
    expect(provider.gasAlertCount, 2);
    expect(provider.averageTemperature, 25);
    expect(provider.averageHumidity, 60);

    provider.dispose();
  });
}

HistoryRecord _record(
  DateTime time, {
  bool motion = false,
  bool rain = false,
  double gas = 100,
}) {
  return HistoryRecord(
    id: time.microsecondsSinceEpoch.toString(),
    temperature: 25,
    humidity: 60,
    gas: gas,
    lightLevel: 100,
    motionDetected: motion,
    raining: rain,
    createdAt: time,
  );
}

class _HistoryRepository implements HistoryRepository {
  _HistoryRepository(this.records);

  final List<HistoryRecord> records;
  final StreamController<List<HistoryRecord>> controller =
      StreamController<List<HistoryRecord>>();

  @override
  Future<List<HistoryRecord>> getRecords() async => records;

  @override
  Stream<List<HistoryRecord>> watchRecords() => controller.stream;

  @override
  Future<void> addRecord(HistoryRecord record) async {}

  @override
  Future<void> clearRecords() async {}

  @override
  Future<void> dispose() => controller.close();
}
