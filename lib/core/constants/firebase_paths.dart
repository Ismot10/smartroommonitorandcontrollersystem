import 'app_config.dart';

abstract final class FirebasePaths {
  static String get roomRoot => 'rooms/${AppConfig.roomId}';

  static String get sensors => '$roomRoot/sensors';
  static String get devices => '$roomRoot/devices';
  static String get automation => '$roomRoot/automation';
  static String get automationRules => '$automation/rules';
  static String get alerts => '$roomRoot/alerts';
  static String get history => '$roomRoot/history';
  static String get schedules => '$roomRoot/schedules';
  static String get system => '$roomRoot/system';

  // Sensor paths
  static String get temperature => '$sensors/temperature';
  static String get humidity => '$sensors/humidity';
  static String get gas => '$sensors/gas';
  static String get motion => '$sensors/motion';
  static String get rain => '$sensors/rain';
  static String get lightLevel => '$sensors/lightLevel';

  // Device paths
  static String get whiteLight => '$devices/whiteLight';
  static String get rgbLight => '$devices/rgbLight';
  static String get curtain => '$devices/curtain';
  static String get buzzer => '$devices/buzzer';
  static String get fan => '$devices/fan';
  static String get doorLock => '$devices/doorLock';

  // System paths
  static String get online => '$system/online';
  static String get lastSeen => '$system/lastSeen';
}
