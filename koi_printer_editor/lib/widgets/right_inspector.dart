import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

class RightInspector extends StatelessWidget {
  const RightInspector({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final selectedId = state.selectedElementId;

    if (selectedId == null) {
      return Container(
        width: 300,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(left: BorderSide(color: theme.dividerColor)),
        ),
        child: const Center(child: Text('未选中任何组件', style: TextStyle(color: Colors.grey))),
      );
    }

    final selectedEditorElement = state.elements.where((e) => e.id == selectedId).firstOrNull;
    if (selectedEditorElement == null) {
       return const SizedBox(width: 300);
    }

    final selectedElement = selectedEditorElement.element;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '属性面板 - ${selectedElement.runtimeType}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (selectedElement is KoiTextElement) ...[
                  TextFormField(
                    initialValue: selectedElement.text,
                    decoration: const InputDecoration(labelText: '文本内容', border: OutlineInputBorder()),
                    maxLines: 3,
                    onChanged: (val) {
                      context.read<EditorState>().execute(
                        UpdateElementCommand(
                          elementId: selectedId,
                          oldElement: selectedElement,
                          newElement: KoiTextElement(
                            text: val,
                            size: selectedElement.size,
                            widthSize: selectedElement.widthSize,
                            heightSize: selectedElement.heightSize,
                            align: selectedElement.align,
                            bold: selectedElement.bold,
                            reverse: selectedElement.reverse,
                            underline: selectedElement.underline,
                            underlineStyle: selectedElement.underlineStyle,
                            font: selectedElement.font,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<KoiTextAlign>(
                    value: selectedElement.align,
                    decoration: const InputDecoration(labelText: '对齐方式'),
                    items: KoiTextAlign.values.map((a) => DropdownMenuItem(value: a, child: Text(a.name))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        context.read<EditorState>().execute(
                          UpdateElementCommand(
                            elementId: selectedId,
                            oldElement: selectedElement,
                            newElement: KoiTextElement(
                              text: selectedElement.text,
                              size: selectedElement.size,
                              widthSize: selectedElement.widthSize,
                              heightSize: selectedElement.heightSize,
                              align: val,
                              bold: selectedElement.bold,
                              reverse: selectedElement.reverse,
                              underline: selectedElement.underline,
                              underlineStyle: selectedElement.underlineStyle,
                              font: selectedElement.font,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('加粗 (Bold)'),
                    value: selectedElement.bold,
                    onChanged: (val) {
                      context.read<EditorState>().execute(
                        UpdateElementCommand(
                          elementId: selectedId,
                          oldElement: selectedElement,
                          newElement: KoiTextElement(
                              text: selectedElement.text,
                              size: selectedElement.size,
                              widthSize: selectedElement.widthSize,
                              heightSize: selectedElement.heightSize,
                              align: selectedElement.align,
                              bold: val,
                              reverse: selectedElement.reverse,
                              underline: selectedElement.underline,
                              underlineStyle: selectedElement.underlineStyle,
                              font: selectedElement.font,
                            ),
                        ),
                      );
                    },
                  ),
                ] else if (selectedElement is KoiQrCodeElement) ...[
                  TextFormField(
                    initialValue: selectedElement.data,
                    decoration: const InputDecoration(labelText: '二维码内容', border: OutlineInputBorder()),
                    onChanged: (val) {
                      context.read<EditorState>().execute(
                        UpdateElementCommand(
                          elementId: selectedId,
                          oldElement: selectedElement,
                          newElement: KoiQrCodeElement(
                            data: val,
                            size: selectedElement.size,
                            strategy: selectedElement.strategy,
                            correction: selectedElement.correction,
                            align: selectedElement.align,
                          ),
                        ),
                      );
                    },
                  ),
                ] else ...[
                   const Text('暂无可用属性配置', style: TextStyle(color: Colors.grey)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
