import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class LabelImageElementInspector extends ElementInspectorBuilder<KoiLabelImageElement> {
  @override
  Widget build(BuildContext context, String elementId, KoiLabelImageElement element) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('绝对图片 (Image)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
            label: '打印宽度 (留空保持原比例)',
            value: element.width ?? 0,
            onChanged: (v) => update(context, elementId, element.copyWith(width: v == 0 ? null : v)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // 实际项目中应调用文件选择器或图片裁剪工具
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('此处需集成图片选择器')));
            },
            icon: const Icon(Icons.image),
            label: const Text('替换图片'),
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
