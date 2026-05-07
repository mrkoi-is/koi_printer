import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:koi_printer_editor/widgets/utils/data_binding_field.dart';

class QrCodeElementInspector extends ElementInspectorBuilder<KoiQrCodeElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiQrCodeElement element,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '二维码数据 (Data)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              DataBindingField(
                text: element.data,
                allowExpression: false,
                onUpdate: (val) =>
                    update(context, elementId, element.copyWith(data: val)),
              ),
            ],
          ),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '几何与对齐 (Geometry)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),

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
                onSelectionChanged: (set) => update(
                  context,
                  elementId,
                  element.copyWith(align: set.first),
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                '模块大小',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Slider(
                value: element.size.index.toDouble(),
                min: 0,
                max: 15,
                divisions: 15,
                label: 'Size ${element.size.index + 1}',
                onChanged: (val) {
                  update(
                    context,
                    elementId,
                    element.copyWith(size: KoiQrSize.values[val.toInt()]),
                  );
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<KoiQrCorrection>(
                initialValue: element.correction,
                decoration: const InputDecoration(
                  labelText: '纠错级别',
                  border: OutlineInputBorder(),
                ),
                items: KoiQrCorrection.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    update(
                      context,
                      elementId,
                      element.copyWith(correction: val),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
