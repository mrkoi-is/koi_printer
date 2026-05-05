import 'package:flutter/foundation.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_command.dart';

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
class EditorState extends ChangeNotifier {
  EditorState({
    List<EditorElement>? initialElements,
  }) : _elements = initialElements ?? [];

  List<EditorElement> _elements;
  String? _selectedElementId;

  // ── 当前模板元数据 (Issue 4: 记住当前 manifest 的身份) ──
  String _currentManifestId = '';
  String _currentManifestName = '';
  String _currentManifestCategory = '';
  String _currentManifestDescription = '';

  // ── Schema — 直接复用 KoiTemplateField, 不再另造类 (Issue 1) ──
  List<KoiTemplateField> _schema = const [];

  // 历史栈
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  // 预览模式与假数据 (Issue 2: 不再硬编码, 从 manifest 加载)
  bool _isPreviewMode = false;
  Map<String, dynamic> _mockData = {};
  
  // 画布纸张大小 (默认为 80mm 即 380px)
  double _paperWidthPx = 380.0;

  List<EditorElement> get elements => _elements;
  KoiPrintDocument get document => KoiTicketDocument(elements: _elements.map((e) => e.element).toList());
  String? get selectedElementId => _selectedElementId;
  EditorElement? get selectedElement => _elements.where((e) => e.id == _selectedElementId).firstOrNull;
  bool get isPreviewMode => _isPreviewMode;
  Map<String, dynamic> get mockData => _mockData;
  double get paperWidthPx => _paperWidthPx;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  // ── Schema 公开 API (替代旧的 DataSchema) ──

  /// 当前模板的 Schema 字段列表。
  List<KoiTemplateField> get schema => _schema;

  /// Schema 所属实体名 (用于左面板 "单据模型: xxx" 显示)。
  String get schemaEntity => _currentManifestName;

  /// 当前模板标识 (用于导出时回填)。
  String get currentManifestId => _currentManifestId;

  /// 当前模板名称 (用于导出时回填)。
  String get currentManifestName => _currentManifestName;

  /// 当前模板分类
  String get currentManifestCategory => _currentManifestCategory;

  /// 当前模板描述
  String get currentManifestDescription => _currentManifestDescription;

  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

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

    // 同步身份 (Issue 4)
    _currentManifestId = manifest.id;
    _currentManifestName = manifest.name;
    _currentManifestCategory = manifest.category;
    _currentManifestDescription = manifest.description;

    // 同步 Schema (Issue 1: 直接赋值, 无需转换)
    _schema = manifest.schema;

    // 同步假数据 (Issue 2: 从 manifest 获取, 不再硬编码)
    _mockData = manifest.mockData.isNotEmpty
        ? Map<String, dynamic>.from(manifest.mockData)
        : {};

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

  void updateSchema(List<KoiTemplateField> schema) {
    _schema = schema;
    notifyListeners();
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

  // ── 外部状态变更接口 (UI 交互层使用) ──

  void updatePaperWidthPx(double widthPx) {
    _paperWidthPx = widthPx;
    notifyListeners();
  }

  void updateManifestMetadata({
    String? id,
    String? name,
    String? category,
    String? description,
  }) {
    if (id != null) _currentManifestId = id;
    if (name != null) _currentManifestName = name;
    if (category != null) _currentManifestCategory = category;
    if (description != null) _currentManifestDescription = description;
    notifyListeners();
  }

  void updateMockData(Map<String, dynamic> data) {
    _mockData = data;
    notifyListeners();
  }

  void addSchemaField(KoiTemplateField field) {
    _schema = List.from(_schema)..add(field);
    notifyListeners();
  }

  void updateSchemaField(int index, KoiTemplateField field) {
    if (index >= 0 && index < _schema.length) {
      final newList = List<KoiTemplateField>.from(_schema);
      newList[index] = field;
      _schema = newList;
      notifyListeners();
    }
  }

  void removeSchemaField(int index) {
    if (index >= 0 && index < _schema.length) {
      final newList = List<KoiTemplateField>.from(_schema);
      newList.removeAt(index);
      _schema = newList;
      notifyListeners();
    }
  }
}

