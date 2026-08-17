class DeviceSchedule {
  const DeviceSchedule({
    required this.id,
    required this.name,
    required this.deviceId,
    required this.deviceName,
    required this.turnOn,
    required this.hour,
    required this.minute,
    required this.weekdays,
    required this.enabled,
    required this.createdAt,
    required this.updatedAt,
    this.lastExecutedAt,
    this.level,
  });

  final String id;
  final String name;
  final String deviceId;
  final String deviceName;
  final bool turnOn;
  final int hour;
  final int minute;
  final List<int> weekdays;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastExecutedAt;
  final int? level;

  bool get repeats => weekdays.isNotEmpty;

  DeviceSchedule copyWith({
    String? id,
    String? name,
    String? deviceId,
    String? deviceName,
    bool? turnOn,
    int? hour,
    int? minute,
    List<int>? weekdays,
    bool? enabled,
    DateTime? updatedAt,
    DateTime? lastExecutedAt,
    int? level,
  }) {
    return DeviceSchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      turnOn: turnOn ?? this.turnOn,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekdays: weekdays ?? this.weekdays,
      enabled: enabled ?? this.enabled,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      level: level ?? this.level,
    );
  }

  DateTime? nextOccurrence([DateTime? from]) {
    if (!enabled) return null;
    final now = from ?? DateTime.now();

    for (var offset = 0; offset <= 7; offset++) {
      final date = now.add(Duration(days: offset));
      if (weekdays.isNotEmpty && !weekdays.contains(date.weekday)) {
        continue;
      }

      final candidate = DateTime(date.year, date.month, date.day, hour, minute);
      if (candidate.isAfter(now)) {
        return candidate;
      }
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'turnOn': turnOn,
      'action': action,
      if (level != null) 'level': level,
      'hour': hour,
      'minute': minute,
      'weekdays': weekdays.isEmpty
          ? {'once': true}
          : {for (final day in weekdays) '$day': day},
      'enabled': enabled,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      if (lastExecutedAt != null)
        'lastExecutedAt': lastExecutedAt!.millisecondsSinceEpoch,
    };
  }

  factory DeviceSchedule.fromMap(String id, Map<dynamic, dynamic> map) {
    return DeviceSchedule(
      id: id,
      name:
          map['name']?.toString() ??
          map['deviceName']?.toString() ??
          'Device schedule',
      deviceId: map['deviceId']?.toString() ?? '',
      deviceName: map['deviceName']?.toString() ?? 'Device',
      turnOn: map['turnOn'] == true,
      level: map['level'] == null ? null : _int(map['level']).clamp(0, 100),
      hour: _int(map['hour']).clamp(0, 23),
      minute: _int(map['minute']).clamp(0, 59),
      weekdays: _weekdays(map['weekdays']),
      enabled: map['enabled'] != false,
      createdAt: _date(map['createdAt']),
      updatedAt: _date(map['updatedAt']),
      lastExecutedAt: map['lastExecutedAt'] == null
          ? null
          : _date(map['lastExecutedAt']),
    );
  }

  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static DateTime _date(dynamic value) =>
      DateTime.fromMillisecondsSinceEpoch(value is num ? value.toInt() : 0);

  static List<int> _weekdays(dynamic value) {
    if (value is List) {
      return value.map(_int).where((day) => day >= 1 && day <= 7).toList();
    }
    if (value is Map) {
      return value.values
          .map(_int)
          .where((day) => day >= 1 && day <= 7)
          .toList();
    }
    return const [];
  }

  String get action {
    return switch (deviceId) {
      'curtain' => turnOn ? 'open' : 'closed',
      'doorLock' => turnOn ? 'locked' : 'unlocked',
      _ => turnOn ? 'on' : 'off',
    };
  }

  String get actionLabel {
    final base = switch (deviceId) {
      'curtain' => turnOn ? 'Open' : 'Close',
      'doorLock' => turnOn ? 'Lock' : 'Unlock',
      _ => turnOn ? 'Turn ON' : 'Turn OFF',
    };
    if (turnOn &&
        level != null &&
        (deviceId == 'whiteLight' || deviceId == 'fan')) {
      return '$base at $level%';
    }
    return base;
  }
}
