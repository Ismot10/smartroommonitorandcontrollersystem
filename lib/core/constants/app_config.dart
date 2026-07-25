abstract final class AppConfig {
  /// Sensor and device values remain simulated until
  /// the ESP32 and Realtime Database are connected.
  static const bool useMockData = false;

  /// Authentication is now provided by Firebase.
  static const bool useFirebaseAuth = true;

  /// Set false so onboarding appears only once.
  static const bool alwaysShowOnboarding = false;

  static const String appName =
      'Aurora Smart Living';

  static const String roomId = 'room_01';
}
