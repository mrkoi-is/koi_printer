import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

int _idCounter = 0;
String _genId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

// ═══════════════════════════════════════════════════════════
// 模板清单库 — 每个模板携带完整的元数据 + Schema + 分组
// 从 JSON 文件异步加载，初始化后不可再篡改引用
// ═══════════════════════════════════════════════════════════

/// 模板注册表，确保初始化一次后不会被意外清空或覆盖。
class TemplateRegistry {
  TemplateRegistry._();
  static final TemplateRegistry instance = TemplateRegistry._();

  List<KoiTemplateManifest>? _manifests;
  bool get isInitialized => _manifests != null;

  /// 初始化模板列表，仅允许调用一次。
  /// 第二次调用会被静默忽略（幂等安全）。
  void initialize(List<KoiTemplateManifest> manifests) {
    _manifests ??= List.unmodifiable(manifests);
  }

  /// 获取所有模板（未初始化时返回空列表，不会抛异常）。
  List<KoiTemplateManifest> get manifests => _manifests ?? const [];

  /// 仅用于测试：重置注册表，允许重新初始化。
  void resetForTesting() {
    _manifests = null;
  }
}

/// 便捷访问器 — 保持外部调用代码的简洁性。
List<KoiTemplateManifest> get templateManifests => TemplateRegistry.instance.manifests;

/// 将 Manifest 的 document.elements 转换为编辑器可用的 EditorElement 列表。
List<EditorElement> manifestToEditorElements(KoiTemplateManifest manifest) {
  final doc = manifest.document;
  if (doc is KoiTicketDocument) {
    return doc.elements.map((e) => EditorElement(id: _genId(), element: e)).toList();
  } else if (doc is KoiLabelDocument) {
    return doc.elements.map((e) => EditorElement(id: _genId(), element: e)).toList();
  }
  return [];
}

/// 默认加载的模板 (通常是列表的第一个)。
KoiTemplateManifest? get defaultManifest => templateManifests.isNotEmpty ? templateManifests.first : null;
List<EditorElement> get defaultTemplateElements => defaultManifest != null ? manifestToEditorElements(defaultManifest!) : [];
