import 'package:flutter/foundation.dart';
import 'package:koi_printer/koi_printer.dart';

mixin EditorSchemaMixin on ChangeNotifier {
  List<KoiTemplateField> _schema = const [];
  Map<String, dynamic> _mockData = {};
  bool _isPreviewMode = false;

  List<KoiTemplateField> get schema => _schema;
  Map<String, dynamic> get mockData => _mockData;
  bool get isPreviewMode => _isPreviewMode;

  void initSchemaAndMock(List<KoiTemplateField> newSchema, Map<String, dynamic> newMockData) {
    _schema = newSchema;
    _mockData = newMockData;
  }

  void togglePreviewMode() {
    _isPreviewMode = !_isPreviewMode;
    notifyListeners();
  }

  void updateMockData(Map<String, dynamic> data) {
    _mockData = data;
    notifyListeners();
  }

  void updateSchema(List<KoiTemplateField> schema) {
    _schema = schema;
    notifyListeners();
  }

  void addSchemaField(KoiTemplateField field) {
    if (_schema.any((e) => e.key == field.key)) {
      throw Exception('字段 Key "${field.key}" 已存在');
    }
    _schema = List<KoiTemplateField>.from(_schema)..add(field);
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
