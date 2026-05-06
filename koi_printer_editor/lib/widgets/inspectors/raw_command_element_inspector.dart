import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class RawCommandElementInspector
    extends ElementInspectorBuilder<KoiRawCommandElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiRawCommandElement element,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '原始指令 (Raw Command)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 16),

          TextFormField(
            initialValue: element.command,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: '指令内容',
              border: OutlineInputBorder(),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
            onChanged: (val) {
              update(context, elementId, KoiRawCommandElement(val));
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '提示：可直接注入 TSPL / CPCL 打印机指令文本。',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
