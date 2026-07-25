import '../models/automation_settings_snapshot.dart';

abstract interface class AutomationRepository {
  Stream<AutomationSettingsSnapshot?> watchSettings();

  Future<void> saveSettings(AutomationSettingsSnapshot settings);

  Future<void> dispose();
}
