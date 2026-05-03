import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// 打印机硬件状态。
enum KoiPrinterHardwareState {
  /// 就绪 (正常)。
  ready,

  /// 缺纸。
  outOfPaper,

  /// 纸仓开盖。
  coverOpen,

  /// 过热。
  overheated,

  /// 未知状态。
  unknown,
}

/// 打印机连接适配器接口。
/// Adapter interface for printer connections.
///
/// 实现:
/// - KoiBleAdapter — BLE (Bluetooth Low Energy)
/// - KoiNetworkAdapter — TCP/IP 网络
/// - KoiClassicBtAdapter — 经典蓝牙 SPP
/// - KoiUsbAdapter — USB
abstract interface class KoiPrinterAdapter {
  /// 当前连接状态。
  KoiConnectionState get state;

  /// 连接状态流。
  Stream<KoiConnectionState> get stateStream;

  /// 打印机硬件状态流 (缺纸/开盖/过热等)。
  Stream<KoiPrinterHardwareState> get hardwareStateStream;

  /// 连接类型。
  KoiConnectionType get connectionType;

  /// 当前连接配置。
  KoiConnectionConfig? get config;

  /// 连接策略。
  KoiConnectionPolicy get policy;

  /// 连接到打印机。
  Future<bool> connect(KoiConnectionConfig config);

  /// 断开连接。
  Future<void> disconnect();

  /// 发送指令块。
  ///
  /// [chunks] 是协议层的逻辑分块 (来自 KoiCommandRenderer.render)。
  /// BLE 实现会进一步按 MTU 分块。
  Future<void> sendChunks(List<List<int>> chunks);

  /// 主动查询打印机硬件状态 (会发送 ESC/POS 状态查询指令)。
  Future<KoiPrinterHardwareState> queryHardwareState();

  /// 是否已连接并就绪。
  bool get isReady;

  /// 释放资源。
  Future<void> dispose();
}
