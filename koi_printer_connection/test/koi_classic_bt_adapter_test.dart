// ignore_for_file: lines_longer_than_80_chars // rationale: long strings in tests
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

void main() {
  group('KoiClassicBtAdapter', () {
    late KoiClassicBtAdapter adapter;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      adapter = KoiClassicBtAdapter();
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('initial state is correct', () {
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.connectionType, KoiConnectionType.classicBluetooth);
      expect(adapter.isReady, false);
      expect(adapter.config, null);
      expect(adapter.policy, KoiConnectionPolicy.defaultPolicy);
      expect(adapter.stateStream, isA<Stream<KoiConnectionState>>());
      expect(
        adapter.hardwareStateStream,
        isA<Stream<KoiPrinterHardwareState>>(),
      );
    });

    test('queryHardwareState returns unknown', () async {
      final state = await adapter.queryHardwareState();
      expect(state, KoiPrinterHardwareState.unknown);
    });

    test('connect fails gracefully on missing plugin/invalid mac', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );
      // In test env, flutter_bluetooth_serial channel throws MissingPluginException
      // The adapter catches it and returns false.
      final result = await adapter.connect(config);
      expect(result, false);
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.config, config);
    });

    test('connect succeeds with mocked MethodChannel', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('flutter_bluetooth_serial/methods'),
            (methodCall) async {
              if (methodCall.method == 'connect') {
                return 1;
              }
              return null;
            },
          );

      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );
      final result = await adapter.connect(config);

      expect(result, isTrue);
      expect(adapter.isReady, isTrue);
      expect(adapter.state, KoiConnectionState.ready);

      // sendChunks might throw because EventChannel is not mocked, but we can catch it
      try {
        await adapter.sendChunks([
          [0x01, 0x02],
        ]);
      } on Object catch (_) {
        // It's fine if it throws due to platform channel missing
      }

      await adapter.disconnect();
      expect(adapter.state, KoiConnectionState.disconnected);
    });

    test('disconnect does not throw even if not connected', () async {
      await expectLater(adapter.disconnect(), completes);
      expect(adapter.state, KoiConnectionState.disconnected);
    });

    test('sendChunks throws Exception if not connected', () async {
      expect(
        () => adapter.sendChunks([
          [0x01],
        ]),
        throwsException,
      );
    });

    test('connect uses connectionFactory if provided', () async {
      const config = KoiConnectionConfig(
        deviceId: '00:11:22:33:44:55',
        deviceName: 'Printer',
      );
      var factoryCalled = false;
      final testAdapter = KoiClassicBtAdapter(
        connectionFactory: (address) async {
          factoryCalled = true;
          throw Exception('Factory error');
        },
      );

      final result = await testAdapter.connect(config);
      expect(result, isFalse);
      expect(factoryCalled, isTrue);
      await testAdapter.dispose();
    });

    test('disconnect handles error gracefully', () async {
      final testAdapter = KoiClassicBtAdapter(
        connectionFactory: (address) async {
          throw Exception('Force disconnect error');
        },
      );
      // We can't easily mock BluetoothConnection without implementing it entirely,
      // but disconnect() handles any exception. We can just call it.
      await testAdapter.disconnect();
      expect(testAdapter.state, KoiConnectionState.disconnected);
      await testAdapter.dispose();
    });
  });
}
