enum DeviceType {
  whiteLight,
  rgbLight,
  curtain,
  buzzer,
  fan,
  doorLock,
}

enum DeviceConnectionType {
  physical,
  digitalTwin,
}

enum CurtainPosition {
  open,
  closed,
}

enum DoorLockState {
  locked,
  unlocked,
}

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

  bool get isPhysical =>
      connectionType == DeviceConnectionType.physical;

  String get connectionLabel =>
      isPhysical ? 'CONNECTED' : 'VIRTUAL DEVICE';

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

  factory SmartDevice.fromMap(
      String id,
      Map<dynamic, dynamic> map,
      ) {
    return SmartDevice(
      id: id,
      name: map['name']?.toString() ?? id,
      type: DeviceType.values.firstWhere(
            (type) => type.name == map['type'],
        orElse: () => DeviceType.whiteLight,
      ),
      connectionType: DeviceConnectionType.values.firstWhere(
            (type) => type.name == map['connectionType'],
        orElse: () => DeviceConnectionType.physical,
      ),
      isOn: map['isOn'] == true,
      isOnline: map['isOnline'] != false,
      brightness: _toInt(map['brightness'], fallback: 100),
      rgbColor: _toInt(
        map['rgbColor'],
        fallback: 0xFF75B83B,
      ),
      curtainPosition: CurtainPosition.values.firstWhere(
            (position) => position.name == map['curtainPosition'],
        orElse: () => CurtainPosition.open,
      ),
      doorLockState: DoorLockState.values.firstWhere(
            (state) => state.name == map['doorLockState'],
        orElse: () => DoorLockState.locked,
      ),
    );
  }

  static int _toInt(
      dynamic value, {
        required int fallback,
      }) {
    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}