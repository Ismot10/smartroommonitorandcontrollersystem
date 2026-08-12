enum AutomationRuleType {
  temperatureFan,
  lowLight,
  motionSecurity,
  rainCurtain,
  gasEmergency,
}

enum AutomationSeverity { info, warning, critical }

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

  Map<String, dynamic> toPersistenceMap() {
    return {
      'enabled': enabled,
      if (triggerValue != null) 'triggerValue': triggerValue,
      if (resetValue != null) 'resetValue': resetValue,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  factory AutomationRule.fromMap(String id, Map<dynamic, dynamic> map) {
    return AutomationRule(
      id: id,
      title: map['title']?.toString() ?? id,
      description: map['description']?.toString() ?? '',
      type: AutomationRuleType.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => AutomationRuleType.temperatureFan,
      ),
      enabled: map['enabled'] != false,
      triggerValue: _toNullableDouble(map['triggerValue']),
      resetValue: _toNullableDouble(map['resetValue']),
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
    this.isRead = false,
  });

  final String id;
  final String ruleId;
  final String title;
  final String message;
  final DateTime createdAt;
  final AutomationSeverity severity;
  final bool isTest;
  final bool isRead;

  AutomationSeverity get displaySeverity => switch (ruleId) {
    'gasEmergency' => AutomationSeverity.critical,
    'temperatureFan' || 'rainCurtain' => AutomationSeverity.warning,
    'motionSecurity' || 'lowLight' || 'schedule' => AutomationSeverity.info,
    _ => severity,
  };

  String get displayTitle => switch (ruleId) {
    'gasEmergency' => 'Gas Emergency Detected',
    'temperatureFan' => 'High Temperature Detected',
    'motionSecurity' => 'Motion Detected',
    'lowLight' => 'Low-Light Automation Activated',
    'rainCurtain' => 'Rain Detected — Curtain Closed',
    'schedule' => 'Scheduled Action Completed',
    'system' => title.isEmpty ? 'System Event' : title,
    _ => title.isEmpty ? 'Smart Room Alert' : title,
  };

  String get category => switch (ruleId) {
    'gasEmergency' => 'Safety',
    'temperatureFan' || 'rainCurtain' => 'Environment',
    'motionSecurity' => 'Security',
    'lowLight' => 'Automation',
    'schedule' => 'Schedule',
    _ => 'System',
  };

  bool get isAutomationCategory => switch (ruleId) {
    'temperatureFan' ||
    'lowLight' ||
    'motionSecurity' ||
    'rainCurtain' ||
    'gasEmergency' => true,
    _ => false,
  };

  String get triggerDescription => switch (ruleId) {
    'gasEmergency' => 'Gas sensor detected an unsafe condition.',
    'temperatureFan' => 'Room temperature crossed the configured limit.',
    'motionSecurity' => 'The motion sensor detected room activity.',
    'lowLight' => 'Room light level fell below the configured threshold.',
    'rainCurtain' => 'The rain sensor detected rainfall.',
    'schedule' => 'A scheduled device action reached its configured time.',
    _ => 'Aurora reported a smart-room system event.',
  };

  List<String> get automaticActions => switch (ruleId) {
    'gasEmergency' => const [
      'Safety Alarm activated',
      'Aurora Light activated',
      'Room Light activated',
      'Door Lock unlocked',
    ],
    'temperatureFan' => const ['Climate Fan activated'],
    'motionSecurity' => const ['Room Light activated', 'Door Lock secured'],
    'lowLight' => const ['Room Light activated'],
    'rainCurtain' => const ['Smart Curtain closed'],
    'schedule' => _scheduleActions(message),
    _ => const [],
  };

  static List<String> _scheduleActions(String message) {
    final normalized = message.trim();
    if (normalized.isEmpty) return const ['Scheduled action completed'];

    final separator = normalized.indexOf(':');
    var action = separator >= 0
        ? normalized.substring(separator + 1).trim()
        : normalized;
    if (action.endsWith('.')) action = action.substring(0, action.length - 1);
    if (action.isEmpty) return const ['Scheduled action completed'];
    return ['$action successfully'];
  }

  AutomationEvent copyWith({String? id, bool? isRead}) {
    return AutomationEvent(
      id: id ?? this.id,
      ruleId: ruleId,
      title: title,
      message: message,
      createdAt: createdAt,
      severity: severity,
      isTest: isTest,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ruleId': ruleId,
      'title': title,
      'message': message,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'severity': severity.name,
      'isTest': isTest,
      'isRead': isRead,
    };
  }

  factory AutomationEvent.fromMap(String id, Map<dynamic, dynamic> map) {
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
      isRead: map['isRead'] == true,
    );
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is num) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }

    return DateTime.now();
  }
}
