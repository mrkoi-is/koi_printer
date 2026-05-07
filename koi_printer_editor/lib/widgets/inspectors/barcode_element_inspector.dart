import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:koi_printer_editor/widgets/utils/data_binding_field.dart';

class BarcodeElementInspector
    extends ElementInspectorBuilder<KoiBarcodeElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiBarcodeElement element,
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
                '条码数据 (Data)',
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
              const SizedBox(height: 16),
              DropdownButtonFormField<KoiBarcodeType>(
                initialValue: element.type,
                decoration: const InputDecoration(
                  labelText: '条码格式 (Format)',
                  border: OutlineInputBorder(),
                ),
                items: KoiBarcodeType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.name.toUpperCase()),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    update(context, elementId, element.copyWith(type: val));
                  }
                },
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
                '宽度比例',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Slider(
                value: element.width.toDouble(),
                min: 2,
                max: 6,
                divisions: 4,
                label: 'Width ${element.width}',
                onChanged: (val) {
                  update(
                    context,
                    elementId,
                    element.copyWith(width: val.toInt()),
                  );
                },
              ),

              const SizedBox(height: 16),
              const Text(
                '条码高度 (点数)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Slider(
                value: element.height.toDouble(),
                min: 20,
                max: 160,
                divisions: 14,
                label: '${element.height} px',
                onChanged: (val) {
                  update(
                    context,
                    elementId,
                    element.copyWith(height: val.toInt()),
                  );
                },
              ),

              const SizedBox(height: 16),
              DropdownButtonFormField<KoiBarcodeTextPosition>(
                initialValue: element.textPosition,
                decoration: const InputDecoration(
                  labelText: '文字位置 (HRI)',
                  border: OutlineInputBorder(),
                ),
                items: KoiBarcodeTextPosition.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    update(
                      context,
                      elementId,
                      element.copyWith(textPosition: val),
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
