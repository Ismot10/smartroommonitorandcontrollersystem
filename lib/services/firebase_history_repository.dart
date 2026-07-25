import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/history_record.dart';
import 'history_repository.dart';

class FirebaseHistoryRepository implements HistoryRepository {
  FirebaseHistoryRepository({FirebaseDatabase? database})
    : _reference = (database ?? FirebaseDatabase.instance).ref(
        FirebasePaths.history,
      );

  final DatabaseReference _reference;

  @override
  Future<List<HistoryRecord>> getRecords() async {
    final snapshot = await _reference.limitToLast(1000).get();
    return _recordsFromValue(snapshot.value);
  }

  @override
  Stream<List<HistoryRecord>> watchRecords() {
    return _reference
        .limitToLast(1000)
        .onValue
        .map((event) => _recordsFromValue(event.snapshot.value));
  }

  @override
  Future<void> addRecord(HistoryRecord record) {
    return _reference.child(record.id).set(record.toMap());
  }

  @override
  Future<void> clearRecords() {
    return _reference.remove();
  }

  List<HistoryRecord> _recordsFromValue(Object? value) {
    if (value is! Map) {
      return <HistoryRecord>[];
    }

    final records =
        value.entries
            .where((entry) => entry.value is Map)
            .map(
              (entry) => HistoryRecord.fromMap(
                entry.key.toString(),
                entry.value as Map,
              ),
            )
            .toList()
          ..sort(
            (first, second) => first.createdAt.compareTo(second.createdAt),
          );

    return records;
  }

  @override
  Future<void> dispose() async {}
}
