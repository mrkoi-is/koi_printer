import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';
import 'package:mocktail/mocktail.dart';

class MockBluetoothDevice extends Mock implements BluetoothDevice {}

class MockBluetoothService extends Mock implements BluetoothService {}

class MockBluetoothCharacteristic extends Mock
    implements BluetoothCharacteristic {}

void main() {
  setUpAll(() {
    registerFallbackValue(const Duration(seconds: 1));
  });

  group('KoiBleAdapter', () {
    late KoiBleAdapter adapter;
    late MockBluetoothDevice mockDevice;

    setUp(() {
      mockDevice = MockBluetoothDevice();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => Stream.value(BluetoothConnectionState.disconnected));
      when(() => mockDevice.mtu).thenAnswer((_) => Stream.value(512));
      when(() => mockDevice.disconnect()).thenAnswer((_) async {});

      adapter = KoiBleAdapter(
        deviceFactory: (id) => mockDevice,
      );
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('initial state is correct', () {
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.connectionType, KoiConnectionType.ble);
      expect(adapter.isReady, false);
      expect(adapter.config, null);
    });

    test('queryHardwareState returns unknown', () async {
      final state = await adapter.queryHardwareState();
      expect(state, KoiPrinterHardwareState.unknown);
    });

    test('getters return correct streams and policy', () {
      expect(
        adapter.hardwareStateStream,
        isA<Stream<KoiPrinterHardwareState>>(),
      );
      expect(adapter.stateStream, isA<Stream<KoiConnectionState>>());
      expect(adapter.policy, KoiConnectionPolicy.aggressive);
      expect(adapter.connectionType, KoiConnectionType.ble);
    });

    test('connect matches specific service and characteristic UUIDs', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
        serviceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
        characteristicUuid: '00002af1-0000-1000-8000-00805f9b34fb',
      );

      final mockService1 = MockBluetoothService();
      final mockService2 = MockBluetoothService();
      final mockChar1 = MockBluetoothCharacteristic();
      final mockChar2 = MockBluetoothCharacteristic();

      when(
        () => mockService1.uuid,
      ).thenReturn(Guid('00001800-0000-1000-8000-00805f9b34fb'));
      when(
        () => mockService2.uuid,
      ).thenReturn(Guid('000018f0-0000-1000-8000-00805f9b34fb'));
      when(
        () => mockChar1.uuid,
      ).thenReturn(Guid('00002a00-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar1.properties).thenReturn(
        const CharacteristicProperties(
          read: true,
        ),
      );
      when(
        () => mockChar2.uuid,
      ).thenReturn(Guid('00002af1-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar2.properties).thenReturn(
        const CharacteristicProperties(
          writeWithoutResponse: true,
          write: true,
        ),
      );

      when(() => mockService1.characteristics).thenReturn([mockChar1]);
      when(() => mockService2.characteristics).thenReturn([mockChar2]);
      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [mockService1, mockService2]);
      final connectionStateController =
          StreamController<BluetoothConnectionState>.broadcast();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {
        Future.delayed(const Duration(milliseconds: 50), () {
          if (!connectionStateController.isClosed) {
            connectionStateController.add(BluetoothConnectionState.connected);
          }
        });
      });

      final connectFuture = adapter.connect(config);
      final result = await connectFuture;

      expect(result, isTrue);
      expect(adapter.isReady, true);
      expect(adapter.state, KoiConnectionState.ready);

      // Now emit disconnected to hit the disconnect state coverage
      connectionStateController.add(BluetoothConnectionState.disconnected);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(adapter.state, KoiConnectionState.disconnected);
      await connectionStateController.close();
    });

    test('connect discovers services and becomes ready', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );

      final mockService = MockBluetoothService();
      final mockChar = MockBluetoothCharacteristic();

      when(
        () => mockService.uuid,
      ).thenReturn(Guid('0000ff00-0000-1000-8000-00805f9b34fb'));
      when(
        () => mockChar.uuid,
      ).thenReturn(Guid('0000ff01-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar.properties).thenReturn(
        const CharacteristicProperties(
          writeWithoutResponse: true,
          write: true,
        ),
      );

      when(() => mockService.characteristics).thenReturn([mockChar]);
      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [mockService]);

      // We simulate connection succeeding
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});

      // And we emit connected state
      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Simulate connected state from ble package
      connectionStateController.add(BluetoothConnectionState.connected);

      final result = await connectFuture;

      expect(result, isTrue);
      expect(adapter.state, KoiConnectionState.ready);
      expect(adapter.isReady, isTrue);
      expect(adapter.config, config);

      await connectionStateController.close();
    });

    test('disconnect updates state', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );
      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockDevice.discoverServices()).thenAnswer((_) async => []);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      await expectLater(adapter.disconnect(), completes);
      expect(adapter.state, KoiConnectionState.disconnected);
      verify(() => mockDevice.disconnect()).called(greaterThanOrEqualTo(1));

      await connectionStateController.close();
    });

    test('sendChunks throws StateError if not connected', () async {
      expect(
        () => adapter.sendChunks([
          [0x01],
        ]),
        throwsStateError,
      );
    });

    test('sendChunks writes to characteristic', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );

      final mockService = MockBluetoothService();
      final mockChar = MockBluetoothCharacteristic();

      when(
        () => mockService.uuid,
      ).thenReturn(Guid('0000ff00-0000-1000-8000-00805f9b34fb'));
      when(
        () => mockChar.uuid,
      ).thenReturn(Guid('0000ff01-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar.properties).thenReturn(
        const CharacteristicProperties(
          writeWithoutResponse: true,
          write: true,
        ),
      );

      when(() => mockService.characteristics).thenReturn([mockChar]);
      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [mockService]);

      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockChar.write(
          any(),
          withoutResponse: any(named: 'withoutResponse'),
        ),
      ).thenAnswer((_) async {});

      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      await adapter.sendChunks([
        [0x01, 0x02],
        [0x03, 0x04],
      ]);

      verify(
        () => mockChar.write([0x01, 0x02], withoutResponse: true),
      ).called(1);
      verify(
        () => mockChar.write([0x03, 0x04], withoutResponse: true),
      ).called(1);

      await connectionStateController.close();
    });

    test('connect retries on ANDROID_SPECIFIC_ERROR (133 error)', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );

      var connectAttempts = 0;
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {
        connectAttempts++;
        if (connectAttempts == 1) {
          throw Exception('ANDROID_SPECIFIC_ERROR (133)');
        }
      });
      when(() => mockDevice.discoverServices()).thenAnswer((_) async => []);

      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      expect(connectAttempts, 2);
      await connectionStateController.close();
    });

    test('disconnect catches error', () async {
      when(
        () => mockDevice.disconnect(),
      ).thenThrow(Exception('Disconnect error'));
      await expectLater(adapter.disconnect(), completes);
      expect(adapter.state, KoiConnectionState.disconnected);
    });

    test('sendChunks throws error and catches it', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );

      final mockService = MockBluetoothService();
      final mockChar = MockBluetoothCharacteristic();

      when(
        () => mockService.uuid,
      ).thenReturn(Guid('0000ff00-0000-1000-8000-00805f9b34fb'));
      when(
        () => mockChar.uuid,
      ).thenReturn(Guid('0000ff01-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar.properties).thenReturn(
        const CharacteristicProperties(
          writeWithoutResponse: true,
          write: true,
        ),
      );

      when(() => mockService.characteristics).thenReturn([mockChar]);
      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [mockService]);
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => mockChar.write(
          any(),
          withoutResponse: any(named: 'withoutResponse'),
        ),
      ).thenThrow(Exception('Write error'));

      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      await expectLater(
        adapter.sendChunks([
          [0x01, 0x02],
        ]),
        throwsException,
      );
      await connectionStateController.close();
    });

    test('ignores system UUIDs when searching for characteristics', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );

      final sysService = MockBluetoothService();
      final sysChar = MockBluetoothCharacteristic();
      final sysChar2 = MockBluetoothCharacteristic();
      final normalService = MockBluetoothService();
      final normalChar = MockBluetoothCharacteristic();

      when(
        () => sysService.uuid,
      ).thenReturn(Guid('00001800-0000-1000-8000-00805f9b34fb'));
      when(
        () => sysChar.uuid,
      ).thenReturn(Guid('00002a00-0000-1000-8000-00805f9b34fb'));
      when(
        () => sysChar2.uuid,
      ).thenReturn(Guid('00002a01-0000-1000-8000-00805f9b34fb'));
      when(
        () => normalService.uuid,
      ).thenReturn(Guid('0000ff00-0000-1000-8000-00805f9b34fb'));
      when(
        () => normalChar.uuid,
      ).thenReturn(Guid('0000ff01-0000-1000-8000-00805f9b34fb'));

      when(() => normalChar.properties).thenReturn(
        const CharacteristicProperties(
          writeWithoutResponse: true,
          write: true,
        ),
      );
      when(() => sysChar.properties).thenReturn(
        const CharacteristicProperties(
          read: true,
        ),
      );
      when(() => sysChar2.properties).thenReturn(
        const CharacteristicProperties(
          read: true,
          write: true,
        ),
      );

      when(() => sysService.characteristics).thenReturn([sysChar]);
      when(
        () => normalService.characteristics,
      ).thenReturn([sysChar2, normalChar]);
      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [sysService, normalService]);
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});

      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      expect(adapter.isReady, isTrue);
      await connectionStateController.close();
    });
    test('connect catches Exception and returns false', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );
      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenThrow(Exception('General connect error'));

      final result = await adapter.connect(config);
      expect(result, isFalse);
    });

    test('finds specific characteristic matching config uuid', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
        serviceUuid: '0000ff00-0000-1000-8000-00805f9b34fb',
        characteristicUuid: '0000ff01-0000-1000-8000-00805f9b34fb',
      );

      final mockService = MockBluetoothService();
      final mockChar = MockBluetoothCharacteristic();
      final wrongChar = MockBluetoothCharacteristic();
      final wrongService = MockBluetoothService();

      when(
        () => wrongService.uuid,
      ).thenReturn(Guid('00001111-0000-1000-8000-00805f9b34fb'));
      when(() => wrongService.characteristics).thenReturn([]);

      when(
        () => mockService.uuid,
      ).thenReturn(Guid('0000ff00-0000-1000-8000-00805f9b34fb'));

      when(
        () => wrongChar.uuid,
      ).thenReturn(Guid('00002222-0000-1000-8000-00805f9b34fb'));
      when(() => wrongChar.properties).thenReturn(
        const CharacteristicProperties(writeWithoutResponse: true, write: true),
      );

      when(
        () => mockChar.uuid,
      ).thenReturn(Guid('0000ff01-0000-1000-8000-00805f9b34fb'));
      when(() => mockChar.properties).thenReturn(
        const CharacteristicProperties(writeWithoutResponse: true, write: true),
      );

      when(() => mockService.characteristics).thenReturn([wrongChar, mockChar]);

      when(
        () => mockDevice.discoverServices(),
      ).thenAnswer((_) async => [wrongService, mockService]);

      when(
        () => mockDevice.connect(
          timeout: any(named: 'timeout'),
          autoConnect: any(named: 'autoConnect'),
          mtu: any(named: 'mtu'),
        ),
      ).thenAnswer((_) async {});

      final connectionStateController =
          StreamController<BluetoothConnectionState>();
      when(
        () => mockDevice.connectionState,
      ).thenAnswer((_) => connectionStateController.stream);

      final connectFuture = adapter.connect(config);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      connectionStateController.add(BluetoothConnectionState.connected);
      await connectFuture;

      expect(adapter.isReady, isTrue);
      await connectionStateController.close();
    });
  });
}
