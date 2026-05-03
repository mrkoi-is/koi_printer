/// koi_printer_connection — 打印机连接适配器。
///
/// 提供统一的 [KoiPrinterAdapter] 接口, 支持:
/// - BLE (Bluetooth Low Energy) → [KoiBleAdapter]
/// - TCP/IP 网络 → [KoiNetworkAdapter]
///
/// 以及设备扫描: [KoiBleScanner]
library;

import 'package:koi_printer_connection/koi_printer_connection.dart'
    show KoiBleAdapter, KoiBleScanner, KoiNetworkAdapter, KoiPrinterAdapter;

// 适配器
export 'src/adapter/koi_ble_adapter.dart';
export 'src/adapter/koi_classic_bt_adapter.dart';
export 'src/adapter/koi_network_adapter.dart';
export 'src/adapter/koi_printer_adapter.dart';
// 模型
export 'src/model/koi_connection_config.dart';
// 策略
export 'src/model/koi_connection_policy.dart';
export 'src/model/koi_connection_types.dart';
export 'src/model/koi_discovered_device.dart';
// 扫描器
export 'src/scanner/koi_ble_scanner.dart';
export 'src/scanner/koi_classic_bt_scanner.dart';
export 'src/scanner/koi_keyboard_scanner.dart';
export 'src/scanner/koi_network_scanner.dart';
