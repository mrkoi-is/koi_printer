import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

void main() {
  group('EditorState New APIs Tests', () {
    test('zoomIn and zoomOut limits', () {
      final state = EditorState();
      expect(state.labelScale, 1.5);

      state.zoomIn();
      expect(state.labelScale, 1.75);

      for (var i = 0; i < 10; i++) {
        state.zoomIn();
      }
      expect(state.labelScale, 3.0); // max is 3.0

      for (var i = 0; i < 20; i++) {
        state.zoomOut();
      }
      expect(state.labelScale, 0.5); // min is 0.5
    });

    test('setExplicitLabelMode works and isModeExplicitlySet', () {
      final state = EditorState();
      expect(state.isModeExplicitlySet, false);
      expect(state.isTicketMode, true); // Empty is ticket mode by default

      state.setExplicitLabelMode(false); // set to ticket mode explicitly
      expect(state.isModeExplicitlySet, true);
      expect(state.isTicketMode, true);

      final state2 = EditorState();
      state2.setExplicitLabelMode(true); // set to label mode explicitly
      expect(state2.isModeExplicitlySet, true);
      expect(state2.isTicketMode, false);
      expect(state2.elements.length, 1);
      expect(state2.elements.first.element, isA<KoiLabelSetupElement>());

      // Setting again when not empty does nothing
      state2.setExplicitLabelMode(false);
      expect(state2.isTicketMode, false);
    });

    test('updateElementNoHistory updates without adding command', () {
      final element = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'Old'),
      );
      final state = EditorState(initialElements: [element]);

      expect(state.canUndo, false);

      state.updateElementNoHistory('1', const KoiTextElement(text: 'New'));

      expect(state.canUndo, false);
      expect((state.elements.first.element as KoiTextElement).text, 'New');

      // Update non-existent does nothing
      state.updateElementNoHistory('2', const KoiTextElement(text: 'New 2'));
      expect(state.elements.length, 1);
    });

    test('loadTemplate clears stacks', () {
      final state = EditorState();
      final element = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'A'),
      );
      state.loadTemplate([element]);

      expect(state.elements.length, 1);
      expect(state.canUndo, false);
      expect(state.selectedElementId, null);
    });

    test('updateElements updates elements list', () {
      final state = EditorState();
      final element = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'A'),
      );
      state.updateElements([element]);

      expect(state.elements.length, 1);
      expect(state.elements.first.id, '1');
    });

    test('document getter for label mode', () {
      final element = EditorElement(
        id: '1',
        element: const KoiLabelSetupElement(widthMm: 40, heightMm: 30),
      );
      final state = EditorState(initialElements: [element]);

      expect(state.isTicketMode, false);
      final doc = state.document as KoiLabelDocument;
      expect(doc, isA<KoiLabelDocument>());
      expect(doc.elements.length, 1);
    });

    test('EditorManifestMixin coverage', () {
      final state = EditorState();
      state.initManifestIdentity('1', 'Name', 'Cat', 'Desc');
      expect(state.currentManifestId, '1');
      expect(state.currentManifestName, 'Name');
      expect(state.currentManifestCategory, 'Cat');
      expect(state.currentManifestDescription, 'Desc');
      expect(state.schemaEntity, 'Name');
      expect(state.paperWidthPx, 380.0);

      state.updateManifestMetadata(
        id: '2',
        name: 'Name2',
        category: 'Cat2',
        description: 'Desc2',
      );
      expect(state.currentManifestId, '2');
      expect(state.currentManifestName, 'Name2');
      expect(state.currentManifestCategory, 'Cat2');
      expect(state.currentManifestDescription, 'Desc2');

      state.updatePaperWidthPx(400.0);
      expect(state.paperWidthPx, 400.0);
    });

    test('EditorSchemaMixin coverage', () {
      final state = EditorState();

      state.updateMockData({'key': 'value'});
      expect(state.mockData['key'], 'value');

      final field = KoiTemplateField(
        key: 'price',
        label: 'Price',
        type: KoiFieldType.number,
      );
      state.addSchemaField(field);
      expect(state.schema.length, 1);

      // Duplicate key exception
      expect(() => state.addSchemaField(field), throwsException);

      final field2 = KoiTemplateField(
        key: 'price',
        label: 'Price2',
        type: KoiFieldType.string,
      );
      state.updateSchemaField(0, field2);
      expect(state.schema[0].type, KoiFieldType.string);
      expect(state.schema[0].label, 'Price2');

      // Out of bounds
      state.updateSchemaField(1, field2);
      expect(state.schema.length, 1);

      state.removeSchemaField(0);
      expect(state.schema.length, 0);

      // Out of bounds
      state.removeSchemaField(0);
      expect(state.schema.length, 0);
    });
  });
}
