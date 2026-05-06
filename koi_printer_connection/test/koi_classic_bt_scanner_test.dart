// ignore_for_file: lines_longer_than_80_chars // rationale: long strings in tests
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';
import 'package:koi_printer_connection/src/scanner/koi_classic_bt_scanner.dart';

void main() {
  group('KoiClassicBtScanner', () {
    late KoiClassicBtScanner scanner;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_bluetooth_serial/methods'),
            (methodCall) async {
              if (methodCall.method == 'getBondedDevices') {
                return [
                  {
                    'address': '00:11:22:33:44:55',
                    'name': 'Printer A',
                    'type': 1,
                    'isConnected': false,
                    'bondState': 12,
                  },
                ];
              }
              return null;
            },
          );
      scanner = KoiClassicBtScanner();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_bluetooth_serial/methods'),
            null,
          );
    });

    test('scan returns a stream and devices', () async {
      final stream = scanner.scan(timeout: const Duration(milliseconds: 100));
      expect(stream, isA<Stream<KoiDiscoveredDevice>>());

      final devices = await stream.toList();
      expect(devices.length, 1);
      expect(devices.first.name, 'Printer A');
    });

    test('stopScan completes', () async {
      await expectLater(scanner.stopScan(), completes);
    });

    test('scan handles getBondedDevices error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_bluetooth_serial/methods'),
            (methodCall) async {
              throw Exception('Simulated error');
            },
          );
      final stream = scanner.scan(timeout: const Duration(milliseconds: 100));
      final devices = await stream.toList();
      expect(devices, isEmpty);
    });
  });
}
