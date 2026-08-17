import '../models/esp32_system_status.dart';

abstract interface class SystemStatusRepository {
  Stream<Esp32SystemStatus> watchStatus();
  Stream<bool?> watchOnline();
  Future<void> dispose();
}
