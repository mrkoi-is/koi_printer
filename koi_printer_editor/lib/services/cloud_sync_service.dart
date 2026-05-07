import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudSyncService {
  static const String _kCloudTemplatesKey = 'koi_editor_cloud_templates';

  // 获取云端模板列表
  Future<List<KoiTemplateManifest>> fetchCloudTemplates() async {
    await Future.delayed(const Duration(milliseconds: 800)); // 模拟网络延迟
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(_kCloudTemplatesKey);

    if (jsonStringList == null || jsonStringList.isEmpty) {
      return [];
    }

    try {
      return jsonStringList.map((str) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        return KoiTemplateManifest.fromJson(map);
      }).toList();
    } catch (e) {
      debugPrint('Failed to parse cloud templates: $e');
      return [];
    }
  }

  // 上传模板到云端
  Future<void> uploadTemplate(KoiTemplateManifest manifest) async {
    await Future.delayed(const Duration(milliseconds: 600)); // 模拟网络延迟
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(_kCloudTemplatesKey) ?? [];

    // 解析已有的列表，检查是否存在同 ID 模板，覆盖或追加
    final List<Map<String, dynamic>> existing = [];
    for (final str in jsonStringList) {
      try {
        existing.add(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {}
    }

    final index = existing.indexWhere((m) => m['id'] == manifest.id);
    final newManifestJson = manifest.toJson();
    if (index >= 0) {
      existing[index] = newManifestJson;
    } else {
      existing.add(newManifestJson);
    }

    await prefs.setStringList(
      _kCloudTemplatesKey,
      existing.map((m) => jsonEncode(m)).toList(),
    );
  }

  // 从云端删除模板
  Future<void> deleteTemplate(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final prefs = await SharedPreferences.getInstance();
    final jsonStringList = prefs.getStringList(_kCloudTemplatesKey) ?? [];

    final List<Map<String, dynamic>> existing = [];
    for (final str in jsonStringList) {
      try {
        existing.add(jsonDecode(str) as Map<String, dynamic>);
      } catch (_) {}
    }

    existing.removeWhere((m) => m['id'] == id);

    await prefs.setStringList(
      _kCloudTemplatesKey,
      existing.map((m) => jsonEncode(m)).toList(),
    );
  }
}
