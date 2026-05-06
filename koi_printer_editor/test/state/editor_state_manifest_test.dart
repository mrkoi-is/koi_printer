import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

void main() {
  // 辅助: 创建一个简单的 manifest
  KoiTemplateManifest makeManifest({
    String id = 'test_id',
    String name = '测试模板',
    List<KoiTemplateField> schema = const [],
    Map<String, dynamic> mockData = const {},
    List<KoiTicketElement> elements = const [],
  }) {
    return KoiTemplateManifest(
      id: id,
      name: name,
      schema: schema,
      mockData: mockData,
      document: KoiTicketDocument(elements: elements),
    );
  }

  // 辅助: 把 manifest 转成 EditorElement 列表
  List<EditorElement> toEditorElements(KoiTemplateManifest m) {
    final doc = m.document as KoiTicketDocument;
    int counter = 0;
    return doc.elements
        .map((e) => EditorElement(id: 'e_${counter++}', element: e))
        .toList();
  }

  group('EditorState.loadManifest 行为', () {
    test('同步 elements', () {
      final state = EditorState();
      final manifest = makeManifest(
        elements: const [
          KoiTextElement(text: 'Hello'),
          KoiDividerElement(),
        ],
      );
      final elements = toEditorElements(manifest);

      state.loadManifest(manifest, elements);

      expect(state.elements.length, 2);
      expect(state.elements[0].id, 'e_0');
      expect((state.elements[0].element as KoiTextElement).text, 'Hello');
    });

    test('同步 schema', () {
      final state = EditorState();
      final manifest = makeManifest(
        schema: const [
          KoiTemplateField(key: 'title', label: '标题'),
          KoiTemplateField(
            key: 'amount',
            label: '金额',
            type: KoiFieldType.number,
          ),
        ],
      );

      state.loadManifest(manifest, []);

      expect(state.schema.length, 2);
      expect(state.schema[0].key, 'title');
      expect(state.schema[0].label, '标题');
      expect(state.schema[0].type, KoiFieldType.string);
      expect(state.schema[1].type, KoiFieldType.number);
    });

    test('同步 mockData', () {
      final state = EditorState();
      final manifest = makeManifest(
        mockData: const {'companyName': 'Koi', 'amount': 42},
      );

      state.loadManifest(manifest, []);

      expect(state.mockData['companyName'], 'Koi');
      expect(state.mockData['amount'], 42);
    });

    test('同步 manifest 身份 (id + name)', () {
      final state = EditorState();
      final manifest = makeManifest(id: 'my_id', name: '交款单');

      state.loadManifest(manifest, []);

      expect(state.currentManifestId, 'my_id');
      expect(state.currentManifestName, '交款单');
      expect(state.schemaEntity, '交款单');
    });

    test('清空 undo/redo 栈', () {
      final state = EditorState();
      // 先添加一个元素建立 undo 历史
      final el = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'X'),
      );
      state.loadTemplate([el]);
      expect(state.elements.length, 1);

      // loadManifest 应该重置
      final manifest = makeManifest();
      state.loadManifest(manifest, []);

      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
    });

    test('清空 selectedElementId', () {
      final state = EditorState();
      final el = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'X'),
      );
      state.loadTemplate([el]);
      state.selectElement('1');
      expect(state.selectedElementId, '1');

      final manifest = makeManifest();
      state.loadManifest(manifest, []);

      expect(state.selectedElementId, isNull);
    });

    test('空 schema 保持空列表', () {
      final state = EditorState();
      final manifest = makeManifest(schema: const []);

      state.loadManifest(manifest, []);

      expect(state.schema, isEmpty);
    });

    test('空 mockData 保持空 map', () {
      final state = EditorState();
      final manifest = makeManifest(mockData: const {});

      state.loadManifest(manifest, []);

      expect(state.mockData, isEmpty);
    });
  });

  group('EditorState 基础方法', () {
    test('togglePreviewMode 切换状态', () {
      final state = EditorState();
      expect(state.isPreviewMode, isFalse);

      state.togglePreviewMode();
      expect(state.isPreviewMode, isTrue);

      state.togglePreviewMode();
      expect(state.isPreviewMode, isFalse);
    });

    test('selectElement 设置与清除', () {
      final state = EditorState();

      state.selectElement('abc');
      expect(state.selectedElementId, 'abc');

      state.selectElement(null);
      expect(state.selectedElementId, isNull);
    });

    test('updateSchema 替换 schema', () {
      final state = EditorState();
      expect(state.schema, isEmpty);

      const fields = [KoiTemplateField(key: 'a', label: 'A')];
      state.updateSchema(fields);

      expect(state.schema.length, 1);
      expect(state.schema[0].key, 'a');
    });

    test('document getter 正确构建 KoiTicketDocument', () {
      final el = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'Test'),
      );
      final state = EditorState(initialElements: [el]);

      final doc = state.document;
      expect(doc, isA<KoiTicketDocument>());
      final ticket = doc as KoiTicketDocument;
      expect(ticket.elements.length, 1);
      expect((ticket.elements[0] as KoiTextElement).text, 'Test');
    });

    test('selectedElement 返回正确元素', () {
      final el1 = EditorElement(
        id: 'a',
        element: const KoiTextElement(text: 'A'),
      );
      final el2 = EditorElement(
        id: 'b',
        element: const KoiTextElement(text: 'B'),
      );
      final state = EditorState(initialElements: [el1, el2]);

      state.selectElement('b');
      expect(state.selectedElement, isNotNull);
      expect(state.selectedElement!.id, 'b');
    });

    test('selectedElement 不存在时返回 null', () {
      final state = EditorState();
      state.selectElement('nonexistent');
      expect(state.selectedElement, isNull);
    });
  });
}
