enum DeviceType { whiteLight, rgbLight, curtain, buzzer, fan, doorLock }

enum DeviceConnectionType { physical, digitalTwin }

enum CurtainPosition { open, closed }

enum DoorLockState { locked, unlocked }

class SmartDevice {
  const SmartDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.connectionType,
    required this.isOn,
    required this.isOnline,
    this.brightness = 100,
    this.rgbColor = 0xFF75B83B,
    this.curtainPosition = CurtainPosition.open,
    this.doorLockState = DoorLockState.locked,
  });

  final String id;
  final String name;
  final DeviceType type;
  final DeviceConnectionType connectionType;
  final bool isOn;
  final bool isOnline;
  final int brightness;
  final int rgbColor;
  final CurtainPosition curtainPosition;
  final DoorLockState doorLockState;

  bool get isPhysical => connectionType == DeviceConnectionType.physical;

  String get connectionLabel => isPhysical ? 'CONNECTED' : 'VIRTUAL DEVICE';

  SmartDevice copyWith({
    String? id,
    String? name,
    DeviceType? type,
    DeviceConnectionType? connectionType,
    bool? isOn,
    bool? isOnline,
    int? brightness,
    int? rgbColor,
    CurtainPosition? curtainPosition,
    DoorLockState? doorLockState,
  }) {
    return SmartDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      connectionType: connectionType ?? this.connectionType,
      isOn: isOn ?? this.isOn,
      isOnline: isOnline ?? this.isOnline,
      brightness: brightness ?? this.brightness,
      rgbColor: rgbColor ?? this.rgbColor,
      curtainPosition: curtainPosition ?? this.curtainPosition,
      doorLockState: doorLockState ?? this.doorLockState,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'connectionType': connectionType.name,
      'isOn': isOn,
      'isOnline': isOnline,
      'brightness': brightness,
      'rgbColor': rgbColor,
      'curtainPosition': curtainPosition.name,
      'doorLockState': doorLockState.name,
    };
  }

  factory SmartDevice.fromMap(String id, Map<dynamic, dynamic> raw) {
    final map = Map<String, dynamic>.from(
      raw.map((key, value) => MapEntry(key.toString(), value)),
    );

    return SmartDevice(
      id: id,
      name: _deviceName(id, map['name']?.toString()),
      type:
          _deviceTypeFromId(id) ??
          _parseDeviceType(map['type']?.toString()) ??
          DeviceType.whiteLight,
      connectionType:
          _connectionTypeFromId(id) ??
          _parseConnectionType(map['connectionType']?.toString()) ??
          DeviceConnectionType.physical,
      isOn: map['isOn'] == true,
      isOnline: map['isOnline'] != false,
      brightness: _toInt(map['brightness'], fallback: 100).clamp(0, 100),
      rgbColor: _toInt(map['rgbColor'], fallback: 0xFF75B83B),
      curtainPosition:
          _parseCurtainPosition(map['curtainPosition']?.toString()) ??
          CurtainPosition.open,
      doorLockState:
          _parseDoorLockState(map['doorLockState']?.toString()) ??
          DoorLockState.locked,
    );
  }

  static DeviceType? _deviceTypeFromId(String id) {
    return switch (id) {
      'whiteLight' => DeviceType.whiteLight,
      'rgbLight' => DeviceType.rgbLight,
      'curtain' => DeviceType.curtain,
      'buzzer' => DeviceType.buzzer,
      'fan' => DeviceType.fan,
      'doorLock' => DeviceType.doorLock,
      _ => null,
    };
  }

  static DeviceType? _parseDeviceType(String? value) {
    for (final type in DeviceType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  static DeviceConnectionType? _connectionTypeFromId(String id) {
    return switch (id) {
      'whiteLight' ||
      'rgbLight' ||
      'curtain' ||
      'buzzer' => DeviceConnectionType.physical,
      'fan' || 'doorLock' => DeviceConnectionType.digitalTwin,
      _ => null,
    };
  }

  static DeviceConnectionType? _parseConnectionType(String? value) {
    for (final type in DeviceConnectionType.values) {
      if (type.name == value) {
        return type;
      }
    }
    return null;
  }

  static String _deviceName(String id, String? storedName) {
    if (storedName != null &&
        storedName.trim().isNotEmpty &&
        storedName != id) {
      return storedName;
    }

    return switch (id) {
      'whiteLight' => 'Room Light',
      'rgbLight' => 'Aurora Light',
      'curtain' => 'Smart Curtain',
      'buzzer' => 'Safety Alarm',
      'fan' => 'Climate Fan',
      'doorLock' => 'Door Lock',
      _ => storedName ?? id,
    };
  }

  static CurtainPosition? _parseCurtainPosition(String? value) {
    return switch (value) {
      'open' => CurtainPosition.open,
      'closed' || 'close' => CurtainPosition.closed,
      _ => null,
    };
  }

  static DoorLockState? _parseDoorLockState(String? value) {
    return switch (value) {
      'locked' => DoorLockState.locked,
      'unlocked' => DoorLockState.unlocked,
      _ => null,
    };
  }

  static int _toInt(dynamic value, {required int fallback}) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
