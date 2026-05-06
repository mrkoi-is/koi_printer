import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';

class TicketForEachElementInspector
    extends ElementInspectorBuilder<KoiTicketForEachElement> {
  @override
  Widget build(
    BuildContext context,
    String elementId,
    KoiTicketForEachElement element,
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
                '数据循环 (Data Loop)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: ValueKey(element.listKey),
                initialValue: element.listKey,
                decoration: const InputDecoration(
                  labelText: '绑定的数组变量 (List Key)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) =>
                    update(context, elementId, element.copyWith(listKey: val)),
              ),
              const SizedBox(height: 12),
              const Text(
                '提示：在左侧画布选中此区域后，点击左侧组件库即可向该循环内添加元素。',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
