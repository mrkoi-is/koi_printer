import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:provider/provider.dart';

class TextElementInspector extends ElementInspectorBuilder<KoiTextElement> {
  @override
  Widget build(BuildContext context, String elementId, KoiTextElement element) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDataSection(context, elementId, element),
        const Divider(),
        _buildStyleSection(context, elementId, element),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context, String elementId, KoiTextElement element) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('数据绑定 (Data)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
          const SizedBox(height: 12),
          _DataBindingField(
            elementId: elementId,
            element: element,
            onUpdate: (newText) => update(context, elementId, element.copyWith(text: newText)),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSection(BuildContext context, String elementId, KoiTextElement element) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('排版与样式 (Typography)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
          const SizedBox(height: 12),
          
          // 对齐方式 (Alignment)
          const Text('对齐方式', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          SegmentedButton<KoiTextAlign>(
            segments: const [
              ButtonSegment(value: KoiTextAlign.left, icon: Icon(Icons.format_align_left), label: Text('左')),
              ButtonSegment(value: KoiTextAlign.center, icon: Icon(Icons.format_align_center), label: Text('中')),
              ButtonSegment(value: KoiTextAlign.right, icon: Icon(Icons.format_align_right), label: Text('右')),
            ],
            selected: {element.align},
            onSelectionChanged: (set) => update(context, elementId, element.copyWith(align: set.first)),
          ),
          
          const SizedBox(height: 16),
          // 开关组: 加粗、反白、下划线
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('加粗'),
                selected: element.bold,
                onSelected: (val) => update(context, elementId, element.copyWith(bold: val)),
              ),
              FilterChip(
                label: const Text('反白'),
                selected: element.reverse,
                onSelected: (val) => update(context, elementId, element.copyWith(reverse: val)),
              ),
              FilterChip(
                label: const Text('下划线'),
                selected: element.underline,
                onSelected: (val) => update(context, elementId, element.copyWith(underline: val)),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // 字体大小
          const Text('整体缩放倍数 (基础大小)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(
            value: element.size.index.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            label: '${element.size.index + 1}x',
            onChanged: (val) {
              update(context, elementId, element.copyWith(size: KoiTextSize.values[val.toInt()]));
            },
          ),

          const SizedBox(height: 8),
          const Text('独立倍宽 (选填，覆盖基础宽度)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(
            value: element.widthSize != null ? element.widthSize!.index.toDouble() : -1,
            min: -1,
            max: 7,
            divisions: 8,
            label: element.widthSize != null ? '${element.widthSize!.index + 1}x' : '随整体缩放',
            onChanged: (val) {
              final newWidthSize = val == -1 ? null : KoiTextSize.values[val.toInt()];
              update(context, elementId, element.copyWith(
                widthSize: newWidthSize,
                clearWidthSize: newWidthSize == null,
              ));
            },
          ),

          const SizedBox(height: 8),
          const Text('独立倍高 (选填，覆盖基础高度)', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Slider(
            value: element.heightSize != null ? element.heightSize!.index.toDouble() : -1,
            min: -1,
            max: 7,
            divisions: 8,
            label: element.heightSize != null ? '${element.heightSize!.index + 1}x' : '随整体缩放',
            onChanged: (val) {
              final newHeightSize = val == -1 ? null : KoiTextSize.values[val.toInt()];
              update(context, elementId, element.copyWith(
                heightSize: newHeightSize,
                clearHeightSize: newHeightSize == null,
              ));
            },
          ),
        ],
      ),
    );
  }
}

class _DataBindingField extends StatefulWidget {
  const _DataBindingField({required this.elementId, required this.element, required this.onUpdate});
  final String elementId;
  final KoiTextElement element;
  final ValueChanged<String> onUpdate;

  @override
  State<_DataBindingField> createState() => _DataBindingFieldState();
}

class _DataBindingFieldState extends State<_DataBindingField> {
  int _modeIndex = 0;

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

  @override
  Widget build(BuildContext context) {
    final fields = context.watch<EditorState>().schema;
    final text = widget.element.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                 widget.onUpdate('{{${fields.first.key}}}');
              }
            } else if (_modeIndex == 0) {
               widget.onUpdate(text.replaceAll(RegExp(r'\{\{|\}\}'), ''));
            }
          },
        ),
        const SizedBox(height: 12),
        if (_modeIndex == 0) ...[
           TextFormField(
             key: ValueKey('static_$text'),
             initialValue: text,
             decoration: const InputDecoration(labelText: '纯文本内容', border: OutlineInputBorder()),
             maxLines: 3,
             onChanged: widget.onUpdate,
           ),
        ] else if (_modeIndex == 1) ...[
           DropdownButtonFormField<String>(
             isExpanded: true,
             initialValue: RegExp(r'^\{\{([a-zA-Z0-9_.]+)\}\}$').firstMatch(text)?.group(1) ?? (fields.isNotEmpty ? fields.first.key : null),
             decoration: const InputDecoration(labelText: '绑定业务字段', border: OutlineInputBorder()),
             items: fields.map((f) => DropdownMenuItem(
               value: f.key, 
               child: Text('${f.label} (${f.key})', overflow: TextOverflow.ellipsis),
             )).toList(),
             onChanged: (val) {
               if (val != null) widget.onUpdate('{{$val}}');
             },
           ),
        ] else ...[
           TextFormField(
             key: ValueKey('expr_$text'),
             initialValue: text,
             decoration: const InputDecoration(labelText: '模板表达式', border: OutlineInputBorder()),
             maxLines: 3,
             onChanged: widget.onUpdate,
           ),
           const SizedBox(height: 8),
           Wrap(
             spacing: 4,
             children: fields.map((f) => ActionChip(
               label: Text(f.label, style: const TextStyle(fontSize: 10)),
               onPressed: () => widget.onUpdate('$text{{${f.key}}}'),
             )).toList(),
           )
        ]
      ],
    );
  }
}
