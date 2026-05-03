import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

/// 经典蓝牙 (SPP) 设备扫描器 — 获取已配对设备。
class KoiClassicBtScanner {
  /// 扫描已配对的经典蓝牙设备。
  ///
  /// 经典蓝牙通常返回已配对列表 (不像 BLE 需要主动扫描)。
  Stream<KoiDiscoveredDevice> scan({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final controller = StreamController<KoiDiscoveredDevice>();

    Future<void> fetchBondedDevices() async {
      try {
        final devices =
            await FlutterBluetoothSerial.instance.getBondedDevices();

        for (final device in devices) {
          controller.add(
            KoiDiscoveredDevice(
              name: device.name ?? 'Unknown',
              deviceId: device.address,
              connectionType: KoiConnectionType.classicBluetooth,
            ),
          );
        }
      } catch (e) {
        debugPrint('KoiClassicBtScanner: getBondedDevices error: $e');
      }

      if (!controller.isClosed) controller.close();
    }

    controller.onListen = fetchBondedDevices;

    return controller.stream;
  }

  /// 停止扫描 (经典蓝牙配对列表是即时返回, 无需取消)。
  Future<void> stopScan() async {}
}
