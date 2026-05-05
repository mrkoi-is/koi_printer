import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart' show KoiBleScanner;
import 'package:koi_printer_connection/src/scanner/koi_ble_scanner.dart' show KoiBleScanner;

/// BLE 扫描的抽象提供者接口。
/// 将 FlutterBluePlus 的静态 API 包装为可 Mock 的实例方法，
/// 使 [KoiBleScanner] 在单元测试中可以注入模拟数据。
///
/// Abstract provider interface for BLE scanning.
/// Wraps FlutterBluePlus's static API into mockable instance methods,
/// enabling dependency injection in [KoiBleScanner] unit tests.
abstract class KoiBleScannerProvider {
  /// 启动 BLE 扫描。
  Future<void> startScan({Duration? timeout});

  /// 获取扫描结果流。
  Stream<List<ScanResult>> get scanResults;

  /// 停止 BLE 扫描。
  Future<void> stopScan();
}

/// 默认实现，委托给真实的 [FlutterBluePlus] 静态 API。
/// Default implementation that delegates to the real [FlutterBluePlus] statics.
// coverage:ignore-start
class KoiBleScannerProviderImpl implements KoiBleScannerProvider {
  @override
  Future<void> startScan({Duration? timeout}) =>
      FlutterBluePlus.startScan(timeout: timeout);

  @override
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  @override
  Future<void> stopScan() => FlutterBluePlus.stopScan();
}
// coverage:ignore-end
