import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/automation_rule.dart';
import 'alert_repository.dart';

class FirebaseAlertRepository implements AlertRepository {
  FirebaseAlertRepository({FirebaseDatabase? database})
    : _reference = (database ?? FirebaseDatabase.instance).ref(
        FirebasePaths.alerts,
      );

  final DatabaseReference _reference;

  @override
  Stream<List<AutomationEvent>> watchAlerts() {
    return _reference.orderByChild('createdAt').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return const <AutomationEvent>[];
      }

      final alerts = <AutomationEvent>[];
      for (final entry in value.entries) {
        if (entry.value is Map) {
          alerts.add(
            AutomationEvent.fromMap(entry.key.toString(), entry.value as Map),
          );
        }
      }
      alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return alerts;
    });
  }

  @override
  Future<AutomationEvent> addAlert(AutomationEvent event) async {
    final child = _reference.push();
    final persisted = event.copyWith(id: child.key!);
    await child.set(persisted.toMap());
    return persisted;
  }

  @override
  Future<void> saveAlert(AutomationEvent event) {
    return _reference.child(event.id).set(event.toMap());
  }

  @override
  Future<void> setRead(String id, bool isRead) {
    return _reference.child(id).update({'isRead': isRead});
  }

  @override
  Future<void> deleteAlert(String id) {
    return _reference.child(id).remove();
  }

  @override
  Future<void> clearAlerts() {
    return _reference.remove();
  }

  @override
  Future<void> dispose() async {}
}
