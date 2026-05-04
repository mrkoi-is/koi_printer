import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 打印机设备信息 — 用于持久化已绑定的设备。
/// 来源: 旧 XIIDeviceInfo
class KoiDeviceInfo {
  const KoiDeviceInfo({
    required this.name,
    required this.address,
    required this.connectionType,
  });

  factory KoiDeviceInfo.fromMap(Map<String, dynamic> map) {
    return KoiDeviceInfo(
      name: map['name'] as String,
      address: map['address'] as String,
      connectionType:
          KoiConnectionType.values[map['connectionType'] as int? ?? 0],
    );
  }

  factory KoiDeviceInfo.fromJson(String source) =>
      KoiDeviceInfo.fromMap(json.decode(source) as Map<String, dynamic>);

  /// 设备名称。
  final String name;

  /// 设备地址 (BLE UUID / MAC / IP:Port)。
  final String address;

  /// 连接类型。
  final KoiConnectionType connectionType;

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'connectionType': connectionType.index,
  };

  String toJson() => json.encode(toMap());
}

/// 打印机存储 — 持久化已绑定设备 + 设备配置。
/// 来源: 旧 XIIPrinterStorage (216 LOC, Singleton)
/// 改进: 构造函数注入 SharedPreferences (无 Singleton)。
class KoiPrinterStorage {
  KoiPrinterStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _ticketKey = 'koi_bind_ticket_printer';
  static const _labelKey = 'koi_bind_label_printer';

  // ── 小票打印机绑定 ──

  /// 保存小票打印机信息。
  Future<bool> saveTicketPrinter(KoiDeviceInfo? device) async {
    if (device == null) {
      return _prefs.remove(_ticketKey);
    }
    return _prefs.setString(_ticketKey, device.toJson());
  }

  /// 读取已绑定的小票打印机。
  KoiDeviceInfo? getTicketPrinter() {
    final json = _prefs.getString(_ticketKey);
    if (json == null) return null;
    try {
      return KoiDeviceInfo.fromJson(json);
    } on Object catch (e) {
      debugPrint('KoiPrinterStorage: parse ticket printer error: $e');
      return null;
    }
  }

  // ── 标签打印机绑定 ──

  /// 保存标签打印机信息。
  Future<bool> saveLabelPrinter(KoiDeviceInfo? device) async {
    if (device == null) {
      return _prefs.remove(_labelKey);
    }
    return _prefs.setString(_labelKey, device.toJson());
  }

  /// 读取已绑定的标签打印机。
  KoiDeviceInfo? getLabelPrinter() {
    final json = _prefs.getString(_labelKey);
    if (json == null) return null;
    try {
      return KoiDeviceInfo.fromJson(json);
    } on Object catch (e) {
      debugPrint('KoiPrinterStorage: parse label printer error: $e');
      return null;
    }
  }
}
