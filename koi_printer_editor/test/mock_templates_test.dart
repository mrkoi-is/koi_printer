import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/mock_templates.dart';


void main() {
  group('manifestToEditorElements 转换', () {
    test('Ticket 文档转换出正确数量的 EditorElement', () {
      final manifest = templateManifests.first; // 寄件客户联
      final elements = manifestToEditorElements(manifest);

      final doc = manifest.document as KoiTicketDocument;
      expect(elements.length, doc.elements.length);
    });

    test('每个 EditorElement 有唯一 ID', () {
      final manifest = templateManifests.first;
      final elements = manifestToEditorElements(manifest);

      final ids = elements.map((e) => e.id).toSet();
      expect(ids.length, elements.length, reason: '所有 ID 应该唯一');
    });

    test('EditorElement.element 与原始文档元素一致', () {
      final manifest = templateManifests.first;
      final doc = manifest.document as KoiTicketDocument;
      final elements = manifestToEditorElements(manifest);

      for (int i = 0; i < elements.length; i++) {
        expect(elements[i].element, same(doc.elements[i]),
            reason: '第 $i 个元素应该是同一引用');
      }
    });

    test('非 Ticket 文档返回空列表', () {
      // 构造一个 Label 类型的 manifest
      final labelManifest = KoiTemplateManifest(
        id: 'label',
        name: 'Label',
        document: const KoiLabelDocument(elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
        ]),
      );

      final elements = manifestToEditorElements(labelManifest);
      expect(elements, isEmpty);
    });
  });

  group('templateManifests 数据完整性', () {
    test('所有 manifest 都有非空 id 和 name', () {
      for (final m in templateManifests) {
        expect(m.id, isNotEmpty, reason: '${m.name} 缺少 id');
        expect(m.name, isNotEmpty, reason: '${m.id} 缺少 name');
      }
    });

    test('所有 manifest 的 id 唯一', () {
      final ids = templateManifests.map((m) => m.id).toSet();
      expect(ids.length, templateManifests.length,
          reason: '存在重复的 manifest id');
    });

    test('所有 manifest 的 document 都是 KoiTicketDocument', () {
      for (final m in templateManifests) {
        expect(m.document, isA<KoiTicketDocument>(),
            reason: '${m.name} 的 document 类型不是 KoiTicketDocument');
      }
    });

    test('所有 manifest 都能 round-trip 序列化', () {
      for (final m in templateManifests) {
        final jsonStr = m.toJsonString();
        final restored = KoiTemplateManifest.fromJsonString(jsonStr);

        expect(restored.id, m.id, reason: '${m.name} round-trip id 不匹配');
        expect(restored.name, m.name,
            reason: '${m.name} round-trip name 不匹配');
        expect(restored.schema.length, m.schema.length,
            reason: '${m.name} round-trip schema 长度不匹配');

        final doc = restored.document as KoiTicketDocument;
        final originalDoc = m.document as KoiTicketDocument;
        expect(doc.elements.length, originalDoc.elements.length,
            reason: '${m.name} round-trip elements 长度不匹配');
      }
    });
  });

  group('defaultManifest / defaultTemplateElements', () {
    test('defaultManifest 是 templateManifests 的第一个', () {
      expect(defaultManifest.id, templateManifests.first.id);
    });

    test('defaultTemplateElements 数量匹配 defaultManifest 文档', () {
      final doc = defaultManifest.document as KoiTicketDocument;
      expect(defaultTemplateElements.length, doc.elements.length);
    });
  });
}
