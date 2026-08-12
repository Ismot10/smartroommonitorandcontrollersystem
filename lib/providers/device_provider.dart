import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/smart_device.dart';
import '../services/device_repository.dart';
import '../services/mock_data_service.dart';

class DeviceProvider extends ChangeNotifier {
  DeviceProvider({DeviceRepository? repository})
    : _repository = repository,
      _defaultDevices = List<SmartDevice>.from(MockDataService().devices),
      _devices = List<SmartDevice>.from(MockDataService().devices);

  final DeviceRepository? _repository;

  StreamSubscription<List<SmartDevice>>? _subscription;

  /// Complete expected Aurora device catalogue.
  ///
  /// Firebase may temporarily contain only part of this list.
  /// We merge Firebase devices with these defaults instead of
  /// deleting devices that are missing remotely.
  final List<SmartDevice> _defaultDevices;

  final List<SmartDevice> _devices;

  /// Prevent repeatedly trying to seed the same missing device
  /// while waiting for Firebase to send its updated snapshot.
  final Set<String> _missingSeedRequests = <String>{};

  bool _isLoading = true;
  String? _error;

  // ============================================================
  // GETTERS
  // ============================================================

  List<SmartDevice> get devices => List<SmartDevice>.unmodifiable(_devices);

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<SmartDevice> get activeDevices =>
      _devices.where((device) => device.isOn).toList();

  // ============================================================
  // START
  // ============================================================

  Future<void> start() async {
    final repository = _repository;

    // ----------------------------------------------------------
    // Mock/local mode
    // ----------------------------------------------------------

    if (repository == null) {
      _isLoading = false;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // This still handles the case where /devices is completely
      // empty.
      await repository.seedDevicesIfEmpty(_defaultDevices);

      await _subscription?.cancel();

      _subscription = repository.watchDevices().listen(
        _handleIncomingDevices,
        onError: (Object error) {
          _isLoading = false;
          _error = error.toString();
          notifyListeners();
        },
      );
    } catch (error) {
      _isLoading = false;
      _error = error.toString();
      notifyListeners();
    }
  }

  // ============================================================
  // FIREBASE SNAPSHOT HANDLING
  // ============================================================

  void _handleIncomingDevices(List<SmartDevice> incoming) {
    _isLoading = false;
    _error = null;

    final incomingById = <String, SmartDevice>{
      for (final device in incoming) device.id: device,
    };

    final mergedDevices = <SmartDevice>[];

    // ----------------------------------------------------------
    // Preserve the expected complete Aurora catalogue.
    //
    // When Firebase contains a device, Firebase is authoritative.
    // When it does not, use its local default temporarily.
    // ----------------------------------------------------------

    for (final defaultDevice in _defaultDevices) {
      final remoteDevice = incomingById[defaultDevice.id];

      if (remoteDevice != null) {
        mergedDevices.add(remoteDevice);

        // Firebase now contains it, so remove any previous
        // pending seed marker.
        _missingSeedRequests.remove(defaultDevice.id);
      } else {
        mergedDevices.add(defaultDevice);

        // Firebase is missing this specific device.
        // Seed only this device — do NOT overwrite existing
        // device states.
        _requestMissingDeviceSeed(defaultDevice);
      }
    }

    // ----------------------------------------------------------
    // Preserve any future/unknown Firebase devices as well.
    // ----------------------------------------------------------

    for (final remoteDevice in incoming) {
      final alreadyIncluded = mergedDevices.any(
        (device) => device.id == remoteDevice.id,
      );

      if (!alreadyIncluded) {
        mergedDevices.add(remoteDevice);
      }
    }

    _devices
      ..clear()
      ..addAll(mergedDevices);

    notifyListeners();
  }

  // ============================================================
  // SEED ONE MISSING DEVICE
  // ============================================================

  void _requestMissingDeviceSeed(SmartDevice device) {
    final repository = _repository;

    if (repository == null) {
      return;
    }

    // add() returns false if already present.
    if (!_missingSeedRequests.add(device.id)) {
      return;
    }

    unawaited(_seedMissingDevice(repository, device));
  }

  Future<void> _seedMissingDevice(
    DeviceRepository repository,
    SmartDevice device,
  ) async {
    try {
      await repository.saveDevice(device);

      debugPrint('[DeviceProvider] Seeded missing device: ${device.id}');
    } catch (error) {
      // Allow another snapshot to retry later.
      _missingSeedRequests.remove(device.id);

      debugPrint('[DeviceProvider] Failed to seed ${device.id}: $error');
    }
  }

  // ============================================================
  // FIND DEVICE
  // ============================================================

  SmartDevice? byId(String id) {
    for (final device in _devices) {
      if (device.id == id) {
        return device;
      }
    }

    return null;
  }

  // ============================================================
  // POWER
  // ============================================================

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

  // ============================================================
  // BRIGHTNESS
  // ============================================================

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

  // ============================================================
  // RGB COLOR
  // ============================================================

  void setRgbColor(String id, int rgbColor) {
    final index = _devices.indexWhere((device) => device.id == id);

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(rgbColor: rgbColor);

    _save(_devices[index]);

    notifyListeners();
  }

  // ============================================================
  // CURTAIN
  // ============================================================

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

  // ============================================================
  // DOOR DIGITAL TWIN
  // ============================================================

  void setDoorLockState(DoorLockState state) {
    final index = _devices.indexWhere((device) => device.id == 'doorLock');

    if (index == -1) {
      return;
    }

    _devices[index] = _devices[index].copyWith(
      doorLockState: state,

      // isOn here represents the active/locked state.
      isOn: state == DoorLockState.locked,
    );

    _save(_devices[index]);

    notifyListeners();
  }

  Future<bool> applyScheduledState({
    required String deviceId,
    required bool turnOn,
    int? level,
  }) async {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index == -1) return false;

    final current = _devices[index];
    final updated = switch (current.type) {
      DeviceType.curtain => current.copyWith(
        curtainPosition: turnOn ? CurtainPosition.open : CurtainPosition.closed,
        isOn: true,
      ),
      DeviceType.doorLock => current.copyWith(
        doorLockState: turnOn ? DoorLockState.locked : DoorLockState.unlocked,
        isOn: turnOn,
      ),
      _ => current.copyWith(
        isOn: turnOn,
        brightness: turnOn && level != null
            ? level.clamp(0, 100)
            : current.brightness,
      ),
    };

    _devices[index] = updated;
    notifyListeners();

    final repository = _repository;
    if (repository != null) await repository.saveDevice(updated);
    return true;
  }

  // ============================================================
  // SAVE
  // ============================================================

  void _save(SmartDevice device) {
    final repository = _repository;

    if (repository == null) {
      return;
    }

    unawaited(repository.saveDevice(device));
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _subscription?.cancel();

    _repository?.dispose();

    super.dispose();
  }
}
