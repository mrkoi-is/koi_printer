import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelFeedElementInspector
    extends ElementInspectorBuilder<KoiLabelFeedElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelFeedElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField(
          label: '走纸点数',
          value: element.dots,
          onChanged: (v) =>
              update(context, elementId, element.copyWith(dots: v)),
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
