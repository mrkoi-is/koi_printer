import 'package:flutter/foundation.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/mixins/editor_manifest_mixin.dart';
import 'package:koi_printer_editor/state/mixins/editor_schema_mixin.dart';

/// 编辑器包装的元素，带有唯一 ID
class EditorElement {
  EditorElement({required this.id, required this.element});
  final String id;
  final KoiTicketElement element;

  EditorElement copyWith({String? id, KoiTicketElement? element}) {
    return EditorElement(
      id: id ?? this.id,
      element: element ?? this.element,
    );
  }
}

/// 编辑器全局状态树
class EditorState extends ChangeNotifier with EditorManifestMixin, EditorSchemaMixin {
  EditorState({
    List<EditorElement>? initialElements,
  }) : _elements = initialElements ?? [];

  List<EditorElement> _elements;
  String? _selectedElementId;

  // 历史栈
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  List<EditorElement> get elements => _elements;
  KoiPrintDocument get document => KoiTicketDocument(elements: _elements.map((e) => e.element).toList());
  String? get selectedElementId => _selectedElementId;
  EditorElement? get selectedElement => _elements.where((e) => e.id == _selectedElementId).firstOrNull;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void loadTemplate(List<EditorElement> templateElements) {
    _elements = templateElements;
    _undoStack.clear();
    _redoStack.clear();
    _selectedElementId = null;
    notifyListeners();
  }

  /// 从 [KoiTemplateManifest] 加载完整模板 (元素 + Schema + 假数据 + 身份)。
  void loadManifest(KoiTemplateManifest manifest, List<EditorElement> elements) {
    _elements = elements;
    _undoStack.clear();
    _redoStack.clear();
    _selectedElementId = null;

    initManifestIdentity(manifest.id, manifest.name, manifest.category, manifest.description);
    initSchemaAndMock(
      manifest.schema, 
      manifest.mockData.isNotEmpty ? Map<String, dynamic>.from(manifest.mockData) : {}
    );

    notifyListeners();
  }

  void updateElements(List<EditorElement> newElements) {
    _elements = newElements;
    notifyListeners();
  }

  void selectElement(String? id) {
    if (_selectedElementId != id) {
      _selectedElementId = id;
      notifyListeners();
    }
  }

  void execute(EditorCommand command) {
    command.execute(this);
    _undoStack.add(command);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (canUndo) {
      final command = _undoStack.removeLast();
      command.undo(this);
      _redoStack.add(command);
      notifyListeners();
    }
  }

  void redo() {
    if (canRedo) {
      final command = _redoStack.removeLast();
      command.execute(this);
      _undoStack.add(command);
      notifyListeners();
    }
  }
}
