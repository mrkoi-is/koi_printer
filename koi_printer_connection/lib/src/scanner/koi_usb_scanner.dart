import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

/// USB 打印机扫描器 — 平台通道桥接。
///
/// USB 打印机发现高度依赖平台 (Android USB Host API / iOS 不支持)。
/// 当前实现提供框架, 需要平台通道实现才能工作。
class KoiUsbScanner {
  /// 扫描 USB 打印机。
  ///
  /// 在 Android 上委托到 USB Host API。
  /// 在 iOS / macOS 上暂不支持 USB 打印。
  Stream<KoiDiscoveredDevice> scan() {
    final controller = StreamController<KoiDiscoveredDevice>();

    // TODO(maxlee): 接入平台通道获取 USB 设备列表。
    // Android: 通过 UsbManager.getDeviceList() 筛选打印机 class
    // 暂返回空流。
    debugPrint(
      'KoiUsbScanner: USB scanning requires platform channel. '
      'Returning empty stream.',
    );
    Future<void>.delayed(const Duration(milliseconds: 100)).then((_) {
      if (!controller.isClosed) controller.close();
    });

    return controller.stream;
  }

  /// 停止扫描。
  Future<void> stopScan() async {
    // USB 扫描是即时的, 无需取消。
  }
}
