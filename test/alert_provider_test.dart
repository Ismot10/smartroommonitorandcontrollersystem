import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartroommonitorandcontrollersystem/models/automation_rule.dart';
import 'package:smartroommonitorandcontrollersystem/providers/alert_provider.dart';
import 'package:smartroommonitorandcontrollersystem/services/alert_repository.dart';

void main() {
  test('friendly gas metadata explains severity, trigger and actions', () {
    final event = _event('gasEmergency');

    expect(event.displayTitle, 'Gas Emergency Detected');
    expect(event.displaySeverity, AutomationSeverity.critical);
    expect(event.category, 'Safety');
    expect(event.triggerDescription, contains('unsafe'));
    expect(event.automaticActions, hasLength(4));
  });

  test('schedule details derive a successful automatic action', () {
    final event = _event(
      'schedule',
      message: 'Morning Curtain: Open Smart Curtain.',
    );

    expect(event.category, 'Schedule');
    expect(event.automaticActions, ['Open Smart Curtain successfully']);
  });

  test(
    'persistent automation events are deduplicated and read state persists',
    () async {
      final repository = _AlertRepository();
      final provider = AlertProvider(repository: repository);
      await provider.start();

      final first = _event('rainCurtain');
      await provider.add(first);
      await provider.add(
        _event(
          'rainCurtain',
          createdAt: first.createdAt.add(const Duration(minutes: 1)),
        ),
      );

      expect(provider.alerts, hasLength(1));
      await provider.setRead(provider.alerts.single.id, true);
      expect(provider.unreadCount, 0);
      expect(repository.lastReadValue, isTrue);

      provider.dispose();
    },
  );
}

AutomationEvent _event(
  String ruleId, {
  String message = 'Event happened.',
  DateTime? createdAt,
}) {
  return AutomationEvent(
    id: '$ruleId-${createdAt?.microsecondsSinceEpoch ?? 1}',
    ruleId: ruleId,
    title: ruleId,
    message: message,
    createdAt: createdAt ?? DateTime.now(),
    severity: AutomationSeverity.info,
    isTest: false,
  );
}

class _AlertRepository implements AlertRepository {
  final controller = StreamController<List<AutomationEvent>>();
  bool? lastReadValue;

  @override
  Stream<List<AutomationEvent>> watchAlerts() => controller.stream;

  @override
  Future<AutomationEvent> addAlert(AutomationEvent event) async => event;

  @override
  Future<void> saveAlert(AutomationEvent event) async {}

  @override
  Future<void> setRead(String id, bool isRead) async {
    lastReadValue = isRead;
  }

  @override
  Future<void> deleteAlert(String id) async {}

  @override
  Future<void> clearAlerts() async {}

  @override
  Future<void> dispose() => controller.close();
}
