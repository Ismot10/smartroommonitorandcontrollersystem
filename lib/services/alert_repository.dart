import '../models/automation_rule.dart';

abstract interface class AlertRepository {
  Stream<List<AutomationEvent>> watchAlerts();

  Future<AutomationEvent> addAlert(AutomationEvent event);

  Future<void> saveAlert(AutomationEvent event);

  Future<void> setRead(String id, bool isRead);

  Future<void> deleteAlert(String id);

  Future<void> clearAlerts();

  Future<void> dispose();
}
