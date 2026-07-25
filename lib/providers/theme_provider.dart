import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'darkModeEnabled';

  bool _isDarkMode = false;
  bool _isLoaded = false;

  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  ThemeMode get themeMode {
    return _isDarkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> load() async {
    final preferences =
    await SharedPreferences.getInstance();

    _isDarkMode =
        preferences.getBool(_darkModeKey) ?? false;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool enabled) async {
    if (_isDarkMode == enabled) {
      return;
    }

    _isDarkMode = enabled;
    notifyListeners();

    final preferences =
    await SharedPreferences.getInstance();

    await preferences.setBool(
      _darkModeKey,
      enabled,
    );
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!_isDarkMode);
  }
}