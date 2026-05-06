import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class PositionedTextElementInspector
    extends ElementInspectorBuilder<KoiPositionedTextElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiPositionedTextElement element,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '绝对定位文本 (Positioned Text)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: element.text,
            decoration: const InputDecoration(
              labelText: '文本内容 (支持 {{变量}})',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) {
              update(
                context,
                elementId,
                KoiPositionedTextElement(
                  x: element.x,
                  y: element.y,
                  text: val,
                  fontSize: element.fontSize,
                  font: element.font,
                  rotation: element.rotation,
                  xScale: element.xScale,
                  yScale: element.yScale,
                  bold: element.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: element.x.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'X 坐标 (dot)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final x = int.tryParse(val);
                    if (x != null) {
                      update(
                        context,
                        elementId,
                        KoiPositionedTextElement(
                          x: x,
                          y: element.y,
                          text: element.text,
                          fontSize: element.fontSize,
                          font: element.font,
                          rotation: element.rotation,
                          xScale: element.xScale,
                          yScale: element.yScale,
                          bold: element.bold,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: element.y.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Y 坐标 (dot)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final y = int.tryParse(val);
                    if (y != null) {
                      update(
                        context,
                        elementId,
                        KoiPositionedTextElement(
                          x: element.x,
                          y: y,
                          text: element.text,
                          fontSize: element.fontSize,
                          font: element.font,
                          rotation: element.rotation,
                          xScale: element.xScale,
                          yScale: element.yScale,
                          bold: element.bold,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: element.xScale.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '横向倍宽 (1-10)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final s = int.tryParse(val);
                    if (s != null && s >= 1 && s <= 10) {
                      update(
                        context,
                        elementId,
                        KoiPositionedTextElement(
                          x: element.x,
                          y: element.y,
                          text: element.text,
                          fontSize: element.fontSize,
                          font: element.font,
                          rotation: element.rotation,
                          xScale: s,
                          yScale: element.yScale,
                          bold: element.bold,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: element.yScale.toString(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: '纵向倍高 (1-10)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final s = int.tryParse(val);
                    if (s != null && s >= 1 && s <= 10) {
                      update(
                        context,
                        elementId,
                        KoiPositionedTextElement(
                          x: element.x,
                          y: element.y,
                          text: element.text,
                          fontSize: element.fontSize,
                          font: element.font,
                          rotation: element.rotation,
                          xScale: element.xScale,
                          yScale: s,
                          bold: element.bold,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('加粗显示', style: TextStyle(fontSize: 14)),
            value: element.bold,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) {
              update(
                context,
                elementId,
                KoiPositionedTextElement(
                  x: element.x,
                  y: element.y,
                  text: element.text,
                  fontSize: element.fontSize,
                  font: element.font,
                  rotation: element.rotation,
                  xScale: element.xScale,
                  yScale: element.yScale,
                  bold: val,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
