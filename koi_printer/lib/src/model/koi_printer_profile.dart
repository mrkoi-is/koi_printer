import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

/// 打印机能力数据库 — 型号→能力映射。
/// Printer capability profile database — maps printer model to its
/// supported features (protocols, connections, best QR strategy, etc.).
///
/// 来源: 旧 XIIPrinterProfile + 架构文档 §9
///
/// 使用方式:
/// ```dart
/// final db = KoiPrinterProfileDb();
/// await db.load();
/// final profile = db.findByName('芯烨 XT-423');
/// final strategy = profile?.bestQrStrategy ?? KoiQrRenderStrategy.normal;
/// ```
class KoiPrinterProfile {
  /// Constant constructor.
  const KoiPrinterProfile({
    required this.id,
    required this.name,
    required this.vendor,
    required this.protocols,
    required this.connections,
    this.paperWidthMm = 80,
    this.dotsPerLine = 576,
    this.dpi = 203,
    this.supportsCut = true,
    this.supportsQrCode = true,
    this.bestQrStrategy = KoiQrRenderStrategy.normal,
    this.supportsChinese = true,
    this.characteristicFilter,
    this.maxMtu,
    this.delayProfile = KoiDelayProfile.normal,
  });

  /// Field.
  final String id;
  /// Field.
  final String name;
  /// Field.
  final String vendor;
  /// Field.
  final List<KoiCommandProtocol> protocols;
  /// Field.
  final List<KoiConnectionType> connections;
  /// Field.
  final int paperWidthMm;
  /// Field.
  final int dotsPerLine;
  /// Field.
  final int dpi;
  /// Field.
  final bool supportsCut;
  /// Field.
  final bool supportsQrCode;
  /// Field.
  final KoiQrRenderStrategy bestQrStrategy;
  /// Field.
  final bool supportsChinese;
  /// Field.
  final String? characteristicFilter;
  /// Field.
  final int? maxMtu;
  /// Field.
  final KoiDelayProfile delayProfile;

  /// Method.
  factory KoiPrinterProfile.fromJson(Map<String, dynamic> j) {
    return KoiPrinterProfile(
      id: j['id'] as String,
      name: j['name'] as String,
      vendor: j['vendor'] as String? ?? '',
      protocols: (j['protocols'] as List? ?? [])
          .map((e) => KoiCommandProtocol.values.byName(e as String))
          .toList(),
      connections: (j['connections'] as List? ?? [])
          .map((e) => KoiConnectionType.values.byName(e as String))
          .toList(),
      paperWidthMm: j['paperWidthMm'] as int? ?? 80,
      dotsPerLine: j['dotsPerLine'] as int? ?? 576,
      dpi: j['dpi'] as int? ?? 203,
      supportsCut: j['supportsCut'] as bool? ?? true,
      supportsQrCode: j['supportsQrCode'] as bool? ?? true,
      bestQrStrategy: _parseStrategy(j['bestQrStrategy']),
      supportsChinese: j['supportsChinese'] as bool? ?? true,
      characteristicFilter: j['characteristicFilter'] as String?,
      maxMtu: j['maxMtu'] as int?,
      delayProfile: _parseDelay(j['delayProfile']),
    );
  }

  /// Method.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'vendor': vendor,
    'protocols': protocols.map((e) => e.name).toList(),
    'connections': connections.map((e) => e.name).toList(),
    'paperWidthMm': paperWidthMm,
    'dotsPerLine': dotsPerLine,
    'dpi': dpi,
    'supportsCut': supportsCut,
    'supportsQrCode': supportsQrCode,
    'bestQrStrategy': bestQrStrategy.name,
    'supportsChinese': supportsChinese,
    if (characteristicFilter != null)
      'characteristicFilter': characteristicFilter,
    if (maxMtu != null) 'maxMtu': maxMtu,
    'delayProfile': delayProfile.name,
  };

  static KoiQrRenderStrategy _parseStrategy(Object? value) {
    if (value == null) return KoiQrRenderStrategy.normal;
    for (final s in KoiQrRenderStrategy.values) {
      if (s.name == value.toString()) return s;
    }
    return KoiQrRenderStrategy.normal;
  }

  static KoiDelayProfile _parseDelay(Object? value) {
    if (value == null) return KoiDelayProfile.normal;
    for (final d in KoiDelayProfile.values) {
      if (d.name == value.toString()) return d;
    }
    return KoiDelayProfile.normal;
  }
}

/// 打印机能力数据库。
class KoiPrinterProfileDb {
  /// Method.
  KoiPrinterProfileDb();

  final List<KoiPrinterProfile> _profiles = [];

  /// 所有已加载的型号。
  List<KoiPrinterProfile> get profiles => List.unmodifiable(_profiles);

  /// 从 asset 加载内置数据库。
  // coverage:ignore-start
  Future<void> loadFromAsset({
    String path = 'packages/koi_printer/assets/printers.json',
  }) async {
    final source = await rootBundle.loadString(path);
    final list = json.decode(source) as List;
    _profiles
      ..clear()
      ..addAll(
        list
            .map((e) => KoiPrinterProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  }
  // coverage:ignore-end

  /// 从 JSON 字符串加载。
  void loadFromJsonString(String source) {
    final list = json.decode(source) as List;
    _profiles
      ..clear()
      ..addAll(
        list
            .map((e) => KoiPrinterProfile.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
  }

  /// 添加自定义型号。
  void addProfile(KoiPrinterProfile profile) => _profiles.add(profile);

  /// 按 ID 查找。
  KoiPrinterProfile? findById(String id) {
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// 按名称模糊查找。
  KoiPrinterProfile? findByName(String name) {
    final lower = name.toLowerCase();
    for (final p in _profiles) {
      if (p.name.toLowerCase().contains(lower)) return p;
    }
    return null;
  }

  /// 按 BLE 特征 UUID 查找。
  KoiPrinterProfile? findByCharacteristic(String uuid) {
    final lower = uuid.toLowerCase();
    for (final p in _profiles) {
      if (p.characteristicFilter != null &&
          lower.contains(p.characteristicFilter!.toLowerCase())) {
        return p;
      }
    }
    return null;
  }
}
