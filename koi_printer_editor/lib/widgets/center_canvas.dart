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
        child: state.elements.isEmpty && !state.isModeExplicitlySet
            ? _buildEmptySelector(context, state)
            : (state.isTicketMode ? _buildTicketContent(context, state) : _buildLabelContent(context, state)),
      ),
    );
  }

  Widget _buildEmptySelector(BuildContext context, EditorState state) {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.print, size: 64, color: Colors.blueGrey),
          const SizedBox(height: 24),
          const Text('创建新打印模板', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('请选择您要设计的打印布局模式。注意，模式一旦选择，在添加组件后不可随意更改。', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 默认就是 ticket mode，这里不用做操作，或者直接加一个文本组件
                    state.setExplicitLabelMode(false);
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('小票模式\n(流式排版)', textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    state.setExplicitLabelMode(true);
                  },
                  icon: const Icon(Icons.label),
                  label: const Text('标签模式\n(绝对定位)', textAlign: TextAlign.center),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ),
              ),
            ],
          ),
        ],
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
    final scale = state.labelScale; // 编辑器放大系数：1 dot = scale px，避免元素过小无法点击
    double labelWidth = 400;
    double labelHeight = 300;
    
    for (final e in state.elements) {
      if (e.element is KoiLabelSetupElement) {
        final setup = e.element as KoiLabelSetupElement;
        final dotsW = setup.widthMm / 25.4 * 203;
        final dotsH = setup.heightMm / 25.4 * 203;
        labelWidth = dotsW * scale;
        labelHeight = dotsH * scale;
        break;
      }
    }

    return Stack(
      children: [
        Container(
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
        ),
        Positioned(
          right: 16,
          top: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.zoom_out, size: 20),
                  onPressed: () => context.read<EditorState>().zoomOut(),
                  tooltip: '缩小',
                ),
                Text('${(scale * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.zoom_in, size: 20),
                  onPressed: () => context.read<EditorState>().zoomIn(),
                  tooltip: '放大',
                ),
              ],
            ),
          ),
        ),
      ],
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

class _EditableLabelElementWrap extends StatefulWidget {
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

  @override
  State<_EditableLabelElementWrap> createState() => _EditableLabelElementWrapState();
}

class _EditableLabelElementWrapState extends State<_EditableLabelElementWrap> {
  KoiPrintElement? _dragStartElement;

  KoiPrintElement _processEditMode(KoiPrintElement e, List<KoiTemplateField> fields) {
    if (e is KoiPositionedTextElement) {
      String t = e.text;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return e.copyWith(text: t);
    } else if (e is KoiPositionedBarcodeElement) {
      String t = e.data;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return e.copyWith(data: t);
    } else if (e is KoiPositionedQrCodeElement) {
      String t = e.data;
      for (var f in fields) {
        t = t.replaceAll('{{${f.key}}}', '<${f.label}>');
      }
      return e.copyWith(data: t);
    }
    return e;
  }

  KoiLabelElement _moveElement(KoiLabelElement el, int dx, int dy) {
    if (el is KoiPositionedTextElement) {
      return KoiPositionedTextElement(
        x: el.x + dx, y: el.y + dy, text: el.text,
        fontSize: el.fontSize, font: el.font,
        rotation: el.rotation, xScale: el.xScale, yScale: el.yScale, bold: el.bold,
      );
    } else if (el is KoiLabelBoxElement) {
      return KoiLabelBoxElement(
        x: el.x + dx, y: el.y + dy, width: el.width, height: el.height, thickness: el.thickness,
      );
    } else if (el is KoiPositionedBarcodeElement) {
      return KoiPositionedBarcodeElement(
        x: el.x + dx, y: el.y + dy, data: el.data, height: el.height, type: el.type,
      );
    } else if (el is KoiPositionedQrCodeElement) {
      return KoiPositionedQrCodeElement(
        x: el.x + dx, y: el.y + dy, data: el.data, cellSize: el.cellSize,
      );
    } else if (el is KoiLabelLineElement) {
      return KoiLabelLineElement(
        x: el.x + dx, y: el.y + dy, width: el.width, height: el.height,
      );
    } else if (el is KoiLabelReverseElement) {
      return KoiLabelReverseElement(
        x: el.x + dx, y: el.y + dy, width: el.width, height: el.height,
      );
    } else if (el is KoiLabelImageElement) {
      return KoiLabelImageElement(
        x: el.x + dx, y: el.y + dy, imageBytes: el.imageBytes, width: el.width,
      );
    }
    return el;
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final el = widget.element.element as KoiLabelElement;
    
    // Replace text placeholders with schema labels
    final processed = state.isPreviewMode ? el : _processEditMode(el, state.schema) as KoiLabelElement;

    // Use the public render method from KoiPreviewRenderer
    final innerPositioned = KoiPreviewRenderer.renderPositionedElement(processed, Colors.black, widget.scale);

    if (innerPositioned is! Positioned) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: innerPositioned.left,
      top: innerPositioned.top,
      width: innerPositioned.width,
      height: innerPositioned.height,
      child: GestureDetector(
        onTap: widget.onSelect,
        onPanStart: (details) {
          if (!widget.isSelected) widget.onSelect();
          _dragStartElement = widget.element.element;
        },
        onPanUpdate: (details) {
          if (_dragStartElement == null) return;
          final dx = (details.delta.dx / widget.scale).round();
          final dy = (details.delta.dy / widget.scale).round();
          if (dx == 0 && dy == 0) return;
          
          final current = state.elements.firstWhere((e) => e.id == widget.element.id).element as KoiLabelElement;
          final moved = _moveElement(current, dx, dy);
          state.updateElementNoHistory(widget.element.id, moved);
        },
        onPanEnd: (details) {
          if (_dragStartElement != null) {
            final current = state.elements.firstWhere((e) => e.id == widget.element.id).element;
            if (current != _dragStartElement) {
              // Create a command for history ONLY on end
              state.updateElementNoHistory(widget.element.id, _dragStartElement!);
              state.execute(UpdateElementCommand(
                elementId: widget.element.id,
                oldElement: _dragStartElement!,
                newElement: current,
              ));
            }
            _dragStartElement = null;
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: widget.isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              innerPositioned.child,
              
              if (widget.isSelected)
                Positioned(
                  top: -20,
                  right: -20,
                  child: IconButton(
                    icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                    onPressed: widget.onDelete,
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
