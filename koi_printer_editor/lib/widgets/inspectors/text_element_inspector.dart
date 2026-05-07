import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:koi_printer_editor/widgets/utils/data_binding_field.dart';

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

  Widget _buildDataSection(
    BuildContext context,
    String elementId,
    KoiTextElement element,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '数据绑定 (Data)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),
          DataBindingField(
            text: element.text,
            onUpdate: (newText) =>
                update(context, elementId, element.copyWith(text: newText)),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleSection(
    BuildContext context,
    String elementId,
    KoiTextElement element,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '排版与样式 (Typography)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 12),

          // 对齐方式 (Alignment)
          const Text(
            '对齐方式',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          SegmentedButton<KoiTextAlign>(
            segments: const [
              ButtonSegment(
                value: KoiTextAlign.left,
                icon: Icon(Icons.format_align_left),
                label: Text('左'),
              ),
              ButtonSegment(
                value: KoiTextAlign.center,
                icon: Icon(Icons.format_align_center),
                label: Text('中'),
              ),
              ButtonSegment(
                value: KoiTextAlign.right,
                icon: Icon(Icons.format_align_right),
                label: Text('右'),
              ),
            ],
            selected: {element.align},
            onSelectionChanged: (set) =>
                update(context, elementId, element.copyWith(align: set.first)),
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
                onSelected: (val) =>
                    update(context, elementId, element.copyWith(bold: val)),
              ),
              FilterChip(
                label: const Text('反白'),
                selected: element.reverse,
                onSelected: (val) =>
                    update(context, elementId, element.copyWith(reverse: val)),
              ),
              FilterChip(
                label: const Text('下划线'),
                selected: element.underline,
                onSelected: (val) => update(
                  context,
                  elementId,
                  element.copyWith(underline: val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          // 字体大小
          const Text(
            '整体缩放倍数 (基础大小)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: element.size.index.toDouble(),
            min: 0,
            max: 7,
            divisions: 7,
            label: '${element.size.index + 1}x',
            onChanged: (val) {
              update(
                context,
                elementId,
                element.copyWith(size: KoiTextSize.values[val.toInt()]),
              );
            },
          ),

          const SizedBox(height: 8),
          const Text(
            '独立倍宽 (选填，覆盖基础宽度)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: element.widthSize != null
                ? element.widthSize!.index.toDouble()
                : -1,
            min: -1,
            max: 7,
            divisions: 8,
            label: element.widthSize != null
                ? '${element.widthSize!.index + 1}x'
                : '随整体缩放',
            onChanged: (val) {
              final newWidthSize = val == -1
                  ? null
                  : KoiTextSize.values[val.toInt()];
              update(
                context,
                elementId,
                element.copyWith(
                  widthSize: newWidthSize,
                  clearWidthSize: newWidthSize == null,
                ),
              );
            },
          ),

          const SizedBox(height: 8),
          const Text(
            '独立倍高 (选填，覆盖基础高度)',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Slider(
            value: element.heightSize != null
                ? element.heightSize!.index.toDouble()
                : -1,
            min: -1,
            max: 7,
            divisions: 8,
            label: element.heightSize != null
                ? '${element.heightSize!.index + 1}x'
                : '随整体缩放',
            onChanged: (val) {
              final newHeightSize = val == -1
                  ? null
                  : KoiTextSize.values[val.toInt()];
              update(
                context,
                elementId,
                element.copyWith(
                  heightSize: newHeightSize,
                  clearHeightSize: newHeightSize == null,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
