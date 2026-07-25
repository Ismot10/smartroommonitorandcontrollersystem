import '../models/history_record.dart';

abstract interface class HistoryRepository {
  Future<List<HistoryRecord>> getRecords();

  Stream<List<HistoryRecord>> watchRecords();

  Future<void> addRecord(
      HistoryRecord record,
      );

  Future<void> clearRecords();

  Future<void> dispose();
}