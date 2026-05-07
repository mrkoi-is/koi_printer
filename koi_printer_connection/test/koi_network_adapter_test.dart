import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

void main() {
  group('KoiNetworkAdapter', () {
    late KoiNetworkAdapter adapter;

    setUp(() {
      adapter = KoiNetworkAdapter();
    });

    tearDown(() async {
      await adapter.dispose();
    });

    test('initial state is correct', () {
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.policy, KoiConnectionPolicy.conservative);
      expect(adapter.connectionType, KoiConnectionType.network);
      expect(adapter.isReady, false);
      expect(adapter.config, null);
    });

    test('queryHardwareState returns unknown', () async {
      final state = await adapter.queryHardwareState();
      expect(state, KoiPrinterHardwareState.unknown);
    });

    test('connect fails gracefully on invalid host', () async {
      const config = KoiConnectionConfig(
        deviceId: '255.255.255.255',
        deviceName: 'Printer',
        connectionTimeout: Duration(milliseconds: 100),
      );
      final result = await adapter.connect(config);
      expect(result, false);
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.config, config);
    });

    test('disconnect does not throw even if not connected', () async {
      await expectLater(adapter.disconnect(), completes);
      expect(adapter.state, KoiConnectionState.disconnected);
    });

    test('sendChunks throws StateError if not connected', () async {
      expect(
        () => adapter.sendChunks([
          [0x01],
        ]),
        throwsStateError,
      );
    });

    test('properties access', () {
      expect(adapter.stateStream, isA<Stream<KoiConnectionState>>());
      expect(
        adapter.hardwareStateStream,
        isA<Stream<KoiPrinterHardwareState>>(),
      );
    });

    test('successful connection, send chunks, and disconnect', () async {
      final server = await ServerSocket.bind('127.0.0.1', 0);
      final port = server.port;

      final receivedData = <int>[];
      server.listen((socket) {
        socket.listen(receivedData.addAll);
      });

      final config = KoiConnectionConfig(
        deviceId: '127.0.0.1',
        deviceName: 'LocalPrinter',
        port: port,
        connectionTimeout: const Duration(milliseconds: 100),
      );
      final success = await adapter.connect(config);
      expect(success, true);
      expect(adapter.isReady, true);
      expect(adapter.state, KoiConnectionState.ready);

      await adapter.sendChunks([
        [0x01, 0x02],
        [0x03],
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(receivedData, [0x01, 0x02, 0x03]);

      await adapter.disconnect();
      expect(adapter.state, KoiConnectionState.disconnected);

      await server.close();
    });
  });
}
