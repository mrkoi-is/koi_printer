/// 连接配置。
/// Configuration for establishing a printer connection.
class KoiConnectionConfig {
  /// Documentation for this public member.
  const KoiConnectionConfig({
    required this.deviceName,
    required this.deviceId,
    this.mtu = 512,
    this.serviceUuid,
    this.characteristicUuid,
    this.host,
    this.port = 9100,
    this.autoReconnect = false,
    this.connectionTimeout = const Duration(seconds: 5),
  });

  /// 设备名称。
  final String deviceName;

  /// 设备地址 (BLE: UUID, Classic BT: MAC, Network: host:port)。
  final String deviceId;

  /// MTU (Maximum Transmission Unit) — BLE 分块大小。
  final int mtu;

  /// BLE 服务 UUID。
  final String? serviceUuid;

  /// BLE 特征 UUID。
  final String? characteristicUuid;

  /// 网络打印机主机地址。
  final String? host;

  /// 网络打印机端口 (默认 9100)。
  final int port;

  /// 是否自动重连。
  final bool autoReconnect;

  /// 连接超时时间。
  final Duration connectionTimeout;

  /// Documentation for this public member.
  KoiConnectionConfig copyWith({
    String? deviceName,
    String? deviceId,
    int? mtu,
    String? serviceUuid,
    String? characteristicUuid,
    String? host,
    int? port,
    bool? autoReconnect,
    Duration? connectionTimeout,
  }) {
    return KoiConnectionConfig(
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      mtu: mtu ?? this.mtu,
      serviceUuid: serviceUuid ?? this.serviceUuid,
      characteristicUuid: characteristicUuid ?? this.characteristicUuid,
      host: host ?? this.host,
      port: port ?? this.port,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
    );
  }
}
