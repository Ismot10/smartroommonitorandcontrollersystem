import 'package:flutter_test/flutter_test.dart';
import 'package:smartroommonitorandcontrollersystem/models/smart_device.dart';

void main() {
  group('SmartDevice.fromMap', () {
    test('uses the Firebase key to recover a partial RGB light', () {
      final device = SmartDevice.fromMap('rgbLight', <String, dynamic>{
        'isOn': false,
      });

      expect(device.name, 'Aurora Light');
      expect(device.type, DeviceType.rgbLight);
      expect(device.connectionType, DeviceConnectionType.physical);
      expect(device.isOn, isFalse);
    });

    test('does not misclassify a curtain with stale light metadata', () {
      final device = SmartDevice.fromMap('curtain', <String, dynamic>{
        'name': 'curtain',
        'type': 'whiteLight',
        'brightness': 100,
        'curtainPosition': 'closed',
      });

      expect(device.name, 'Smart Curtain');
      expect(device.type, DeviceType.curtain);
      expect(device.curtainPosition, CurtainPosition.closed);
    });

    test('does not misclassify a buzzer with stale light metadata', () {
      final device = SmartDevice.fromMap('buzzer', <String, dynamic>{
        'name': 'buzzer',
        'type': 'whiteLight',
        'isOn': true,
      });

      expect(device.name, 'Safety Alarm');
      expect(device.type, DeviceType.buzzer);
      expect(device.isOn, isTrue);
    });

    test('still accepts metadata for unknown future devices', () {
      final device = SmartDevice.fromMap('futureDevice', <String, dynamic>{
        'name': 'Future Device',
        'type': 'fan',
        'connectionType': 'digitalTwin',
      });

      expect(device.name, 'Future Device');
      expect(device.type, DeviceType.fan);
      expect(device.connectionType, DeviceConnectionType.digitalTwin);
    });
  });
}
