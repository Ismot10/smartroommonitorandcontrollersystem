enum AutomationRuleType {
  temperatureFan,
  lowLight,
  motionSecurity,
  rainCurtain,
  gasEmergency,
}

enum AutomationSeverity {
  info,
  warning,
  critical,
}

class AutomationRule {
  const AutomationRule({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.enabled,
    required this.actions,
    this.triggerValue,
    this.resetValue,
    this.unit = '',
  });

  final String id;
  final String title;
  final String description;
  final AutomationRuleType type;
  final bool enabled;

  /// Main threshold that activates the rule.
  final double? triggerValue;

  /// Optional second threshold that resets the rule.
  final double? resetValue;

  final String unit;
  final List<String> actions;

  AutomationRule copyWith({
    String? id,
    String? title,
    String? description,
    AutomationRuleType? type,
    bool? enabled,
    double? triggerValue,
    double? resetValue,
    String? unit,
    List<String>? actions,
  }) {
    return AutomationRule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      triggerValue: triggerValue ?? this.triggerValue,
      resetValue: resetValue ?? this.resetValue,
      unit: unit ?? this.unit,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'enabled': enabled,
      'triggerValue': triggerValue,
      'resetValue': resetValue,
      'unit': unit,
      'actions': actions,
    };
  }

  factory AutomationRule.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    return AutomationRule(
      id: id,
      title: map['title']?.toString() ?? id,
      description: map['description']?.toString() ?? '',
      type: AutomationRuleType.values.firstWhere(
            (type) => type.name == map['type'],
        orElse: () => AutomationRuleType.temperatureFan,
      ),
      enabled: map['enabled'] != false,
      triggerValue: _toNullableDouble(
        map['triggerValue'],
      ),
      resetValue: _toNullableDouble(
        map['resetValue'],
      ),
      unit: map['unit']?.toString() ?? '',
      actions: _toStringList(map['actions']),
    );
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString());
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return const [];
  }
}

class AutomationEvent {
  const AutomationEvent({
    required this.id,
    required this.ruleId,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.severity,
    required this.isTest,
  });

  final String id;
  final String ruleId;
  final String title;
  final String message;
  final DateTime createdAt;
  final AutomationSeverity severity;
  final bool isTest;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruleId': ruleId,
      'title': title,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'severity': severity.name,
      'isTest': isTest,
    };
  }

  factory AutomationEvent.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    return AutomationEvent(
      id: id,
      ruleId: map['ruleId']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      createdAt: _toDateTime(map['createdAt']),
      severity: AutomationSeverity.values.firstWhere(
            (severity) => severity.name == map['severity'],
        orElse: () => AutomationSeverity.info,
      ),
      isTest: map['isTest'] == true,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return DateTime.now();
  }
}