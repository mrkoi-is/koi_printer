import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
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
                  _DataBindingField(
                    elementId: selectedId,
                    element: selectedElement,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<KoiTextAlign>(
                    initialValue: selectedElement.align,
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
                ] else if (selectedElement is KoiTicketForEachElement) ...[
                  TextFormField(
                    initialValue: selectedElement.listKey,
                    decoration: const InputDecoration(labelText: '绑定的数组变量 (List Key)', border: OutlineInputBorder()),
                    onChanged: (val) {
                      context.read<EditorState>().execute(
                        UpdateElementCommand(
                          elementId: selectedId,
                          oldElement: selectedElement,
                          newElement: KoiTicketForEachElement(
                            listKey: val,
                            templates: selectedElement.templates,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text('提示：在左侧画布选中此区域后，点击左侧组件库即可向该循环内添加元素。', style: TextStyle(color: Colors.grey, fontSize: 12)),
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

class _DataBindingField extends StatefulWidget {
  const _DataBindingField({required this.elementId, required this.element});
  final String elementId;
  final KoiTextElement element;

  @override
  State<_DataBindingField> createState() => _DataBindingFieldState();
}

class _DataBindingFieldState extends State<_DataBindingField> {
  int _modeIndex = 0; // 0: Static, 1: Variable, 2: Expression

  @override
  void initState() {
    super.initState();
    _determineInitialMode();
  }

  @override
  void didUpdateWidget(covariant _DataBindingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.text != widget.element.text) {
      _determineInitialMode();
    }
  }

  void _determineInitialMode() {
    final text = widget.element.text;
    final isExactVariable = RegExp(r'^\{\{([a-zA-Z0-9_.]+)\}\}$').hasMatch(text);
    final hasVariables = text.contains('{{') && text.contains('}}');
    
    if (isExactVariable) {
      _modeIndex = 1;
    } else if (hasVariables) {
      _modeIndex = 2;
    } else {
      _modeIndex = 0;
    }
  }

  void _updateText(String newText) {
    context.read<EditorState>().execute(
      UpdateElementCommand(
        elementId: widget.elementId,
        oldElement: widget.element,
        newElement: KoiTextElement(
          text: newText,
          size: widget.element.size,
          widthSize: widget.element.widthSize,
          heightSize: widget.element.heightSize,
          align: widget.element.align,
          bold: widget.element.bold,
          reverse: widget.element.reverse,
          underline: widget.element.underline,
          underlineStyle: widget.element.underlineStyle,
          font: widget.element.font,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fields = context.watch<EditorState>().schema;
    final text = widget.element.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('数据映射模式', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('静态', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 1, label: Text('单变量', style: TextStyle(fontSize: 12))),
            ButtonSegment(value: 2, label: Text('表达式', style: TextStyle(fontSize: 12))),
          ],
          selected: {_modeIndex},
          onSelectionChanged: (set) {
            setState(() {
              _modeIndex = set.first;
            });
            if (_modeIndex == 1) {
              if (!RegExp(r'^\{\{([a-zA-Z0-9_.]+)\}\}$').hasMatch(text) && fields.isNotEmpty) {
                 _updateText('{{${fields.first.key}}}');
              }
            } else if (_modeIndex == 0) {
               _updateText(text.replaceAll(RegExp(r'\{\{|\}\}'), ''));
            }
          },
        ),
        const SizedBox(height: 16),
        if (_modeIndex == 0) ...[
           TextFormField(
             initialValue: text,
             decoration: const InputDecoration(labelText: '纯文本内容', border: OutlineInputBorder()),
             maxLines: 3,
             onChanged: _updateText,
           ),
        ] else if (_modeIndex == 1) ...[
           DropdownButtonFormField<String>(
             initialValue: RegExp(r'^\{\{([a-zA-Z0-9_.]+)\}\}$').firstMatch(text)?.group(1) ?? (fields.isNotEmpty ? fields.first.key : null),
             decoration: const InputDecoration(labelText: '绑定业务字段', border: OutlineInputBorder()),
             items: fields.map((f) => DropdownMenuItem(value: f.key, child: Text('${f.label} (${f.key})'))).toList(),
             onChanged: (val) {
               if (val != null) {
                 _updateText('{{$val}}');
               }
             },
           ),
           const SizedBox(height: 8),
           Row(
             children: [
               const Icon(Icons.check_circle, color: Colors.green, size: 16),
               const SizedBox(width: 4),
               Text('已绑定: ${fields.where((f) => '{{${f.key}}}' == text).firstOrNull?.label ?? '未知'}', 
                 style: const TextStyle(color: Colors.green, fontSize: 12)),
             ],
           ),
        ] else ...[
           TextFormField(
             initialValue: text,
             decoration: const InputDecoration(labelText: '模板表达式 (支持纯文本与变量混写)', border: OutlineInputBorder()),
             maxLines: 3,
             onChanged: _updateText,
           ),
           const SizedBox(height: 8),
           const Text('点击插入变量:', style: TextStyle(fontSize: 12, color: Colors.grey)),
           Wrap(
             spacing: 4,
             children: fields.map((f) => ActionChip(
               label: Text(f.label, style: const TextStyle(fontSize: 10)),
               onPressed: () {
                 _updateText('$text{{${f.key}}}');
               },
             )).toList(),
           )
        ]
      ],
    );
  }
}

