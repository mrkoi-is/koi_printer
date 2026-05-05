import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';

class KoiTemplateLoader {
  /// 从 package assets 中异步加载所有的 JSON 模板
  static Future<List<KoiTemplateManifest>> loadAllTemplates() async {
    final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    
    // 找出所有的模板 JSON 文件
    // 注意：如果是被其他项目依赖，路径会带有 packages/koi_printer_editor/ 前缀
    // 如果是本包自己运行，路径可能是 assets/templates/
    final templatePaths = manifest.listAssets().where((path) {
      return path.contains('assets/templates/') && path.endsWith('.json');
    }).toList();

    final List<KoiTemplateManifest> templates = [];

    for (final path in templatePaths) {
      try {
        final jsonStr = await rootBundle.loadString(path);
        final manifest = KoiTemplateManifest.fromJsonString(jsonStr);
        templates.add(manifest);
      } catch (e) {
        debugPrint('Error loading template $path: $e');
      }
    }

    return templates;
  }
}
