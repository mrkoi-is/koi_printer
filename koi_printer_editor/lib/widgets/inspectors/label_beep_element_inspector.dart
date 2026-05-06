import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelBeepElementInspector
    extends ElementInspectorBuilder<KoiLabelBeepElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelBeepElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField(
          label: '蜂鸣等级/次数',
          value: element.level,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(level: v)),
        ),
        const SizedBox(height: 16),
        _buildNumberField(
          label: '间隔/时长',
          value: element.interval,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(interval: v)),
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
