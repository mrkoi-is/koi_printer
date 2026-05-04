import 'package:flutter/foundation.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
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

/// 数据字典 Schema
class DataSchema {
  DataSchema({this.entity = '', this.fields = const []});
  final String entity;
  final List<SchemaField> fields;
}

class SchemaField {
  SchemaField({required this.key, required this.label, required this.type});
  final String key;
  final String label;
  final String type; // string, number, array
}

/// 编辑器全局状态树
class EditorState extends ChangeNotifier {
  EditorState({
    List<EditorElement>? initialElements,
  }) : _elements = initialElements ?? [];

  List<EditorElement> _elements;
  String? _selectedElementId;
  DataSchema _currentSchema = DataSchema(
    entity: 'SenderTicket',
    fields: [
      SchemaField(key: 'waybillNo', label: '运单号', type: 'string'),
      SchemaField(key: 'fee.total', label: '总运费', type: 'number'),
      SchemaField(key: 'items', label: '商品列表', type: 'array'),
    ],
  );

  // 历史栈
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  // 预览模式与假数据
  bool _isPreviewMode = false;
  final Map<String, dynamic> _mockData = {
    'waybillNo': 'SF123456789',
    'fee': {'total': 188.0},
    'items': [
      {'name': 'Koi 机械键盘', 'qty': 1, 'price': 99.0},
      {'name': 'Koi 鼠标', 'qty': 2, 'price': 44.5},
    ],
  };

  List<EditorElement> get elements => _elements;
  KoiPrintDocument get document => KoiTicketDocument(elements: _elements.map((e) => e.element).toList());
  String? get selectedElementId => _selectedElementId;
  EditorElement? get selectedElement => _elements.where((e) => e.id == _selectedElementId).firstOrNull;
  DataSchema get currentSchema => _currentSchema;
  bool get isPreviewMode => _isPreviewMode;
  Map<String, dynamic> get mockData => _mockData;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

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

  void updateSchema(DataSchema schema) {
    _currentSchema = schema;
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
}
