import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelSetupElementInspector
    extends ElementInspectorBuilder<KoiLabelSetupElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiLabelSetupElement element,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '纸张设置 (Setup)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: element.widthMm.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '纸张宽度 (mm)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final width = int.tryParse(val);
                    if (width != null) {
                      update(
                        context,
                        elementId,
                        KoiLabelSetupElement(
                          widthMm: width,
                          heightMm: element.heightMm,
                          speed: element.speed,
                          density: element.density,
                          gapMm: element.gapMm,
                          dpi: element.dpi,
                          referenceX: element.referenceX,
                          referenceY: element.referenceY,
                          codepage: element.codepage,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: element.heightMm.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '纸张高度 (mm)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final height = int.tryParse(val);
                    if (height != null) {
                      update(
                        context,
                        elementId,
                        KoiLabelSetupElement(
                          widthMm: element.widthMm,
                          heightMm: height,
                          speed: element.speed,
                          density: element.density,
                          gapMm: element.gapMm,
                          dpi: element.dpi,
                          referenceX: element.referenceX,
                          referenceY: element.referenceY,
                          codepage: element.codepage,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
