import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

int _idCounter = 0;
String _genId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

// ═══════════════════════════════════════════════════════════
// 模板清单库 — 每个模板携带完整的元数据 + Schema + 分组
// 从 JSON 文件异步加载
// ═══════════════════════════════════════════════════════════

List<KoiTemplateManifest> templateManifests = [];

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
