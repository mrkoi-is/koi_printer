import 'package:flutter/material.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:provider/provider.dart';

class CenterCanvas extends StatelessWidget {
  const CenterCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();

    return Container(
      color: Colors.grey[200],
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: SingleChildScrollView(
        child: state.isTicketMode ? _buildTicketContent(context, state) : _buildLabelContent(context, state),
      ),
    );
  }

  Widget _buildTicketContent(BuildContext context, EditorState state) {
    final elements = state.elements;
    return Container(
      width: state.paperWidthPx + 24, // UI 增加留白，让物理纸张宽度不受影响
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
    );
  }

  Widget _buildLabelContent(BuildContext context, EditorState state) {
    var labelWidth = state.paperWidthPx;
    var labelHeight = state.paperWidthPx * 0.6;
    
    for (final e in state.elements) {
      if (e.element is KoiLabelSetupElement) {
        final setup = e.element as KoiLabelSetupElement;
        labelWidth = setup.widthMm * 3.78;
        labelHeight = setup.heightMm * 3.78;
        break;
      }
    }
    
    // 坐标元素缩放比 (dot → px, 基于 203dpi)
    final scale = labelWidth / (labelWidth / 3.78 * 203 / 25.4);

    return Container(
      width: labelWidth,
      height: labelHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: state.elements.map((editorElement) {
          return _EditableLabelElementWrap(
            key: ValueKey(editorElement.id),
            element: editorElement,
            isSelected: state.selectedElementId == editorElement.id,
            scale: scale,
            onSelect: () => context.read<EditorState>().selectElement(editorElement.id),
            onDelete: () {
              context.read<EditorState>().execute(
                RemoveElementCommand(editorElement.id),
              );
            },
          );
        }).toList(),
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

  KoiPrintElement _processEditMode(KoiPrintElement e, List<KoiTemplateField> fields) {
    if (e is KoiTextElement) {
      String t = e.text;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return e.copyWith(text: t);
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
      if (element.element is KoiTicketElement) {
        // 真实数据预览模式
        mockDoc = const KoiTemplateEngine().expandTicket(
          KoiTicketDocument(elements: [element.element as KoiTicketElement]),
          state.mockData,
        );
      } else {
        mockDoc = KoiLabelDocument(elements: [element.element as KoiLabelElement]);
      }
    } else {
      // 编辑模式下，替换占位符为中文别名标签
      final processed = _processEditMode(element.element, state.schema);
      if (processed is KoiTicketElement) {
        mockDoc = KoiTicketDocument(elements: [processed]);
      } else {
        mockDoc = KoiLabelDocument(elements: [processed as KoiLabelElement]);
      }
    }

    final renderWidget = KoiPreviewRenderer.build(
      document: mockDoc,
      paperWidthPx: state.paperWidthPx,
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
                  final mockInnerDoc = KoiTicketDocument(elements: [_processEditMode(t, state.schema) as KoiTicketElement]);
                  final innerRender = KoiPreviewRenderer.build(
                    document: mockInnerDoc, 
                    paperWidthPx: state.paperWidthPx,
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

    // 编辑模式下依赖 _processEditMode 将 {{变量}} 替换为 <中文标签> 做视觉提示，
    // 因为无法直接侵入 KoiPreviewRenderer 内部修改单个字的底色。

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

class _EditableLabelElementWrap extends StatelessWidget {
  const _EditableLabelElementWrap({
    super.key,
    required this.element,
    required this.isSelected,
    required this.scale,
    required this.onSelect,
    required this.onDelete,
  });

  final EditorElement element;
  final bool isSelected;
  final double scale;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  KoiPrintElement _processEditMode(KoiPrintElement e, List<KoiTemplateField> fields) {
    if (e is KoiPositionedTextElement) {
      String t = e.text;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return KoiPositionedTextElement(
        x: e.x, y: e.y, text: t,
        fontSize: e.fontSize, font: e.font,
        rotation: e.rotation, xScale: e.xScale, yScale: e.yScale, bold: e.bold,
      );
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final el = element.element as KoiLabelElement;
    
    // Replace text placeholders with schema labels
    final processed = state.isPreviewMode ? el : _processEditMode(el, state.schema) as KoiLabelElement;

    // Use the public render method from KoiPreviewRenderer
    final innerPositioned = KoiPreviewRenderer.renderPositionedElement(processed, Colors.black, scale);

    if (innerPositioned is! Positioned) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: innerPositioned.left,
      top: innerPositioned.top,
      width: innerPositioned.width,
      height: innerPositioned.height,
      child: GestureDetector(
        onTap: onSelect,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              innerPositioned.child,
              
              if (isSelected)
                Positioned(
                  top: -20,
                  right: -20,
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
      ),
    );
  }
}
