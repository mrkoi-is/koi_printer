import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

void main() {
  group('Koi Models', () {
    test('KoiConnectionConfig copyWith coverage', () {
      const config = KoiConnectionConfig(
        deviceName: 'Printer',
        deviceId: 'ID1',
      );

      final newConfig = config.copyWith(
        deviceName: 'NewPrinter',
        deviceId: 'ID2',
        mtu: 1024,
        serviceUuid: 's1',
        characteristicUuid: 'c1',
        host: '192.168.1.1',
        port: 9101,
        autoReconnect: true,
        connectionTimeout: const Duration(seconds: 10),
      );

      expect(newConfig.deviceName, 'NewPrinter');
      expect(newConfig.deviceId, 'ID2');
      expect(newConfig.mtu, 1024);
      expect(newConfig.serviceUuid, 's1');
      expect(newConfig.characteristicUuid, 'c1');
      expect(newConfig.host, '192.168.1.1');
      expect(newConfig.port, 9101);
      expect(newConfig.autoReconnect, true);
      expect(newConfig.connectionTimeout, const Duration(seconds: 10));

      final configUnchanged = config.copyWith();
      expect(configUnchanged.mtu, 512);
      expect(configUnchanged.autoReconnect, false);
    });

    test('KoiDiscoveredDevice hashCode coverage', () {
      const device = KoiDiscoveredDevice(
        name: 'Printer',
        deviceId: 'ID1',
        connectionType: KoiConnectionType.network,
      );

      final hash = device.hashCode;
      expect(hash, 'ID1'.hashCode);
    });
  });
}
