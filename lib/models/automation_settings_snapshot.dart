import 'automation_rule.dart';

class AutomationSettingsSnapshot {
  const AutomationSettingsSnapshot({
    required this.masterEnabled,
    required this.rules,
    required this.updatedAt,
  });

  final bool masterEnabled;
  final List<AutomationRule> rules;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() {
    return {
      'masterEnabled': masterEnabled,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'rules': {for (final rule in rules) rule.id: rule.toPersistenceMap()},
    };
  }

  factory AutomationSettingsSnapshot.fromMap(
    Map<dynamic, dynamic> map,
    List<AutomationRule> defaults,
  ) {
    final rawRules = map['rules'];
    final persistedRules = rawRules is Map ? rawRules : const {};

    return AutomationSettingsSnapshot(
      masterEnabled: map['masterEnabled'] != false,
      updatedAt: _toDateTime(map['updatedAt']),
      rules: defaults.map((defaultRule) {
        final value = persistedRules[defaultRule.id];
        if (value is! Map) {
          return defaultRule;
        }

        return defaultRule.copyWith(
          enabled: value['enabled'] != false,
          triggerValue:
              _toNullableDouble(value['triggerValue']) ??
              defaultRule.triggerValue,
          resetValue:
              _toNullableDouble(value['resetValue']) ?? defaultRule.resetValue,
        );
      }).toList(),
    );
  }

  static double? _toNullableDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    return DateTime.now();
  }
}
