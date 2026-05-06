import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

/// PDF417 条码属性编辑面板。
class LabelPdf417ElementInspector
    extends ElementInspectorBuilder<KoiLabelPdf417Element> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelPdf417Element element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField(
          label: 'X 坐标',
          value: element.x,
          onChanged: (v) => update(context, elementId, element.copyWith(x: v)),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          label: 'Y 坐标',
          value: element.y,
          onChanged: (v) => update(context, elementId, element.copyWith(y: v)),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          label: '宽度',
          value: element.width,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(width: v)),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          label: '高度',
          value: element.height,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(height: v)),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          label: '纠错等级 (0-8)',
          value: element.errorLevel,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(errorLevel: v)),
        ),
        const SizedBox(height: 8),
        _buildNumberField(
          label: '列数 (1-30)',
          value: element.columns,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(columns: v)),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: element.data,
          decoration: const InputDecoration(
            labelText: '条码数据',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(data: v)),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }
}
