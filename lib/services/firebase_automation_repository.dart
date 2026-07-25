import 'package:firebase_database/firebase_database.dart';

import '../core/constants/firebase_paths.dart';
import '../models/automation_rule.dart';
import '../models/automation_settings_snapshot.dart';
import 'automation_repository.dart';

class FirebaseAutomationRepository implements AutomationRepository {
  FirebaseAutomationRepository({
    FirebaseDatabase? database,
    required List<AutomationRule> defaults,
  }) : _reference = (database ?? FirebaseDatabase.instance).ref(
         FirebasePaths.automation,
       ),
       _defaults = defaults;

  final DatabaseReference _reference;
  final List<AutomationRule> _defaults;

  @override
  Stream<AutomationSettingsSnapshot?> watchSettings() {
    return _reference.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) {
        return null;
      }
      return AutomationSettingsSnapshot.fromMap(value, _defaults);
    });
  }

  @override
  Future<void> saveSettings(AutomationSettingsSnapshot settings) {
    return _reference.set(settings.toMap());
  }

  @override
  Future<void> dispose() async {}
}
