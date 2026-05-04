import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:provider/provider.dart';

class CenterCanvas extends StatelessWidget {
  const CenterCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final elements = state.elements;

    return Container(
      color: Colors.grey[200],
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SingleChildScrollView(
        child: Container(
          width: 380, // 80mm preview width
          constraints: const BoxConstraints(minHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: elements.length,
            onReorder: (oldIndex, newIndex) {
              context.read<EditorState>().execute(
                ReorderElementsCommand(oldIndex: oldIndex, newIndex: newIndex),
              );
            },
            itemBuilder: (context, index) {
              final editorElement = elements[index];
              return _EditableElementWrap(
                key: ValueKey(editorElement.id),
                element: editorElement,
                isSelected: state.selectedElementId == editorElement.id,
                onSelect: () => context.read<EditorState>().selectElement(editorElement.id),
                onDelete: () {
                  context.read<EditorState>().execute(
                    RemoveElementCommand(editorElement.id),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EditableElementWrap extends StatelessWidget {
  const _EditableElementWrap({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
  });

  final EditorElement element;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mockDoc = KoiTicketDocument(elements: [element.element]);
    final renderWidget = KoiPreviewRenderer.build(
      document: mockDoc,
      paperWidthPx: 380,
    );
    
    Widget child = renderWidget;
    if (renderWidget is Container && renderWidget.child is Column) {
       final col = renderWidget.child as Column;
       if (col.children.isNotEmpty) {
         child = col.children.first;
       }
    }

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: child,
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
