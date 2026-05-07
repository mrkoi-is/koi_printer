/// 连接状态。
/// Represents the current state of a printer connection.
enum KoiConnectionState {
  /// 已断开连接。
  disconnected,

  /// 正在连接。
  connecting,

  /// 已连接 (但尚未匹配服务/特征)。
  connected,

  /// 正在发现服务/特征。
  discovering,

  /// 已就绪 (可以发送指令)。
  ready,

  /// 正在断开连接。
  disconnecting,
}

/// 连接类型。
/// Type of connection to the printer.
enum KoiConnectionType {
  /// BLE (Bluetooth Low Energy)。
  ble,

  /// 经典蓝牙 (SPP)。
  classicBluetooth,

  /// TCP/IP 网络连接。
  network,

  /// USB OTG 连接。
  usb,
}
