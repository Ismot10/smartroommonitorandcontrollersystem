import '../models/sensor_data.dart';
import '../models/smart_device.dart';

class MockDataService {
  SensorData get sensors => SensorData.initial();

  List<SmartDevice> get devices {
    return const [
      SmartDevice(
        id: 'whiteLight',
        name: 'Room Light',
        type: DeviceType.whiteLight,
        connectionType: DeviceConnectionType.physical,
        isOn: true,
        isOnline: true,
        brightness: 82,
      ),
      SmartDevice(
        id: 'rgbLight',
        name: 'Aurora Light',
        type: DeviceType.rgbLight,
        connectionType: DeviceConnectionType.physical,
        isOn: true,
        isOnline: true,
        brightness: 70,
        rgbColor: 0xFF7656E8,
      ),
      SmartDevice(
        id: 'curtain',
        name: 'Smart Curtain',
        type: DeviceType.curtain,
        connectionType: DeviceConnectionType.physical,
        isOn: true,
        isOnline: true,
        curtainPosition: CurtainPosition.open,
      ),
      SmartDevice(
        id: 'buzzer',
        name: 'Safety Alarm',
        type: DeviceType.buzzer,
        connectionType: DeviceConnectionType.physical,
        isOn: false,
        isOnline: true,
      ),
      SmartDevice(
        id: 'fan',
        name: 'Climate Fan',
        type: DeviceType.fan,
        connectionType: DeviceConnectionType.digitalTwin,
        isOn: false,
        isOnline: true,
        brightness: 45,
      ),
      SmartDevice(
        id: 'doorLock',
        name: 'Door Lock',
        type: DeviceType.doorLock,
        connectionType: DeviceConnectionType.digitalTwin,
        isOn: true,
        isOnline: true,
        doorLockState: DoorLockState.locked,
      ),
    ];
  }
}