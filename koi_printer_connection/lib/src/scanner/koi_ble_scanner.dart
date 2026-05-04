import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

/// BLE 设备扫描器。
/// Scanner for discovering BLE printers using flutter_blue_plus.
class KoiBleScanner {
  /// 扫描 BLE 设备。
  ///
  /// [timeout] 扫描超时时间。
  /// [withNames] 仅返回有名称的设备。
  /// 返回设备流, 在 timeout 后自动停止。
  Stream<KoiDiscoveredDevice> scan({
    Duration timeout = const Duration(seconds: 5),
    bool withNames = true,
  }) {
    final controller = StreamController<KoiDiscoveredDevice>();
    final seenIds = <String>{};

    StreamSubscription<List<ScanResult>>? scanSub;

    void startScan() {
      unawaited(FlutterBluePlus.startScan(timeout: timeout));
      scanSub = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final name = result.device.platformName;
          if (withNames && name.isEmpty) continue;

          final deviceId = result.device.remoteId.str;
          if (seenIds.contains(deviceId)) continue;
          seenIds.add(deviceId);

          controller.add(
            KoiDiscoveredDevice(
              name: name.isEmpty ? 'Unknown' : name,
              deviceId: deviceId,
              connectionType: KoiConnectionType.ble,
              rssi: result.rssi,
            ),
          );
        }
      });

      // 超时后自动关闭
      unawaited(
        Future<void>.delayed(timeout).then((_) {
          unawaited(scanSub?.cancel());
          if (!controller.isClosed) {
            unawaited(controller.close());
          }
        }),
      );
    }

    controller
      ..onListen = startScan
      ..onCancel = () {
        unawaited(scanSub?.cancel());
        unawaited(FlutterBluePlus.stopScan());
      };

    return controller.stream;
  }

  /// 停止扫描。
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } on Object catch (e) {
      debugPrint('KoiBleScanner: stopScan error: $e');
    }
  }
}
