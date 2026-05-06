import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/src/scanner/koi_network_scanner.dart';

void main() {
  group('KoiNetworkScanner', () {
    late KoiNetworkScanner scanner;

    setUp(() {
      scanner = KoiNetworkScanner();
    });

    test('scan discovers active printer port', () async {
      // Setup a local test server to simulate a printer
      final server = await ServerSocket.bind('127.0.0.1', 0);
      final port = server.port;

      final results = <String>[];

      final sub = scanner
          .scan(
            subnet: '127.0.0',
            port: port,
            timeout: const Duration(milliseconds: 50),
            endIp: 1, // Only scan 127.0.0.1
          )
          .listen((device) {
            results.add(device.deviceId);
          });

      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      await server.close();

      expect(results, contains('127.0.0.1:$port'));
    });

    test('scan ignores unreachable IPs', () async {
      // Don't start any server, so it should be unreachable
      final results = <String>[];

      final sub = scanner
          .scan(
            subnet: '127.0.0',
            port: 19100, // hopefully unused port
            timeout: const Duration(milliseconds: 10),
            endIp: 2,
          )
          .listen((device) {
            results.add(device.deviceId);
          });

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();

      expect(results, isEmpty);
    });

    test('stopScan does not throw', () async {
      await expectLater(scanner.stopScan(), completes);
    });
  });
}
