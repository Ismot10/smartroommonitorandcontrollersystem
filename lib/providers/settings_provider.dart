import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _displayNameKey =
      'profileDisplayName';

  static const String _roomNameKey =
      'smartRoomName';

  static const String _notificationsKey =
      'notificationsEnabled';

  static const String _criticalAlertsKey =
      'criticalAlertsEnabled';

  static const String _automationAlertsKey =
      'automationAlertsEnabled';

  static const String _systemAlertsKey =
      'systemAlertsEnabled';

  static const String _hapticFeedbackKey =
      'hapticFeedbackEnabled';

  String _displayName = 'Ismot Ara';
  String _roomName = 'Living Room';

  bool _notificationsEnabled = true;
  bool _criticalAlertsEnabled = true;
  bool _automationAlertsEnabled = true;
  bool _systemAlertsEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _isLoaded = false;

  String get displayName => _displayName;
  String get roomName => _roomName;

  bool get notificationsEnabled =>
      _notificationsEnabled;

  bool get criticalAlertsEnabled =>
      _criticalAlertsEnabled;

  bool get automationAlertsEnabled =>
      _automationAlertsEnabled;

  bool get systemAlertsEnabled =>
      _systemAlertsEnabled;

  bool get hapticFeedbackEnabled =>
      _hapticFeedbackEnabled;

  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final preferences =
    await SharedPreferences.getInstance();

    _displayName =
        preferences.getString(_displayNameKey) ??
            'Ismot Ara';

    _roomName =
        preferences.getString(_roomNameKey) ??
            'Living Room';

    _notificationsEnabled =
        preferences.getBool(_notificationsKey) ??
            true;

    _criticalAlertsEnabled =
        preferences.getBool(_criticalAlertsKey) ??
            true;

    _automationAlertsEnabled =
        preferences.getBool(_automationAlertsKey) ??
            true;

    _systemAlertsEnabled =
        preferences.getBool(_systemAlertsKey) ??
            true;

    _hapticFeedbackEnabled =
        preferences.getBool(_hapticFeedbackKey) ??
            true;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDisplayName(
      String value,
      ) async {
    final name = value.trim();

    if (name.isEmpty || name == _displayName) {
      return;
    }

    _displayName = name;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setString(
      _displayNameKey,
      name,
    );
  }

  Future<void> setRoomName(
      String value,
      ) async {
    final name = value.trim();

    if (name.isEmpty || name == _roomName) {
      return;
    }

    _roomName = name;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setString(
      _roomNameKey,
      name,
    );
  }

  Future<void> setNotificationsEnabled(
      bool value,
      ) async {
    _notificationsEnabled = value;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _notificationsKey,
      value,
    );
  }

  Future<void> setCriticalAlertsEnabled(
      bool value,
      ) async {
    _criticalAlertsEnabled = value;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _criticalAlertsKey,
      value,
    );
  }

  Future<void> setAutomationAlertsEnabled(
      bool value,
      ) async {
    _automationAlertsEnabled = value;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _automationAlertsKey,
      value,
    );
  }

  Future<void> setSystemAlertsEnabled(
      bool value,
      ) async {
    _systemAlertsEnabled = value;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _systemAlertsKey,
      value,
    );
  }

  Future<void> setHapticFeedbackEnabled(
      bool value,
      ) async {
    _hapticFeedbackEnabled = value;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _hapticFeedbackKey,
      value,
    );
  }
}