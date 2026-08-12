import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/automation_rule.dart';
import '../services/alert_repository.dart';

class AlertProvider extends ChangeNotifier {
  AlertProvider({AlertRepository? repository}) : _repository = repository;

  final AlertRepository? _repository;
  final List<AutomationEvent> _alerts = [];
  StreamSubscription<List<AutomationEvent>>? _subscription;
  bool _hasLoaded = false;
  String? _error;

  List<AutomationEvent> get alerts => List.unmodifiable(_alerts);
  int get unreadCount => _alerts.where((alert) => !alert.isRead).length;
  bool get hasLoaded => _hasLoaded;
  bool get isLoading => !_hasLoaded && _error == null;
  String? get error => _error;

  Future<void> start() async {
    final repository = _repository;
    if (repository == null) {
      _hasLoaded = true;
      _error = null;
      notifyListeners();
      return;
    }

    _hasLoaded = false;
    _error = null;
    notifyListeners();
    await _subscription?.cancel();
    _subscription = repository.watchAlerts().listen(
      (alerts) {
        _hasLoaded = true;
        _error = null;
        _alerts
          ..clear()
          ..addAll(alerts);
        notifyListeners();
      },
      onError: (Object error) {
        _hasLoaded = true;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> add(AutomationEvent alert) async {
    final repository = _repository;
    if (repository == null) {
      _upsert(alert);
      return;
    }

    final persisted = await repository.addAlert(alert);
    _upsert(persisted);
  }

  Future<void> setRead(String id, bool isRead) async {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) {
      return;
    }

    _alerts[index] = _alerts[index].copyWith(isRead: isRead);
    notifyListeners();
    await _repository?.setRead(id, isRead);
  }

  Future<void> markAllRead() async {
    final unreadIds = _alerts
        .where((alert) => !alert.isRead)
        .map((alert) => alert.id)
        .toList();
    for (final id in unreadIds) {
      await setRead(id, true);
    }
  }

  Future<void> delete(String id) async {
    _alerts.removeWhere((alert) => alert.id == id);
    notifyListeners();
    await _repository?.deleteAlert(id);
  }

  Future<void> restore(AutomationEvent alert) async {
    _upsert(alert);
    await _repository?.saveAlert(alert);
  }

  Future<void> clear() async {
    _alerts.clear();
    notifyListeners();
    await _repository?.clearAlerts();
  }

  void _upsert(AutomationEvent alert) {
    final index = _alerts.indexWhere((item) => item.id == alert.id);
    if (index == -1) {
      _alerts.insert(0, alert);
    } else {
      _alerts[index] = alert;
    }
    _alerts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository?.dispose();
    super.dispose();
  }
}
