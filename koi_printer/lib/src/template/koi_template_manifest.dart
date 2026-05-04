import 'dart:convert';

import 'package:koi_printer_command/koi_printer_command.dart';

/// 模板字段 Schema — 声明模板期望接收的变量。
/// Declares the variables a template expects from the caller.
///
/// 使用示例:
/// ```dart
/// KoiTemplateField(key: 'ticketSn', label: '运单号', type: KoiFieldType.string)
/// ```
class KoiTemplateField {
  /// 创建一个模板字段。
  const KoiTemplateField({
    required this.key,
    required this.label,
    this.type = KoiFieldType.string,
  });

  /// 变量 key (对应 {{key}} 占位符)。
  final String key;

  /// 人类可读标签 (用于编辑器 UI 展示)。
  final String label;

  /// 字段类型。
  final KoiFieldType type;
}

/// 字段类型枚举。
enum KoiFieldType {
  /// 普通文本。
  string,

  /// 数字。
  number,

  /// 数组 (用于 ForEach 循环)。
  array,
}

/// 元素分组 — 为编辑器提供业务语义化分区。
/// Groups consecutive elements into named business sections for the editor UI.
///
/// 例如: "收发件人信息" 包含索引 [8, 9, 10] 的三个元素。
class KoiTemplateGroup {
  /// 创建一个模板元素分组。
  const KoiTemplateGroup({
    required this.label,
    required this.startIndex,
    required this.endIndex,
  });

  /// 分组名称 (如 "收发件人信息", "费用明细")。
  final String label;

  /// 在 document.elements 中的起始索引 (含)。
  final int startIndex;

  /// 在 document.elements 中的结束索引 (含)。
  final int endIndex;
}

/// 模板清单 — 包装 [KoiPrintDocument] + 元数据 + Schema。
/// Template manifest that wraps a print document with metadata, schema,
/// and element grouping for the visual editor.
///
/// 这是编辑器导出和加载的 **信封格式 (Envelope Format)**:
/// - `document` 字段是标准的 [KoiPrintDocument], 底层完全不变
/// - 外层增加了业务语义 (名称、分类、Schema、分组)
///
/// 使用示例:
/// ```dart
/// final manifest = KoiTemplateManifest(
///   id: 'tms_sender_v1',
///   name: '寄件客户联',
///   category: 'tms',
///   document: myTicketDocument,
///   schema: [
///     KoiTemplateField(key: 'ticketSn', label: '运单号'),
///     KoiTemplateField(key: 'items', label: '费用列表', type: KoiFieldType.array),
///   ],
///   groups: [
///     KoiTemplateGroup(label: '标题区', startIndex: 0, endIndex: 3),
///   ],
/// );
///
/// // 序列化
/// final jsonStr = manifest.toJsonString();
///
/// // 反序列化
/// final restored = KoiTemplateManifest.fromJsonString(jsonStr);
/// ```
class KoiTemplateManifest {
  /// 创建一个模板清单。
  const KoiTemplateManifest({
    required this.id,
    required this.name,
    required this.document,
    this.version = 1,
    this.category = '',
    this.description = '',
    this.schema = const [],
    this.groups = const [],
    this.mockData = const {},
  });

  /// 从 JSON Map 反序列化。
  factory KoiTemplateManifest.fromJson(Map<String, dynamic> json) {
    return KoiTemplateManifest(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      version: json['version'] as int? ?? 1,
      category: json['category'] as String? ?? '',
      description: json['description'] as String? ?? '',
      document: _parseDocument(json['document']),
      schema: (json['schema'] as List?)
              ?.map((e) => _fieldFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      groups: (json['groups'] as List?)
              ?.map((e) => _groupFromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mockData: (json['mockData'] as Map<String, dynamic>?) ?? {},
    );
  }

  /// 从 JSON 字符串反序列化。
  factory KoiTemplateManifest.fromJsonString(String source) {
    return KoiTemplateManifest.fromJson(
      jsonDecode(source) as Map<String, dynamic>,
    );
  }

  /// 模板唯一标识符。
  final String id;

  /// 模板名称 (人类可读)。
  final String name;

  /// 版本号。
  final int version;

  /// 分类标签 (如 'tms_sender', 'finance', 'payment')。
  final String category;

  /// 模板描述。
  final String description;

  /// 底层打印文档 (标准 KoiPrintDocument, 不做任何修改)。
  final KoiPrintDocument document;

  /// 模板期望的变量 Schema。
  final List<KoiTemplateField> schema;

  /// 元素的业务分组 (纯 UI 层, 不影响底层打印逻辑)。
  final List<KoiTemplateGroup> groups;

  /// 示例数据 (用于编辑器预览模式)。
  final Map<String, dynamic> mockData;

  // ═══════════════════════════════════════════════════════════
  // 序列化
  // ═══════════════════════════════════════════════════════════

  /// 序列化为 Map。
  Map<String, dynamic> toJson() => {
    'manifestVersion': 1,
    'id': id,
    'name': name,
    'version': version,
    if (category.isNotEmpty) 'category': category,
    if (description.isNotEmpty) 'description': description,
    'schema': schema.map(_fieldToJson).toList(),
    if (groups.isNotEmpty) 'groups': groups.map(_groupToJson).toList(),
    if (mockData.isNotEmpty) 'mockData': mockData,
    'document': document.toJson(),
  };

  /// 序列化为格式化的 JSON 字符串。
  String toJsonString() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  // ═══════════════════════════════════════════════════════════
  // 内部: Schema 字段序列化
  // ═══════════════════════════════════════════════════════════

  static Map<String, dynamic> _fieldToJson(KoiTemplateField f) => {
    'key': f.key,
    'label': f.label,
    if (f.type != KoiFieldType.string) 'type': f.type.name,
  };

  static KoiTemplateField _fieldFromJson(Map<String, dynamic> j) =>
      KoiTemplateField(
        key: j['key'] as String,
        label: j['label'] as String? ?? j['key'] as String,
        type: _parseFieldType(j['type'] as String?),
      );

  static KoiFieldType _parseFieldType(String? value) {
    if (value == null) return KoiFieldType.string;
    for (final t in KoiFieldType.values) {
      if (t.name == value) return t;
    }
    return KoiFieldType.string;
  }

  // ═══════════════════════════════════════════════════════════
  // 内部: 分组序列化
  // ═══════════════════════════════════════════════════════════

  static Map<String, dynamic> _groupToJson(KoiTemplateGroup g) => {
    'label': g.label,
    'startIndex': g.startIndex,
    'endIndex': g.endIndex,
  };

  static KoiTemplateGroup _groupFromJson(Map<String, dynamic> j) =>
      KoiTemplateGroup(
        label: j['label'] as String,
        startIndex: j['startIndex'] as int,
        endIndex: j['endIndex'] as int,
      );

  static KoiPrintDocument _parseDocument(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'KoiTemplateManifest: 缺少或无效的 "document" 字段',
      );
    }
    return koiPrintDocumentFromJson(value);
  }
}
