import 'package:flutter/material.dart';
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

  KoiTicketElement _processEditMode(KoiTicketElement e, List<KoiTemplateField> fields) {
    if (e is KoiTextElement) {
      String t = e.text;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return KoiTextElement(
        text: t,
        size: e.size,
        widthSize: e.widthSize,
        heightSize: e.heightSize,
        align: e.align,
        bold: e.bold,
        reverse: e.reverse,
        underline: e.underline,
        underlineStyle: e.underlineStyle,
        font: e.font,
      );
    } else if (e is KoiTextRowElement) {
      return KoiTextRowElement(
        columns: e.columns.map((c) {
          String t = c.text;
          for (var f in fields) {
            t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
          }
          return KoiTextColumn(text: t, ratio: c.ratio, align: c.align, bold: c.bold);
        }).toList(),
      );
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    
    KoiPrintDocument mockDoc;
    if (state.isPreviewMode) {
      // 真实数据预览模式
      mockDoc = const KoiTemplateEngine().expandTicket(
        KoiTicketDocument(elements: [element.element]),
        state.mockData,
      );
    } else {
      // 编辑模式下，替换占位符为中文别名标签
      mockDoc = KoiTicketDocument(
        elements: [_processEditMode(element.element, state.schema)],
      );
    }

    final renderWidget = KoiPreviewRenderer.build(
      document: mockDoc,
      paperWidthPx: 380,
      fontFamily: 'SarasaMono',
    );
    
    Widget child = renderWidget;
    // 提取单个元素的渲染结果（去除外层 Document 容器）
    if (renderWidget is Container && renderWidget.child is Column) {
       final col = renderWidget.child as Column;
       if (col.children.isNotEmpty) {
         child = col.children.first;
       }
    }

    if (!state.isPreviewMode && element.element is KoiTicketForEachElement) {
       final forEachElement = element.element as KoiTicketForEachElement;
       child = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange, style: BorderStyle.solid),
            color: Colors.orange.withValues(alpha: 0.05),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Text('🔄 列表循环区域 (数组: ${forEachElement.listKey})', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
               const Divider(color: Colors.orange),
               ...forEachElement.templates.map((t) {
                  final mockInnerDoc = KoiTicketDocument(elements: [_processEditMode(t, state.schema)]);
                  final innerRender = KoiPreviewRenderer.build(
                    document: mockInnerDoc, 
                    paperWidthPx: 380,
                    fontFamily: 'SarasaMono',
                  );
                  if (innerRender is Container && innerRender.child is Column) {
                    final col = innerRender.child as Column;
                    if (col.children.isNotEmpty) return col.children.first;
                  }
                  return innerRender;
               }),
               if (forEachElement.templates.isEmpty)
                 const Padding(
                   padding: EdgeInsets.all(16), 
                   child: Center(child: Text('选中此区域，从左侧组件库添加子组件', style: TextStyle(color: Colors.grey, fontSize: 12)))
                 ),
            ]
          )
       );
    }

    // 编辑模式下给中文别名加个底色（如果是文本）
    if (!state.isPreviewMode) {
      // 因为我们无法直接侵入 KoiPreviewRenderer 内部修改单个字的底色，
      // 所以我们依赖上面的 _processEditMode 将文字变成 <运单号> 来做视觉提示
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
