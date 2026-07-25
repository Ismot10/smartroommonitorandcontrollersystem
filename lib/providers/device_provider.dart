import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/smart_device.dart';
import '../services/device_repository.dart';
import '../services/mock_data_service.dart';

class DeviceProvider extends ChangeNotifier {
  DeviceProvider({DeviceRepository? repository})
    : _repository = repository,
      _devices = List<SmartDevice>.from(MockDataService().devices);

  final DeviceRepository? _repository;
  StreamSubscription<List<SmartDevice>>? _subscription;

  final List<SmartDevice> _devices;

  List<SmartDevice> get devices => List.unmodifiable(_devices);

  List<SmartDevice> get activeDevices =>
      _devices.where((device) => device.isOn).toList();

  Future<void> start() async {
    final repository = _repository;
    if (repository == null) {
      return;
    }

    await repository.seedDevicesIfEmpty(_devices);
    await _subscription?.cancel();
    _subscription = repository.watchDevices().listen((incoming) {
      if (incoming.isEmpty) {
        return;
      }
      _devices
        ..clear()
        ..addAll(incoming);
      notifyListeners();
    });
  }

  SmartDevice? byId(String id) {
    for (final device in _devices) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }

  void toggle(String id) {
    final index = _devices.indexWhere((device) => device.id == id);

    if (index == -1) {
      return;
    }

    final current = _devices[index];

    _devices[index] = current.copyWith(isOn: !current.isOn);

    _save(_devices[index]);
    notifyListeners();
  }

  void setPower(String id, bool isOn) {
    final index = _devices.indexWhere((device) => device.id == id);

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(isOn: isOn);

    _save(_devices[index]);
    notifyListeners();
  }

  void setBrightness(String id, int brightness) {
    final index = _devices.indexWhere((device) => device.id == id);

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(
      brightness: brightness.clamp(0, 100),
    );

    _save(_devices[index]);
    notifyListeners();
  }

  void setRgbColor(String id, int rgbColor) {
    final index = _devices.indexWhere((device) => device.id == id);

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(rgbColor: rgbColor);

    _save(_devices[index]);
    notifyListeners();
  }

  void setCurtainPosition(CurtainPosition position) {
    final index = _devices.indexWhere((device) => device.id == 'curtain');

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(
      curtainPosition: position,
      isOn: true,
    );

    _save(_devices[index]);
    notifyListeners();
  }

  void setDoorLockState(DoorLockState state) {
    final index = _devices.indexWhere((device) => device.id == 'doorLock');

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(
      doorLockState: state,
      isOn: state == DoorLockState.locked,
    );

    _save(_devices[index]);
    notifyListeners();
  }

  void _save(SmartDevice device) {
    final repository = _repository;
    if (repository != null) {
      unawaited(repository.saveDevice(device));
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository?.dispose();
    super.dispose();
  }
}
