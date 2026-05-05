import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

void main() {
  group('EditorState & Command Pattern Tests', () {
    test('Initial state is empty', () {
      final state = EditorState();
      expect(state.elements, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isFalse);
      expect(state.selectedElementId, isNull);
    });

    test('AddElementCommand and Undo/Redo', () {
      final state = EditorState();
      final element = EditorElement(
        id: '1',
        element: const KoiTextElement(text: 'Hello'),
      );

      // Execute Add
      state.execute(AddElementCommand(element));
      expect(state.elements.length, 1);
      expect(state.elements.first.id, '1');
      expect(state.canUndo, isTrue);
      expect(state.selectedElementId, '1');

      // Undo Add
      state.undo();
      expect(state.elements, isEmpty);
      expect(state.canUndo, isFalse);
      expect(state.canRedo, isTrue);
      expect(state.selectedElementId, isNull);

      // Redo Add
      state.redo();
      expect(state.elements.length, 1);
      expect(state.elements.first.id, '1');
      expect(state.canUndo, isTrue);
      expect(state.canRedo, isFalse);

      // Add to root with specific index
      final element2 = EditorElement(
        id: '2',
        element: const KoiTextElement(text: 'Hello 2'),
      );
      state.execute(AddElementCommand(element2, index: 0));
      expect(state.elements.first.id, '2');
      expect(state.elements.length, 2);
    });

    test('AddElementCommand with parentId to KoiTicketForEachElement', () {
      final forEachElement = EditorElement(
        id: 'parent_1',
        element: const KoiTicketForEachElement(
          listKey: 'items',
          templates: [KoiTextElement(text: 'Old')],
        ),
      );
      final state = EditorState(initialElements: [forEachElement]);

      // 1. Add to specific index
      final child1 = EditorElement(
        id: 'child_1',
        element: const KoiTextElement(text: 'Child 1'),
      );
      state.execute(AddElementCommand(child1, parentId: 'parent_1', index: 0));

      var parent = state.elements.first.element as KoiTicketForEachElement;
      expect(parent.templates.length, 2);
      expect((parent.templates[0] as KoiTextElement).text, 'Child 1');
      expect((parent.templates[1] as KoiTextElement).text, 'Old');

      // 2. Add to end (null index)
      final child2 = EditorElement(
        id: 'child_2',
        element: const KoiTextElement(text: 'Child 2'),
      );
      state.execute(AddElementCommand(child2, parentId: 'parent_1'));
      
      parent = state.elements.first.element as KoiTicketForEachElement;
      expect(parent.templates.length, 3);
      expect((parent.templates[2] as KoiTextElement).text, 'Child 2');

      // 3. Undo additions
      state.undo(); // undo child2
      parent = state.elements.first.element as KoiTicketForEachElement;
      expect(parent.templates.length, 2);

      state.undo(); // undo child1
      parent = state.elements.first.element as KoiTicketForEachElement;
      expect(parent.templates.length, 1);
      expect((parent.templates[0] as KoiTextElement).text, 'Old');

      // 4. Invalid parentId - no-op
      final child3 = EditorElement(
        id: 'child_3',
        element: const KoiTextElement(text: 'Child 3'),
      );
      state.execute(AddElementCommand(child3, parentId: 'invalid_id'));
      expect(state.elements.length, 1);
      parent = state.elements.first.element as KoiTicketForEachElement;
      expect(parent.templates.length, 1);

      // 5. Parent is not KoiTicketForEachElement - no-op
      final textElement = EditorElement(
        id: 'parent_2',
        element: const KoiTextElement(text: 'Parent'),
      );
      state.updateElements([textElement]);
      state.execute(AddElementCommand(child3, parentId: 'parent_2'));
      expect((state.elements.first.element as KoiTextElement).text, 'Parent');
    });

    test('RemoveElementCommand and Undo/Redo', () {
      final element = EditorElement(
        id: '2',
        element: const KoiTextElement(text: 'ToRemove'),
      );
      final state = EditorState(initialElements: [element]);
      expect(state.elements.length, 1);
      
      // Select the element to ensure it's cleared on removal
      state.selectElement('2');
      expect(state.selectedElementId, '2');

      // Execute Remove
      state.execute(RemoveElementCommand('2'));
      expect(state.elements, isEmpty);
      expect(state.selectedElementId, isNull);

      // Undo Remove
      state.undo();
      expect(state.elements.length, 1);
      expect(state.elements.first.id, '2');
      expect(state.selectedElementId, '2');
    });

    test('UpdateElementCommand and Undo/Redo', () {
      final element = EditorElement(
        id: '3',
        element: const KoiTextElement(text: 'Old'),
      );
      final state = EditorState(initialElements: [element]);

      state.execute(UpdateElementCommand(
        elementId: '3',
        oldElement: const KoiTextElement(text: 'Old'),
        newElement: const KoiTextElement(text: 'New'),
      ));

      expect(state.elements.first.element, isA<KoiTextElement>());
      expect((state.elements.first.element as KoiTextElement).text, 'New');

      state.undo();
      expect((state.elements.first.element as KoiTextElement).text, 'Old');
    });

    test('ReorderElementsCommand and Undo/Redo', () {
      final e1 = EditorElement(id: 'A', element: const KoiTextElement(text: 'A'));
      final e2 = EditorElement(id: 'B', element: const KoiTextElement(text: 'B'));
      final e3 = EditorElement(id: 'C', element: const KoiTextElement(text: 'C'));
      final state = EditorState(initialElements: [e1, e2, e3]);

      // Move A (index 0) to after C (index 3, since ReorderableListView uses length as index)
      state.execute(ReorderElementsCommand(oldIndex: 0, newIndex: 3));
      
      expect(state.elements[0].id, 'B');
      expect(state.elements[1].id, 'C');
      expect(state.elements[2].id, 'A');

      state.undo();
      expect(state.elements[0].id, 'A');
      expect(state.elements[1].id, 'B');
      expect(state.elements[2].id, 'C');

      // Move C (index 2) to before A (index 0)
      state.execute(ReorderElementsCommand(oldIndex: 2, newIndex: 0));
      expect(state.elements[0].id, 'C');
      expect(state.elements[1].id, 'A');
      expect(state.elements[2].id, 'B');

      state.undo();
      expect(state.elements[0].id, 'A');
      expect(state.elements[1].id, 'B');
      expect(state.elements[2].id, 'C');
    });
  });
}
