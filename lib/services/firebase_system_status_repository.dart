import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/esp32_system_status.dart';
import 'system_status_repository.dart';

class FirebaseSystemStatusRepository implements SystemStatusRepository {
  FirebaseSystemStatusRepository({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _reference = (database ?? FirebaseDatabase.instance).ref(
         'rooms/room_01/system',
       );

  final FirebaseAuth _auth;
  final DatabaseReference _reference;

  @override
  Stream<Esp32SystemStatus> watchStatus() {
    late final StreamController<Esp32SystemStatus> controller;
    StreamSubscription<User?>? authSubscription;
    StreamSubscription<DatabaseEvent>? databaseSubscription;
    Timer? clock;
    Esp32SystemStatus? latest;

    void emit(Esp32SystemStatus status) {
      latest = status;
      if (!controller.isClosed) controller.add(status);
    }

    Future<void> attachDatabaseListener(User? user) async {
      await databaseSubscription?.cancel();
      databaseSubscription = null;
      clock?.cancel();
      clock = null;

      if (user == null) {
        latest = null;
        emit(
          Esp32SystemStatus(
            reportedOnline: null,
            lastSeen: null,
            observedAt: DateTime.now(),
          ),
        );
        return;
      }

      clock = Timer.periodic(const Duration(seconds: 1), (_) {
        final status = latest;
        if (status != null) emit(status.observedAtTime(DateTime.now()));
      });

      databaseSubscription = _reference.onValue.listen((event) {
        final value = event.snapshot.value;
        final map = value is Map ? value : const <Object?, Object?>{};
        emit(
          Esp32SystemStatus(
            reportedOnline: _parseOnlineStatus(map['esp32_status']),
            lastSeen: _parseTimestamp(map['esp32_last_seen']),
            observedAt: DateTime.now(),
          ),
        );
      }, onError: controller.addError);
    }

    controller = StreamController<Esp32SystemStatus>(
      onListen: () {
        authSubscription = _auth.authStateChanges().listen(
          (user) => unawaited(attachDatabaseListener(user)),
          onError: controller.addError,
        );
      },
      onCancel: () async {
        clock?.cancel();
        await databaseSubscription?.cancel();
        await authSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Stream<bool?> watchOnline() {
    return watchStatus().map((status) => status.isOnline).distinct();
  }

  static bool? _parseOnlineStatus(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return switch (value.trim().toLowerCase()) {
        'online' => true,
        'offline' => false,
        _ => null,
      };
    }
    return null;
  }

  static DateTime? _parseTimestamp(dynamic value) {
    final milliseconds = switch (value) {
      int() => value,
      num() => value.toInt(),
      _ => int.tryParse(value?.toString() ?? ''),
    };
    if (milliseconds == null || milliseconds <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  @override
  Future<void> dispose() async {}
}
