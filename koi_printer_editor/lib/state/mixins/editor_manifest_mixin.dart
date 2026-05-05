import 'package:flutter/foundation.dart';

mixin EditorManifestMixin on ChangeNotifier {
  String _currentManifestId = '';
  String _currentManifestName = '';
  String _currentManifestCategory = '';
  String _currentManifestDescription = '';
  double _paperWidthPx = 380.0;

  String get currentManifestId => _currentManifestId;
  String get currentManifestName => _currentManifestName;
  String get currentManifestCategory => _currentManifestCategory;
  String get currentManifestDescription => _currentManifestDescription;
  double get paperWidthPx => _paperWidthPx;

  /// Schema 所属实体名 (用于左面板 "单据模型: xxx" 显示)。
  String get schemaEntity => _currentManifestName;

  void initManifestIdentity(String id, String name, String category, String description) {
    _currentManifestId = id;
    _currentManifestName = name;
    _currentManifestCategory = category;
    _currentManifestDescription = description;
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

  void updatePaperWidthPx(double widthPx) {
    _paperWidthPx = widthPx;
    notifyListeners();
  }
}
