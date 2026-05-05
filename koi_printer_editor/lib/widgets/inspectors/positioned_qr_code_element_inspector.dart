import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class PositionedQrCodeElementInspector extends ElementInspectorBuilder<KoiPositionedQrCodeElement> {
  @override
  Widget build(BuildContext context, String elementId, KoiPositionedQrCodeElement element) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('绝对定位二维码 (Positioned QR Code)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          
          TextFormField(
            initialValue: element.data,
            decoration: const InputDecoration(
              labelText: '二维码内容 (支持 {{变量}})',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (val) {
              update(context, elementId, element.copyWith(data: val));
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  label: 'X 坐标',
                  value: element.x,
                  onChanged: (v) => update(context, elementId, element.copyWith(x: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumberField(
                  label: 'Y 坐标',
                  value: element.y,
                  onChanged: (v) => update(context, elementId, element.copyWith(y: v)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildNumberField(
            label: '单元格大小 (模块宽度)',
            value: element.cellSize,
            onChanged: (v) => update(context, elementId, element.copyWith(cellSize: v)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required String label,
    required int value,
    required void Function(int) onChanged,
  }) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder(), isDense: true),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (v) {
        final parsed = int.tryParse(v);
        if (parsed != null) {
          onChanged(parsed);
        }
      },
    );
  }
}
