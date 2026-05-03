import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  KoiConnectionConfig
  // ════════════════════════════════════════════════════════════

  group('KoiConnectionConfig', () {
    test('creates with defaults', () {
      const config = KoiConnectionConfig(
        deviceName: 'Test Printer',
        deviceId: '00:11:22:33:44:55',
      );
      expect(config.mtu, 512);
      expect(config.port, 9100);
      expect(config.autoReconnect, false);
    });

    test('copyWith creates new instance', () {
      const original = KoiConnectionConfig(
        deviceName: 'Printer A',
        deviceId: 'id-1',
        mtu: 512,
      );
      final copy = original.copyWith(mtu: 256, autoReconnect: true);
      expect(copy.mtu, 256);
      expect(copy.autoReconnect, true);
      expect(copy.deviceName, 'Printer A');
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiConnectionState
  // ════════════════════════════════════════════════════════════

  group('KoiConnectionState', () {
    test('has all expected values', () {
      expect(KoiConnectionState.values.length, 6);
      expect(
        KoiConnectionState.values,
        containsAll([
          KoiConnectionState.disconnected,
          KoiConnectionState.connecting,
          KoiConnectionState.connected,
          KoiConnectionState.discovering,
          KoiConnectionState.ready,
          KoiConnectionState.disconnecting,
        ]),
      );
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiConnectionType
  // ════════════════════════════════════════════════════════════

  group('KoiConnectionType', () {
    test('has 4 expected values', () {
      expect(KoiConnectionType.values.length, 4);
      expect(
        KoiConnectionType.values,
        containsAll([
          KoiConnectionType.ble,
          KoiConnectionType.classicBluetooth,
          KoiConnectionType.network,
          KoiConnectionType.usb,
        ]),
      );
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiDiscoveredDevice
  // ════════════════════════════════════════════════════════════

  group('KoiDiscoveredDevice', () {
    test('equality based on deviceId', () {
      const a = KoiDiscoveredDevice(
        name: 'Printer A',
        deviceId: 'id-1',
        connectionType: KoiConnectionType.ble,
      );
      const b = KoiDiscoveredDevice(
        name: 'Printer B',
        deviceId: 'id-1',
        connectionType: KoiConnectionType.ble,
      );
      const c = KoiDiscoveredDevice(
        name: 'Printer A',
        deviceId: 'id-2',
        connectionType: KoiConnectionType.ble,
      );
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('toString contains key info', () {
      const device = KoiDiscoveredDevice(
        name: 'Printer',
        deviceId: 'id-1',
        connectionType: KoiConnectionType.ble,
      );
      expect(device.toString(), contains('Printer'));
      expect(device.toString(), contains('id-1'));
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiConnectionPolicy
  // ════════════════════════════════════════════════════════════

  group('KoiConnectionPolicy', () {
    test('default policy has expected values', () {
      const p = KoiConnectionPolicy.defaultPolicy;
      expect(p.maxRetries, 10);
      expect(p.retryDelay, const Duration(milliseconds: 20));
      expect(p.retryStrategy, KoiRetryStrategy.linear);
      expect(p.autoReconnectInterval, const Duration(seconds: 3));
      expect(p.autoDisconnectAfter, isNull);
    });

    test('aggressive policy has shorter intervals', () {
      const p = KoiConnectionPolicy.aggressive;
      expect(p.maxRetries, 20);
      expect(p.retryDelay, const Duration(milliseconds: 10));
      expect(p.autoReconnectInterval, const Duration(seconds: 1));
      expect(p.retryStrategy, KoiRetryStrategy.linear);
    });

    test('conservative policy has exponential backoff', () {
      const p = KoiConnectionPolicy.conservative;
      expect(p.maxRetries, 5);
      expect(p.retryStrategy, KoiRetryStrategy.exponential);
      expect(p.autoDisconnectAfter, isNotNull);
      expect(p.autoDisconnectAfter, const Duration(seconds: 30));
    });

    test('delayForRetry linear returns fixed delay', () {
      const p = KoiConnectionPolicy(
        retryDelay: Duration(milliseconds: 100),
        retryStrategy: KoiRetryStrategy.linear,
      );
      expect(p.delayForRetry(0), const Duration(milliseconds: 100));
      expect(p.delayForRetry(1), const Duration(milliseconds: 100));
      expect(p.delayForRetry(5), const Duration(milliseconds: 100));
    });

    test('delayForRetry exponential doubles each attempt', () {
      const p = KoiConnectionPolicy(
        retryDelay: Duration(milliseconds: 100),
        retryStrategy: KoiRetryStrategy.exponential,
      );
      // attempt 0 → 100ms × 2^0 = 100ms
      expect(p.delayForRetry(0), const Duration(milliseconds: 100));
      // attempt 1 → 100ms × 2^1 = 200ms
      expect(p.delayForRetry(1), const Duration(milliseconds: 200));
      // attempt 2 → 100ms × 2^2 = 400ms
      expect(p.delayForRetry(2), const Duration(milliseconds: 400));
      // attempt 3 → 100ms × 2^3 = 800ms
      expect(p.delayForRetry(3), const Duration(milliseconds: 800));
    });

    test('delayForRetry exponential clamps at attempt 10', () {
      const p = KoiConnectionPolicy(
        retryDelay: Duration(milliseconds: 10),
        retryStrategy: KoiRetryStrategy.exponential,
      );
      // attempt 10 → 10ms × 2^10 = 10240ms
      expect(p.delayForRetry(10), const Duration(milliseconds: 10240));
      // attempt 20 → 应 clamp 到 10, 所以还是 10240ms
      expect(p.delayForRetry(20), const Duration(milliseconds: 10240));
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiPrinterHardwareState
  // ════════════════════════════════════════════════════════════

  group('KoiPrinterHardwareState', () {
    test('has 5 expected values', () {
      expect(KoiPrinterHardwareState.values.length, 5);
      expect(
        KoiPrinterHardwareState.values,
        containsAll([
          KoiPrinterHardwareState.ready,
          KoiPrinterHardwareState.outOfPaper,
          KoiPrinterHardwareState.coverOpen,
          KoiPrinterHardwareState.overheated,
          KoiPrinterHardwareState.unknown,
        ]),
      );
    });
  });

  // ════════════════════════════════════════════════════════════
  //  Adapter 初始化状态
  // ════════════════════════════════════════════════════════════

  group('KoiNetworkAdapter', () {
    test('initial state is disconnected', () {
      final adapter = KoiNetworkAdapter();
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.isReady, false);
      expect(adapter.connectionType, KoiConnectionType.network);
      expect(adapter.config, isNull);
    });

    test('policy defaults to conservative', () {
      final adapter = KoiNetworkAdapter();
      expect(adapter.policy.maxRetries, 5);
      expect(adapter.policy.retryStrategy, KoiRetryStrategy.exponential);
    });
  });

  group('KoiBleAdapter', () {
    test('initial state is disconnected', () {
      final adapter = KoiBleAdapter();
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.isReady, false);
      expect(adapter.connectionType, KoiConnectionType.ble);
    });
  });

  group('KoiClassicBtAdapter', () {
    test('initial state is disconnected', () {
      final adapter = KoiClassicBtAdapter();
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.isReady, false);
      expect(adapter.connectionType, KoiConnectionType.classicBluetooth);
    });
  });

  group('KoiUsbAdapter', () {
    test('initial state is disconnected', () {
      final adapter = KoiUsbAdapter();
      expect(adapter.state, KoiConnectionState.disconnected);
      expect(adapter.isReady, false);
      expect(adapter.connectionType, KoiConnectionType.usb);
    });
  });
}
