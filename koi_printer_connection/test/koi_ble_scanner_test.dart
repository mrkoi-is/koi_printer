import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';
import 'package:koi_printer_connection/src/scanner/koi_ble_scanner.dart';
import 'package:koi_printer_connection/src/scanner/koi_ble_scanner_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockBleScannerProvider extends Mock implements KoiBleScannerProvider {}

class MockScanResult extends Mock implements ScanResult {}

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

/// 构造一个用于测试的 Mock ScanResult。
MockScanResult _makeMockScanResult({
  required String deviceId,
  String platformName = '',
  int rssi = -50,
}) {
  final mockDevice = MockBluetoothDevice();
  when(() => mockDevice.platformName).thenReturn(platformName);
  when(() => mockDevice.remoteId).thenReturn(DeviceIdentifier(deviceId));

  final mockResult = MockScanResult();
  when(() => mockResult.device).thenReturn(mockDevice);
  when(() => mockResult.rssi).thenReturn(rssi);

  return mockResult;
}

void main() {
  group('KoiBleScanner', () {
    late MockBleScannerProvider mockProvider;
    late KoiBleScanner scanner;
    late StreamController<List<ScanResult>> scanResultsController;

    setUp(() {
      mockProvider = MockBleScannerProvider();
      scanResultsController = StreamController<List<ScanResult>>.broadcast();

      when(() => mockProvider.startScan(timeout: any(named: 'timeout')))
          .thenAnswer((_) async {});
      when(() => mockProvider.scanResults)
          .thenAnswer((_) => scanResultsController.stream);
      when(() => mockProvider.stopScan()).thenAnswer((_) async {});

      scanner = KoiBleScanner(provider: mockProvider);
    });

    tearDown(() async {
      if (!scanResultsController.isClosed) {
        await scanResultsController.close();
      }
    });

    test('scan emits KoiDiscoveredDevice for devices with names', () async {
      final result1 = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:01',
        platformName: 'Printer-01',
        rssi: -45,
      );
      final result2 = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:02',
        platformName: 'Printer-02',
        rssi: -70,
      );

      final stream = scanner.scan(timeout: const Duration(milliseconds: 200));
      final devices = <KoiDiscoveredDevice>[];
      final sub = stream.listen(devices.add);

      // 等待 onListen -> startScan 触发
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 推入扫描结果
      scanResultsController.add([result1, result2]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(devices.length, 2);
      expect(devices[0].name, 'Printer-01');
      expect(devices[0].deviceId, 'AA:BB:CC:DD:EE:01');
      expect(devices[0].connectionType, KoiConnectionType.ble);
      expect(devices[0].rssi, -45);
      expect(devices[1].name, 'Printer-02');
      expect(devices[1].rssi, -70);

      await sub.cancel();
    });

    test('scan filters out nameless devices when withNames=true', () async {
      final withName = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:01',
        platformName: 'Printer',
      );
      final noName = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:02',
        platformName: '', // 无名称
      );

      final stream = scanner.scan(
        timeout: const Duration(milliseconds: 200),
        withNames: true,
      );
      final devices = <KoiDiscoveredDevice>[];
      final sub = stream.listen(devices.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      scanResultsController.add([withName, noName]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(devices.length, 1);
      expect(devices[0].name, 'Printer');

      await sub.cancel();
    });

    test('scan includes nameless devices when withNames=false', () async {
      final noName = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:01',
        platformName: '',
      );

      final stream = scanner.scan(
        timeout: const Duration(milliseconds: 200),
        withNames: false,
      );
      final devices = <KoiDiscoveredDevice>[];
      final sub = stream.listen(devices.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      scanResultsController.add([noName]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(devices.length, 1);
      expect(devices[0].name, 'Unknown'); // 空名称映射为 'Unknown'

      await sub.cancel();
    });

    test('scan deduplicates devices by deviceId', () async {
      final result = _makeMockScanResult(
        deviceId: 'AA:BB:CC:DD:EE:01',
        platformName: 'Printer',
      );

      final stream = scanner.scan(timeout: const Duration(milliseconds: 200));
      final devices = <KoiDiscoveredDevice>[];
      final sub = stream.listen(devices.add);

      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 推入两次相同 deviceId
      scanResultsController.add([result]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      scanResultsController.add([result]);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(devices.length, 1); // 只出现一次

      await sub.cancel();
    });

    test('scan stream auto-closes after timeout', () async {
      final stream = scanner.scan(timeout: const Duration(milliseconds: 100));
      final devices = await stream.toList(); // 等待流关闭
      expect(devices, isEmpty);
    });

    test('scan handles startScan error gracefully', () async {
      when(() => mockProvider.startScan(timeout: any(named: 'timeout')))
          .thenAnswer((_) async => throw Exception('BLE not available'));

      final stream = scanner.scan(timeout: const Duration(milliseconds: 100));
      // startScan 的错误被 catchError 捕获，stream 不应崩溃
      final devices = await stream.toList();
      expect(devices, isEmpty);
    });

    test('cancel triggers stopScan on provider', () async {
      final stream = scanner.scan(timeout: const Duration(milliseconds: 500));
      final sub = stream.listen((_) {});

      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      verify(() => mockProvider.stopScan()).called(1);
    });

    test('stopScan completes normally', () async {
      await expectLater(scanner.stopScan(), completes);
      verify(() => mockProvider.stopScan()).called(1);
    });

    test('stopScan catches provider error', () async {
      when(() => mockProvider.stopScan())
          .thenAnswer((_) async => throw Exception('Stop failed'));

      // 不应抛出异常
      await expectLater(scanner.stopScan(), completes);
    });

    test('default constructor uses real provider', () {
      // 验证无参构造不崩溃
      final defaultScanner = KoiBleScanner();
      expect(defaultScanner, isNotNull);
    });
  });
}
