import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:koi_printer_editor/widgets/utils/data_binding_field.dart';

class LabelBlockTextElementInspector
    extends ElementInspectorBuilder<KoiLabelBlockTextElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelBlockTextElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataBindingField(
          text: element.text,
          onUpdate: (v) =>
              update(context, elementId, element.copyWith(text: v)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: 'X 坐标',
                value: element.x,
                onChanged: (v) =>
                    update(context, elementId, element.copyWith(x: v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: 'Y 坐标',
                value: element.y,
                onChanged: (v) =>
                    update(context, elementId, element.copyWith(y: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                label: '宽度',
                value: element.width,
                onChanged: (v) =>
                    update(context, elementId, element.copyWith(width: v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildNumberField(
                label: '高度',
                value: element.height,
                onChanged: (v) =>
                    update(context, elementId, element.copyWith(height: v)),
              ),
            ),
          ],
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
