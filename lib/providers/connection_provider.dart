import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/connection_repository.dart';

enum CloudConnectionStatus { connecting, online, offline, reconnected }

class ConnectionProvider extends ChangeNotifier {
  ConnectionProvider({required ConnectionRepository repository})
    : _repository = repository;

  static const String _lastConnectedKey = 'firebase_last_connected_at';

  final ConnectionRepository _repository;

  StreamSubscription<bool>? _subscription;
  Timer? _onlineTransitionTimer;

  CloudConnectionStatus _status = CloudConnectionStatus.connecting;
  DateTime? _lastConnectedAt;
  bool _receivedConnectionEvent = false;

  CloudConnectionStatus get status => _status;
  DateTime? get lastConnectedAt => _lastConnectedAt;
  bool get isOffline => _status == CloudConnectionStatus.offline;

  Future<void> start() async {
    final preferences = await SharedPreferences.getInstance();
    final savedTimestamp = preferences.getInt(_lastConnectedKey);

    if (savedTimestamp != null) {
      _lastConnectedAt = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
      notifyListeners();
    }

    await _subscription?.cancel();
    _subscription = _repository.watchConnection().distinct().listen(
      _handleConnectionChanged,
      onError: (_) {
        _status = CloudConnectionStatus.offline;
        notifyListeners();
      },
    );
  }

  Future<void> _handleConnectionChanged(bool connected) async {
    _onlineTransitionTimer?.cancel();

    if (!connected) {
      _status = CloudConnectionStatus.offline;
      _receivedConnectionEvent = true;
      notifyListeners();
      return;
    }

    final wasDisconnected =
        _receivedConnectionEvent && _status == CloudConnectionStatus.offline;

    _lastConnectedAt = DateTime.now();
    _receivedConnectionEvent = true;
    _status = wasDisconnected
        ? CloudConnectionStatus.reconnected
        : CloudConnectionStatus.online;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _lastConnectedKey,
      _lastConnectedAt!.millisecondsSinceEpoch,
    );

    if (wasDisconnected) {
      _onlineTransitionTimer = Timer(const Duration(seconds: 4), () {
        _status = CloudConnectionStatus.online;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _onlineTransitionTimer?.cancel();
    _subscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
