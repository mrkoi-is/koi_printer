import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// 扫描到的设备信息。
/// Represents a discovered printer device.
class KoiDiscoveredDevice {
  const KoiDiscoveredDevice({
    required this.name,
    required this.deviceId,
    required this.connectionType,
    this.rssi,
    this.config,
  });

  /// 设备名称。
  final String name;

  /// 设备标识。
  final String deviceId;

  /// 连接类型。
  final KoiConnectionType connectionType;

  /// 信号强度 (仅用于蓝牙)。
  final int? rssi;

  /// 预配置信息 (如已知的 service/characteristic UUID)。
  final KoiConnectionConfig? config;

  @override
  String toString() =>
      'KoiDiscoveredDevice('
      'name: $name, '
      'id: $deviceId, '
      'type: $connectionType'
      ')';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KoiDiscoveredDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}
