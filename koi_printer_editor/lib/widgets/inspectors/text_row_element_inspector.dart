import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class TextRowElementInspector extends ElementInspectorBuilder<KoiTextRowElement> {
  @override
  Widget build(BuildContext context, String elementId, KoiTextRowElement element) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('多列排版配置 (Text Row)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
              const SizedBox(height: 12),
              
              ...element.columns.asMap().entries.map((entry) {
                final idx = entry.key;
                final col = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('列 ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                            onPressed: () {
                              if (element.columns.length <= 1) return; // 至少保留一列
                              final newCols = List<KoiTextColumn>.from(element.columns)..removeAt(idx);
                              update(context, elementId, element.copyWith(columns: newCols));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('row_${elementId}_col_${idx}_text_${col.text}'),
                        initialValue: col.text,
                        decoration: const InputDecoration(labelText: '内容', border: OutlineInputBorder()),
                        onChanged: (val) {
                          final newCols = List<KoiTextColumn>.from(element.columns);
                          newCols[idx] = col.copyWith(text: val);
                          update(context, elementId, element.copyWith(columns: newCols));
                        },
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('row_${elementId}_col_${idx}_ratio_${col.ratio}'),
                              initialValue: col.ratio.toString(),
                              decoration: const InputDecoration(labelText: '比例宽度 (Ratio)', border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                              onChanged: (val) {
                                final ratio = int.tryParse(val) ?? 1;
                                final newCols = List<KoiTextColumn>.from(element.columns);
                                newCols[idx] = col.copyWith(ratio: ratio);
                                update(context, elementId, element.copyWith(columns: newCols));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<KoiTextAlign>(
                              key: ValueKey('row_${elementId}_col_${idx}_align_${col.align}'),
                              initialValue: col.align,
                              decoration: const InputDecoration(labelText: '对齐方式', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem(value: KoiTextAlign.left, child: Text('左对齐')),
                                DropdownMenuItem(value: KoiTextAlign.center, child: Text('居中')),
                                DropdownMenuItem(value: KoiTextAlign.right, child: Text('右对齐')),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  final newCols = List<KoiTextColumn>.from(element.columns);
                                  newCols[idx] = col.copyWith(align: val);
                                  update(context, elementId, element.copyWith(columns: newCols));
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              
              OutlinedButton.icon(
                onPressed: () {
                  final newCols = List<KoiTextColumn>.from(element.columns)
                    ..add(const KoiTextColumn(text: '新列', ratio: 1));
                  update(context, elementId, element.copyWith(columns: newCols));
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('添加一列'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
