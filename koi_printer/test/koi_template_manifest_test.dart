import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';

void main() {
  group('KoiTemplateManifest 序列化 round-trip', () {
    // 构建一个完整的 manifest 用于所有 round-trip 测试
    const fullManifest = KoiTemplateManifest(
      id: 'test_v1',
      name: '测试模板',
      version: 2,
      category: 'test',
      description: '一个用于测试的模板',
      schema: [
        KoiTemplateField(key: 'title', label: '标题'),
        KoiTemplateField(
            key: 'amount', label: '金额', type: KoiFieldType.number),
        KoiTemplateField(
            key: 'items', label: '列表', type: KoiFieldType.array),
      ],
      groups: [
        KoiTemplateGroup(label: '头部', startIndex: 0, endIndex: 2),
        KoiTemplateGroup(label: '明细', startIndex: 3, endIndex: 5),
      ],
      mockData: {
        'title': '测试标题',
        'amount': 99.9,
        'items': [
          {'name': 'A', 'qty': 1},
          {'name': 'B', 'qty': 2},
        ],
      },
      document: KoiTicketDocument(elements: [
        KoiTextElement(text: '{{title}}', bold: true),
        KoiDividerElement(),
        KoiCutElement(),
      ]),
    );

    test('完整 manifest toJson → fromJson round-trip', () {
      final json = fullManifest.toJson();
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.id, 'test_v1');
      expect(restored.name, '测试模板');
      expect(restored.version, 2);
      expect(restored.category, 'test');
      expect(restored.description, '一个用于测试的模板');
    });

    test('schema 字段 round-trip 保持类型', () {
      final json = fullManifest.toJson();
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.schema.length, 3);
      expect(restored.schema[0].key, 'title');
      expect(restored.schema[0].label, '标题');
      expect(restored.schema[0].type, KoiFieldType.string);
      expect(restored.schema[1].type, KoiFieldType.number);
      expect(restored.schema[2].type, KoiFieldType.array);
    });

    test('groups 分组 round-trip', () {
      final json = fullManifest.toJson();
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.groups.length, 2);
      expect(restored.groups[0].label, '头部');
      expect(restored.groups[0].startIndex, 0);
      expect(restored.groups[0].endIndex, 2);
      expect(restored.groups[1].label, '明细');
    });

    test('mockData round-trip 保持嵌套结构', () {
      final json = fullManifest.toJson();
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.mockData['title'], '测试标题');
      expect(restored.mockData['amount'], 99.9);
      expect(restored.mockData['items'], isList);
      final items = restored.mockData['items'] as List;
      expect(items.length, 2);
      expect((items[0] as Map)['name'], 'A');
    });

    test('document round-trip 保持元素类型', () {
      final json = fullManifest.toJson();
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.document, isA<KoiTicketDocument>());
      final doc = restored.document as KoiTicketDocument;
      expect(doc.elements.length, 3);
      expect(doc.elements[0], isA<KoiTextElement>());
      expect((doc.elements[0] as KoiTextElement).text, '{{title}}');
      expect((doc.elements[0] as KoiTextElement).bold, true);
      expect(doc.elements[1], isA<KoiDividerElement>());
      expect(doc.elements[2], isA<KoiCutElement>());
    });

    test('toJsonString → fromJsonString round-trip', () {
      final jsonStr = fullManifest.toJsonString();
      final restored = KoiTemplateManifest.fromJsonString(jsonStr);

      expect(restored.id, fullManifest.id);
      expect(restored.name, fullManifest.name);
      expect(restored.schema.length, fullManifest.schema.length);
      expect(restored.document, isA<KoiTicketDocument>());
    });
  });

  group('KoiTemplateManifest 稀疏 JSON (可选字段省略)', () {
    test('省略 category/description/groups/mockData 时 toJson 不包含这些字段',
        () {
      const manifest = KoiTemplateManifest(
        id: 'minimal',
        name: '最小模板',
        document: KoiTicketDocument(elements: []),
      );

      final json = manifest.toJson();

      expect(json.containsKey('category'), isFalse);
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('groups'), isFalse);
      expect(json.containsKey('mockData'), isFalse);
      // 但 schema 始终输出 (即使为空列表)
      expect(json['schema'], isList);
    });

    test('fromJson 对缺失字段给出安全默认值', () {
      final json = <String, dynamic>{
        'document': const KoiTicketDocument(elements: []).toJson(),
      };
      final restored = KoiTemplateManifest.fromJson(json);

      expect(restored.id, '');
      expect(restored.name, '');
      expect(restored.version, 1);
      expect(restored.category, '');
      expect(restored.description, '');
      expect(restored.schema, isEmpty);
      expect(restored.groups, isEmpty);
      expect(restored.mockData, isEmpty);
    });
  });

  group('KoiTemplateManifest 错误处理', () {
    test('缺少 document 字段时抛出 FormatException', () {
      final json = <String, dynamic>{
        'id': 'broken',
        'name': '坏模板',
      };

      expect(
        () => KoiTemplateManifest.fromJson(json),
        throwsFormatException,
      );
    });

    test('document 字段类型错误时抛出 FormatException', () {
      final json = <String, dynamic>{
        'id': 'broken',
        'document': '不是Map',
      };

      expect(
        () => KoiTemplateManifest.fromJson(json),
        throwsFormatException,
      );
    });

    test('document 字段为 null 时抛出 FormatException', () {
      final json = <String, dynamic>{
        'id': 'broken',
        'document': null,
      };

      expect(
        () => KoiTemplateManifest.fromJson(json),
        throwsFormatException,
      );
    });
  });

  group('KoiTemplateField 序列化细节', () {
    test('默认类型 string 不输出 type 字段', () {
      const manifest = KoiTemplateManifest(
        id: 'f1',
        name: 'test',
        schema: [KoiTemplateField(key: 'name', label: '名称')],
        document: KoiTicketDocument(elements: []),
      );

      final json = manifest.toJson();
      final schemaList = json['schema'] as List;
      final fieldJson = schemaList[0] as Map<String, dynamic>;

      // string 是默认值, 不应该出现在 JSON 中
      expect(fieldJson.containsKey('type'), isFalse);
      expect(fieldJson['key'], 'name');
      expect(fieldJson['label'], '名称');
    });

    test('非默认类型 number/array 输出 type 字段', () {
      const manifest = KoiTemplateManifest(
        id: 'f2',
        name: 'test',
        schema: [
          KoiTemplateField(
              key: 'price', label: '价格', type: KoiFieldType.number),
          KoiTemplateField(
              key: 'items', label: '列表', type: KoiFieldType.array),
        ],
        document: KoiTicketDocument(elements: []),
      );

      final json = manifest.toJson();
      final schemaList = json['schema'] as List;

      expect((schemaList[0] as Map)['type'], 'number');
      expect((schemaList[1] as Map)['type'], 'array');
    });

    test('fromJson 中未知 type 回退为 string', () {
      final json = <String, dynamic>{
        'id': 'f3',
        'name': 'test',
        'schema': [
          {'key': 'x', 'label': 'X', 'type': 'unknown_type'},
        ],
        'document': const KoiTicketDocument(elements: []).toJson(),
      };

      final restored = KoiTemplateManifest.fromJson(json);
      expect(restored.schema[0].type, KoiFieldType.string);
    });

    test('fromJson 中缺少 label 时回退为 key', () {
      final json = <String, dynamic>{
        'id': 'f4',
        'name': 'test',
        'schema': [
          {'key': 'myField'},
        ],
        'document': const KoiTicketDocument(elements: []).toJson(),
      };

      final restored = KoiTemplateManifest.fromJson(json);
      expect(restored.schema[0].label, 'myField');
    });
  });

  group('KoiTemplateManifest manifestVersion', () {
    test('toJson 输出 manifestVersion: 1', () {
      const manifest = KoiTemplateManifest(
        id: 'v',
        name: 'v',
        document: KoiTicketDocument(elements: []),
      );
      final json = manifest.toJson();
      expect(json['manifestVersion'], 1);
    });
  });
}
