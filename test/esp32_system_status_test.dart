import 'package:flutter_test/flutter_test.dart';
import 'package:smartroommonitorandcontrollersystem/models/esp32_system_status.dart';

void main() {
  group('Esp32SystemStatus', () {
    final now = DateTime(2026, 8, 13, 12);

    test('is online while the heartbeat is fresh', () {
      final status = Esp32SystemStatus(
        reportedOnline: true,
        lastSeen: now.subtract(const Duration(seconds: 25)),
        observedAt: now,
      );

      expect(status.isOnline, isTrue);
    });

    test('becomes offline when the heartbeat is stale', () {
      final status = Esp32SystemStatus(
        reportedOnline: true,
        lastSeen: now.subtract(const Duration(seconds: 26)),
        observedAt: now,
      );

      expect(status.isOnline, isFalse);
    });

    test('respects an explicitly offline ESP32 status', () {
      final status = Esp32SystemStatus(
        reportedOnline: false,
        lastSeen: now,
        observedAt: now,
      );

      expect(status.isOnline, isFalse);
    });
  });
}
