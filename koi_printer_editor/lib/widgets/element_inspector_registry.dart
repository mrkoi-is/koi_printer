import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

abstract class ElementInspectorBuilder<T extends KoiTicketElement> {
  Widget build(BuildContext context, String elementId, T element);

  /// 封装便捷的更新钩子，避免在使用侧重复写 read[EditorState]().execute...
  void update(BuildContext context, String elementId, T oldElement, T newElement) {
    context.read<EditorState>().execute(
      UpdateElementCommand(
        elementId: elementId,
        oldElement: oldElement,
        newElement: newElement,
      ),
    );
  }
}

class InspectorRegistry {
  InspectorRegistry._();

  static final InspectorRegistry instance = InspectorRegistry._();

  final Map<Type, ElementInspectorBuilder> _builders = {};

  void register<T extends KoiTicketElement>(ElementInspectorBuilder<T> builder) {
    _builders[T] = builder;
  }

  Widget buildInspector(BuildContext context, String elementId, KoiTicketElement element) {
    final builder = _builders[element.runtimeType];
    if (builder != null) {
      // 这里的 dynamic 强转是因为 Map<Type, ...> 擦除了泛型，但我们在 register 时保证了类型对应
      return builder.build(context, elementId, element as dynamic);
    }
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text('暂无可用属性配置', style: TextStyle(color: Colors.grey)),
    );
  }
}
