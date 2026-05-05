import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

abstract class EditorCommand {
  void execute(EditorState state);
  void undo(EditorState state);
}

class AddElementCommand extends EditorCommand {
  AddElementCommand(this.element, {this.index, this.parentId});

  final EditorElement element;
  final int? index;
  final String? parentId;

  @override
  void execute(EditorState state) {
    final elements = List<EditorElement>.from(state.elements);
    
    if (parentId != null) {
      final pIndex = elements.indexWhere((e) => e.id == parentId);
      if (pIndex != -1) {
        final parent = elements[pIndex].element;
        if (parent is KoiTicketForEachElement) {
          final newTemplates = List<KoiTicketElement>.from(parent.templates);
          if (element.element is! KoiTicketElement) return;
          final ticketEl = element.element as KoiTicketElement;
          if (index != null && index! >= 0 && index! <= newTemplates.length) {
            newTemplates.insert(index!, ticketEl);
          } else {
            newTemplates.add(ticketEl);
          }
          elements[pIndex] = elements[pIndex].copyWith(
            element: KoiTicketForEachElement(
              listKey: parent.listKey,
              templates: newTemplates,
            ),
          );
        }
      }
    } else {
      if (index != null && index! >= 0 && index! <= elements.length) {
        elements.insert(index!, element);
      } else {
        elements.add(element);
      }
    }
    
    state.updateElements(elements);
    // 选中仍然保留到容器（因为子元素没有 ID 追踪，这是一个简化版实现）
    state.selectElement(parentId ?? element.id);
  }

  @override
  void undo(EditorState state) {
    final elements = List<EditorElement>.from(state.elements);
    
    if (parentId != null) {
      final pIndex = elements.indexWhere((e) => e.id == parentId);
      if (pIndex != -1) {
        final parent = elements[pIndex].element;
        if (parent is KoiTicketForEachElement) {
          final newTemplates = List<KoiTicketElement>.from(parent.templates);
          if (element.element is KoiTicketElement) {
            newTemplates.remove(element.element as KoiTicketElement);
          }
          elements[pIndex] = elements[pIndex].copyWith(
            element: KoiTicketForEachElement(
              listKey: parent.listKey,
              templates: newTemplates,
            ),
          );
        }
      }
    } else {
      elements.removeWhere((e) => e.id == element.id);
    }
    
    state.updateElements(elements);
    if (state.selectedElementId == element.id) {
      state.selectElement(null);
    }
  }
}

class RemoveElementCommand extends EditorCommand {
  RemoveElementCommand(this.elementId);

  final String elementId;
  EditorElement? _removedElement;
  int? _removedIndex;

  @override
  void execute(EditorState state) {
    final elements = List<EditorElement>.from(state.elements);
    _removedIndex = elements.indexWhere((e) => e.id == elementId);
    if (_removedIndex != -1) {
      _removedElement = elements.removeAt(_removedIndex!);
      state.updateElements(elements);
      if (state.selectedElementId == elementId) {
        state.selectElement(null);
      }
    }
  }

  @override
  void undo(EditorState state) {
    if (_removedElement != null && _removedIndex != null) {
      final elements = List<EditorElement>.from(state.elements);
      elements.insert(_removedIndex!, _removedElement!);
      state.updateElements(elements);
      state.selectElement(elementId);
    }
  }
}

class UpdateElementCommand extends EditorCommand {
  UpdateElementCommand({
    required this.elementId,
    required this.oldElement,
    required this.newElement,
  });

  final String elementId;
  final KoiPrintElement oldElement;
  final KoiPrintElement newElement;

  @override
  void execute(EditorState state) {
    _replace(state, newElement);
  }

  @override
  void undo(EditorState state) {
    _replace(state, oldElement);
  }

  void _replace(EditorState state, KoiPrintElement replacement) {
    final elements = List<EditorElement>.from(state.elements);
    final index = elements.indexWhere((e) => e.id == elementId);
    if (index != -1) {
      elements[index] = elements[index].copyWith(element: replacement);
      state.updateElements(elements);
    }
  }
}

class ReorderElementsCommand extends EditorCommand {
  ReorderElementsCommand({
    required this.oldIndex,
    required this.newIndex,
  });

  final int oldIndex;
  final int newIndex;

  @override
  void execute(EditorState state) {
    _move(state, oldIndex, newIndex);
  }

  @override
  void undo(EditorState state) {
    int reverseOldIndex = newIndex;
    int reverseNewIndex = oldIndex;
    if (oldIndex < newIndex) {
      reverseOldIndex -= 1;
    } else {
      reverseNewIndex += 1;
    }
    _move(state, reverseOldIndex, reverseNewIndex);
  }

  void _move(EditorState state, int from, int to) {
    final elements = List<EditorElement>.from(state.elements);
    final element = elements.removeAt(from);
    int target = to;
    if (from < to) target -= 1;
    elements.insert(target, element);
    state.updateElements(elements);
  }
}
