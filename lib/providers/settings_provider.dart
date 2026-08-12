import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_config.dart';
import '../models/user_profile.dart';
import '../services/user_profile_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider({UserProfileRepository? profileRepository})
    : _profileRepository = profileRepository;

  final UserProfileRepository? _profileRepository;
  StreamSubscription<UserProfile?>? _profileSubscription;
  String? _boundUserId;
  String _boundEmail = '';
  String _authDisplayName = '';
  bool _profileSeedRequested = false;

  static const String _displayNameKey = 'profileDisplayName';

  static const String _roomNameKey = 'smartRoomName';

  static const String _notificationsKey = 'notificationsEnabled';

  static const String _criticalAlertsKey = 'criticalAlertsEnabled';

  static const String _automationAlertsKey = 'automationAlertsEnabled';

  static const String _systemAlertsKey = 'systemAlertsEnabled';

  static const String _hapticFeedbackKey = 'hapticFeedbackEnabled';

  String _displayName = 'Ismot Ara';
  String _roomName = 'Living Room';

  bool _notificationsEnabled = true;
  bool _criticalAlertsEnabled = true;
  bool _automationAlertsEnabled = true;
  bool _systemAlertsEnabled = true;
  bool _hapticFeedbackEnabled = true;
  bool _isLoaded = false;
  Future<void>? _loadFuture;

  String get displayName => _displayName;
  String get roomName => _roomName;

  bool get notificationsEnabled => _notificationsEnabled;

  bool get criticalAlertsEnabled => _criticalAlertsEnabled;

  bool get automationAlertsEnabled => _automationAlertsEnabled;

  bool get systemAlertsEnabled => _systemAlertsEnabled;

  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;

  bool get isLoaded => _isLoaded;

  Future<void> bindUser({
    required String? uid,
    required String? email,
    required String? authDisplayName,
  }) async {
    await load();

    if (uid == null || uid.isEmpty) {
      await _profileSubscription?.cancel();
      _profileSubscription = null;
      _boundUserId = null;
      _profileSeedRequested = false;
      return;
    }

    _boundEmail = email?.trim() ?? '';
    _authDisplayName = authDisplayName?.trim() ?? '';

    if (_boundUserId == uid && _profileSubscription != null) {
      return;
    }

    await _profileSubscription?.cancel();
    _boundUserId = uid;
    _profileSeedRequested = false;

    final preferences = await SharedPreferences.getInstance();
    _displayName =
        preferences.getString(_userDisplayNameKey(uid)) ??
        (_authDisplayName.isNotEmpty ? _authDisplayName : _displayName);
    _roomName = preferences.getString(_userRoomNameKey(uid)) ?? _roomName;
    notifyListeners();

    final repository = _profileRepository;
    if (repository == null) {
      return;
    }

    _profileSubscription = repository.watchProfile(uid).listen((profile) {
      if (profile == null) {
        if (!_profileSeedRequested) {
          _profileSeedRequested = true;
          unawaited(_createInitialProfile(uid));
        }
        return;
      }

      _profileSeedRequested = true;
      _displayName = profile.displayName;
      _roomName = profile.roomName;
      unawaited(_cacheProfile(uid));
      notifyListeners();
    });
  }

  Future<void> load() {
    return _loadFuture ??= _loadFromCache();
  }

  Future<void> _loadFromCache() async {
    final preferences = await SharedPreferences.getInstance();

    _displayName = preferences.getString(_displayNameKey) ?? 'Ismot Ara';

    _roomName = preferences.getString(_roomNameKey) ?? 'Living Room';

    _notificationsEnabled = preferences.getBool(_notificationsKey) ?? true;

    _criticalAlertsEnabled = preferences.getBool(_criticalAlertsKey) ?? true;

    _automationAlertsEnabled =
        preferences.getBool(_automationAlertsKey) ?? true;

    _systemAlertsEnabled = preferences.getBool(_systemAlertsKey) ?? true;

    _hapticFeedbackEnabled = preferences.getBool(_hapticFeedbackKey) ?? true;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDisplayName(String value) async {
    final name = value.trim();

    if (name.isEmpty || name == _displayName) {
      return;
    }

    _displayName = name;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_displayNameKey, name);

    final uid = _boundUserId;
    if (uid != null) {
      await preferences.setString(_userDisplayNameKey(uid), name);
      await _profileRepository?.updateProfile(uid, {'displayName': name});
    }
  }

  Future<void> setRoomName(String value) async {
    final name = value.trim();

    if (name.isEmpty || name == _roomName) {
      return;
    }

    _roomName = name;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_roomNameKey, name);

    final uid = _boundUserId;
    if (uid != null) {
      await preferences.setString(_userRoomNameKey(uid), name);
      await _profileRepository?.updateProfile(uid, {'roomName': name});
    }
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_notificationsKey, value);
  }

  Future<void> setCriticalAlertsEnabled(bool value) async {
    _criticalAlertsEnabled = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_criticalAlertsKey, value);
  }

  Future<void> setAutomationAlertsEnabled(bool value) async {
    _automationAlertsEnabled = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_automationAlertsKey, value);
  }

  Future<void> setSystemAlertsEnabled(bool value) async {
    _systemAlertsEnabled = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_systemAlertsKey, value);
  }

  Future<void> setHapticFeedbackEnabled(bool value) async {
    _hapticFeedbackEnabled = value;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_hapticFeedbackKey, value);
  }

  Future<void> _createInitialProfile(String uid) async {
    final now = DateTime.now();
    final displayName = _authDisplayName.isNotEmpty
        ? _authDisplayName
        : _displayName;

    await _profileRepository?.createProfile(
      UserProfile(
        uid: uid,
        displayName: displayName,
        email: _boundEmail,
        roomId: AppConfig.roomId,
        roomName: _roomName,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _cacheProfile(String uid) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_displayNameKey, _displayName);
    await preferences.setString(_roomNameKey, _roomName);
    await preferences.setString(_userDisplayNameKey(uid), _displayName);
    await preferences.setString(_userRoomNameKey(uid), _roomName);
  }

  static String _userDisplayNameKey(String uid) => '$_displayNameKey.$uid';

  static String _userRoomNameKey(String uid) => '$_roomNameKey.$uid';

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _profileRepository?.dispose();
    super.dispose();
  }
}
