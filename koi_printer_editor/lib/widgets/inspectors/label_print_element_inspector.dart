import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelPrintElementInspector
    extends ElementInspectorBuilder<KoiLabelPrintElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelPrintElement element,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '打印触发指令 (Print)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: element.copies.toString(),
                  decoration: const InputDecoration(
                    labelText: '份数',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) {
                      update(
                        context,
                        elementId,
                        KoiLabelPrintElement(
                          copies: parsed,
                          sets: element.sets,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: element.sets.toString(),
                  decoration: const InputDecoration(
                    labelText: '套数',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (v) {
                    final parsed = int.tryParse(v);
                    if (parsed != null) {
                      update(
                        context,
                        elementId,
                        KoiLabelPrintElement(
                          copies: element.copies,
                          sets: parsed,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '提示：此组件用于触发实际打印操作，通常放在标签模板的最后。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
