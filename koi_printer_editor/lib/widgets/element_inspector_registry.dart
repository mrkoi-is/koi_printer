import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

abstract class ElementInspectorBuilder<T extends KoiTicketElement> {
  Widget build(BuildContext context, String elementId, T element);

  /// 封装便捷的更新钩子。从 EditorState 获取最新元素作为 oldElement，
  /// 避免闭包捕获的过期引用导致 Undo 链断裂。
  void update(BuildContext context, String elementId, T newElement) {
    final state = context.read<EditorState>();
    final current = state.elements.where((e) => e.id == elementId).firstOrNull;
    if (current == null) return;
    state.execute(
      UpdateElementCommand(
        elementId: elementId,
        oldElement: current.element,
        newElement: newElement,
      ),
    );
  }
}

class InspectorRegistry {
  InspectorRegistry._();

  static final InspectorRegistry instance = InspectorRegistry._();

  final Map<Type, ElementInspectorBuilder> _builders = {};
  bool _initialized = false;

  void register<T extends KoiTicketElement>(ElementInspectorBuilder<T> builder) {
    _builders[T] = builder;
  }

  /// 确保注册只执行一次，防止热重载时重复创建 Builder 实例。
  void ensureInitialized(void Function(InspectorRegistry r) registerFn) {
    if (_initialized) return;
    _initialized = true;
    registerFn(this);
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
