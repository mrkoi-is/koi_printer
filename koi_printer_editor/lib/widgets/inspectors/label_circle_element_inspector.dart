import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelCircleElementInspector
    extends ElementInspectorBuilder<KoiLabelCircleElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelCircleElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        _buildNumberField(
          label: '直径',
          value: element.diameter,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(diameter: v)),
        ),
        const SizedBox(height: 16),
        _buildNumberField(
          label: '线条粗细',
          value: element.thickness,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(thickness: v)),
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
