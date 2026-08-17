import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/esp32_system_status.dart';
import '../services/system_status_repository.dart';

class SystemStatusProvider extends ChangeNotifier {
  SystemStatusProvider({required SystemStatusRepository repository})
    : _repository = repository;

  final SystemStatusRepository _repository;
  StreamSubscription<Esp32SystemStatus>? _subscription;

  Esp32SystemStatus? _status;
  String? _error;

  Esp32SystemStatus? get status => _status;
  bool? get isOnline => _status?.isOnline;
  DateTime? get lastSeen => _status?.lastSeen;
  String? get error => _error;

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _repository.watchStatus().listen(
      (status) {
        _status = status;
        _error = null;
        notifyListeners();
      },
      onError: (Object error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  String get lastSeenLabel {
    final age = _status?.age;
    if (age == null) return 'Waiting for heartbeat';
    if (age.inSeconds < 3) return 'Last seen just now';
    if (age.inSeconds < 60) return 'Last seen ${age.inSeconds} sec ago';
    if (age.inMinutes < 60) return 'Last seen ${age.inMinutes} min ago';
    if (age.inHours < 24) return 'Last seen ${age.inHours} hr ago';
    return 'Last seen ${age.inDays} day${age.inDays == 1 ? '' : 's'} ago';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
