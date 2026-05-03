import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

/// 经典蓝牙 (SPP) 设备扫描器 — 通过平台通道获取已配对设备。
/// Classic Bluetooth scanner using platform channels to discover
/// bonded/paired devices.
///
/// 来源: 旧 XIIBluetoothSerialService
class KoiClassicBtScanner {
  static const _channel = MethodChannel('koi_printer_connection/classic_bt');

  /// 扫描已配对的经典蓝牙设备。
  ///
  /// 经典蓝牙通常返回已配对列表 (不像 BLE 需要主动扫描)。
  Stream<KoiDiscoveredDevice> scan({
    Duration timeout = const Duration(seconds: 5),
  }) {
    final controller = StreamController<KoiDiscoveredDevice>();

    Future<void> fetchBondedDevices() async {
      try {
        final result = await _channel.invokeMethod<List<dynamic>>(
          'getBondedDevices',
        );

        if (result != null) {
          for (final device in result) {
            if (device is Map) {
              controller.add(
                KoiDiscoveredDevice(
                  name: (device['name'] as String?) ?? 'Unknown',
                  deviceId: (device['address'] as String?) ?? '',
                  connectionType: KoiConnectionType.classicBluetooth,
                ),
              );
            }
          }
        }
      } on PlatformException catch (e) {
        debugPrint('KoiClassicBtScanner: getBondedDevices error: $e');
      }

      if (!controller.isClosed) controller.close();
    }

    controller.onListen = () => fetchBondedDevices();

    return controller.stream;
  }

  /// 停止扫描 (经典蓝牙配对列表是即时返回, 无需取消)。
  Future<void> stopScan() async {}
}
