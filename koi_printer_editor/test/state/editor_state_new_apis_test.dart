import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

/// T1: 覆盖 EditorState 新增的所有 API 方法。
void main() {
  group('updatePaperWidthPx', () {
    test('更新画布宽度', () {
      final state = EditorState();
      expect(state.paperWidthPx, 380.0);

      state.updatePaperWidthPx(280.0);
      expect(state.paperWidthPx, 280.0);
    });
  });

  group('updateManifestMetadata', () {
    test('部分更新 — 只传 id 和 name', () {
      final state = EditorState();
      state.updateManifestMetadata(id: 'abc', name: '测试');
      expect(state.currentManifestId, 'abc');
      expect(state.currentManifestName, '测试');
      // 其余字段保持默认
      expect(state.currentManifestCategory, '');
      expect(state.currentManifestDescription, '');
    });

    test('完整更新所有字段', () {
      final state = EditorState();
      state.updateManifestMetadata(
        id: 'x',
        name: 'Y',
        category: 'tms',
        description: '描述',
      );
      expect(state.currentManifestId, 'x');
      expect(state.currentManifestName, 'Y');
      expect(state.currentManifestCategory, 'tms');
      expect(state.currentManifestDescription, '描述');
    });

    test('null 参数不覆盖已有值', () {
      final state = EditorState();
      state.updateManifestMetadata(id: 'keep', name: 'keep');
      state.updateManifestMetadata(category: 'cat');
      expect(state.currentManifestId, 'keep');
      expect(state.currentManifestCategory, 'cat');
    });
  });

  group('updateMockData', () {
    test('替换 mockData', () {
      final state = EditorState();
      expect(state.mockData, isEmpty);

      state.updateMockData({'key': 'val'});
      expect(state.mockData['key'], 'val');
    });

    test('用空 map 清空', () {
      final state = EditorState();
      state.updateMockData({'a': 1});
      state.updateMockData({});
      expect(state.mockData, isEmpty);
    });
  });

  group('addSchemaField', () {
    test('追加字段到 schema', () {
      final state = EditorState();
      expect(state.schema, isEmpty);

      const f = KoiTemplateField(key: 'name', label: '姓名');
      state.addSchemaField(f);
      expect(state.schema.length, 1);
      expect(state.schema[0].key, 'name');
    });

    test('多次追加不丢失', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'a', label: 'A'),
      );
      state.addSchemaField(
        const KoiTemplateField(key: 'b', label: 'B'),
      );
      expect(state.schema.length, 2);
      expect(state.schema[0].key, 'a');
      expect(state.schema[1].key, 'b');
    });
  });

  group('updateSchemaField', () {
    test('正常替换字段', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'old', label: '旧'),
      );
      state.updateSchemaField(
        0,
        const KoiTemplateField(key: 'new', label: '新'),
      );
      expect(state.schema[0].key, 'new');
      expect(state.schema[0].label, '新');
    });

    test('越界 index 不会崩溃', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'a', label: 'A'),
      );
      // 不应抛异常
      state.updateSchemaField(
        5,
        const KoiTemplateField(key: 'x', label: 'X'),
      );
      expect(state.schema.length, 1);
      expect(state.schema[0].key, 'a');
    });

    test('负数 index 不会崩溃', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'a', label: 'A'),
      );
      state.updateSchemaField(
        -1,
        const KoiTemplateField(key: 'x', label: 'X'),
      );
      expect(state.schema[0].key, 'a');
    });
  });

  group('removeSchemaField', () {
    test('正常删除字段', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'a', label: 'A'),
      );
      state.addSchemaField(
        const KoiTemplateField(key: 'b', label: 'B'),
      );
      state.removeSchemaField(0);
      expect(state.schema.length, 1);
      expect(state.schema[0].key, 'b');
    });

    test('越界 index 不会崩溃', () {
      final state = EditorState();
      state.removeSchemaField(0);
      expect(state.schema, isEmpty);
    });

    test('负数 index 不会崩溃', () {
      final state = EditorState();
      state.addSchemaField(
        const KoiTemplateField(key: 'a', label: 'A'),
      );
      state.removeSchemaField(-1);
      expect(state.schema.length, 1);
    });
  });

  group('loadManifest 同步 category 和 description (T3)', () {
    test('同步 category', () {
      final state = EditorState();
      final manifest = KoiTemplateManifest(
        id: 't',
        name: 'T',
        category: 'finance',
        document: const KoiTicketDocument(elements: []),
      );
      state.loadManifest(manifest, []);
      expect(state.currentManifestCategory, 'finance');
    });

    test('同步 description', () {
      final state = EditorState();
      final manifest = KoiTemplateManifest(
        id: 't',
        name: 'T',
        description: '这是描述',
        document: const KoiTicketDocument(elements: []),
      );
      state.loadManifest(manifest, []);
      expect(state.currentManifestDescription, '这是描述');
    });
  });
}
