import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/device_schedule.dart';
import 'schedule_repository.dart';

class FirebaseScheduleRepository implements ScheduleRepository {
  FirebaseScheduleRepository({FirebaseDatabase? database})
    : _reference = (database ?? FirebaseDatabase.instance).ref(
        FirebasePaths.schedules,
      );

  final DatabaseReference _reference;

  @override
  Stream<List<DeviceSchedule>> watchSchedules() {
    return _reference.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const <DeviceSchedule>[];

      final schedules = <DeviceSchedule>[];
      for (final entry in value.entries) {
        if (entry.value is Map) {
          schedules.add(
            DeviceSchedule.fromMap(entry.key.toString(), entry.value as Map),
          );
        }
      }
      schedules.sort((a, b) {
        final first = a.nextOccurrence();
        final second = b.nextOccurrence();
        if (first == null) return 1;
        if (second == null) return -1;
        return first.compareTo(second);
      });
      return schedules;
    });
  }

  @override
  Future<DeviceSchedule> create(DeviceSchedule schedule) async {
    final child = _reference.push();
    final saved = schedule.copyWith(id: child.key!);
    await child.set(saved.toMap());
    return saved;
  }

  @override
  Future<void> save(DeviceSchedule schedule) {
    return _reference.child(schedule.id).set(schedule.toMap());
  }

  @override
  Future<void> delete(String id) => _reference.child(id).remove();

  @override
  Future<void> dispose() async {}
}
