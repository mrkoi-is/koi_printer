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
      SchemaField(key: 'companyName', label: '公司名称', type: 'string'),
      SchemaField(key: 'companyAdv', label: '宣传语', type: 'string'),
      SchemaField(key: 'fromNodeInfo', label: '发件网点', type: 'string'),
      SchemaField(key: 'toNodeInfo', label: '目的网点', type: 'string'),
      SchemaField(key: 'ticketSn', label: '运单号', type: 'string'),
      SchemaField(key: 'sequnceId', label: '流水号', type: 'string'),
      SchemaField(key: 'operatorName', label: '操作员', type: 'string'),
      SchemaField(key: 'startDate', label: '开单时间', type: 'string'),
      SchemaField(key: 'recieverName', label: '收件人', type: 'string'),
      SchemaField(key: 'recieverPhone', label: '收件电话', type: 'string'),
      SchemaField(key: 'senderInfo', label: '发件人', type: 'string'),
      SchemaField(key: 'senderPhone', label: '发件电话', type: 'string'),
      SchemaField(key: 'weight', label: '重量', type: 'string'),
      SchemaField(key: 'volume', label: '体积', type: 'string'),
      SchemaField(key: 'cargoInfo', label: '品名', type: 'string'),
      SchemaField(key: 'cargoCount', label: '件数', type: 'string'),
      SchemaField(key: 'totalFee', label: '总运费', type: 'string'),
      SchemaField(key: 'behalfFee', label: '代收货款', type: 'string'),
      SchemaField(key: 'remark', label: '备注', type: 'string'),
      SchemaField(key: 'items', label: '商品/单据列表', type: 'array'),
    ],
  );

  // 历史栈
  final List<EditorCommand> _undoStack = [];
  final List<EditorCommand> _redoStack = [];

  // 预览模式与假数据
  bool _isPreviewMode = false;
  Map<String, dynamic> _mockData = {
    'companyName': '顺丰速运 (SF Express)',
    'companyAdv': '一站式供应链解决方案提供商',
    'fromNodeInfo': '深圳南山科技园网点',
    'toNodeInfo': '北京朝阳国贸网点',
    'ticketSn': 'SF1234567890123',
    'sequnceId': '0001',
    'operatorName': '张三丰',
    'startDate': '2026-05-04 12:00:00',
    'recieverName': '李四',
    'pickMethod': '派送',
    'recieverPhone': '138****8000',
    'senderInfo': '王五',
    'senderPhone': '139****9000',
    'weight': '2.5',
    'volume': '0.01',
    'cargoInfo': '电子产品',
    'cargoCount': '1',
    'freightFee': '18.00',
    'preFreightFee': '18.00',
    'settlementMethod': '现付',
    'pickFee': '0.00',
    'psFee': '0.00',
    'totalFee': '18.00',
    'behalfFee': '0.00',
    'remark': '易碎物品，请轻拿轻放',
    // 财务模板需要的数据
    'nodeInfo': '深圳高新园财务中心',
    'bizerName': '李四',
    'handUser': '王五',
    'handDate': '2026-05-04 18:00',
    'totalAmount': '¥ 50,000',
    // 请款模板需要的数据
    'requestUser': '赵六',
    'requestAmount': '¥ 5,000.00',
    'reason': '采购新一批打印纸和碳带',
    'items': [
      {'name': '顺丰特快', 'qty': 1, 'price': 18.0, 'count': 100, 'amount': '¥1,800'},
      {'name': '顺丰标快', 'qty': 2, 'price': 12.0, 'count': 500, 'amount': '¥6,000'},
      {'name': '包装费', 'qty': 1, 'price': 5.0, 'count': 100, 'amount': '¥500'},
    ]
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

  /// 从 [KoiTemplateManifest] 加载完整模板 (元素 + Schema + 假数据)。
  void loadManifest(KoiTemplateManifest manifest, List<EditorElement> elements) {
    _elements = elements;
    _undoStack.clear();
    _redoStack.clear();
    _selectedElementId = null;

    // 同步 Schema
    if (manifest.schema.isNotEmpty) {
      _currentSchema = DataSchema(
        entity: manifest.name,
        fields: manifest.schema.map((f) => SchemaField(
          key: f.key,
          label: f.label,
          type: f.type.name,
        )).toList(),
      );
    }

    // 同步假数据
    if (manifest.mockData.isNotEmpty) {
      _mockData = Map<String, dynamic>.from(manifest.mockData);
    }

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
