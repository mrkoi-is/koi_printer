import 'package:flutter/material.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/widgets/element_inspector_registry.dart';
import 'package:provider/provider.dart';

// 引入具体的 Inspector Builders
import 'package:koi_printer_editor/widgets/inspectors/text_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/qr_code_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/barcode_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/text_row_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/ticket_for_each_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/label_box_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/label_setup_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/positioned_text_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/positioned_barcode_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/positioned_qr_code_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/label_line_element_inspector.dart';
import 'package:koi_printer_editor/widgets/inspectors/label_reverse_element_inspector.dart';
import 'package:koi_printer/koi_printer.dart'; // 需要导出相关模型类

class RightInspector extends StatefulWidget {
  const RightInspector({super.key});

  @override
  State<RightInspector> createState() => _RightInspectorState();
}

class _RightInspectorState extends State<RightInspector> {
  @override
  void initState() {
    super.initState();
    InspectorRegistry.instance.ensureInitialized((r) {
      r.register<KoiTextElement>(TextElementInspector());
      r.register<KoiQrCodeElement>(QrCodeElementInspector());
      r.register<KoiBarcodeElement>(BarcodeElementInspector());
      r.register<KoiTicketForEachElement>(TicketForEachElementInspector());
      r.register<KoiTextRowElement>(TextRowElementInspector());
      r.register<KoiLabelBoxElement>(LabelBoxElementInspector());
      r.register<KoiLabelSetupElement>(LabelSetupElementInspector());
      r.register<KoiPositionedTextElement>(PositionedTextElementInspector());
      r.register<KoiPositionedBarcodeElement>(PositionedBarcodeElementInspector());
      r.register<KoiPositionedQrCodeElement>(PositionedQrCodeElementInspector());
      r.register<KoiLabelLineElement>(LabelLineElementInspector());
      r.register<KoiLabelReverseElement>(LabelReverseElementInspector());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);
    final selectedId = state.selectedElementId;

    if (selectedId == null) {
      return _buildEmptyContainer(theme, '未选中任何组件');
    }

    final selectedEditorElement = state.elements.where((e) => e.id == selectedId).firstOrNull;
    if (selectedEditorElement == null) {
       return const SizedBox(width: 300);
    }

    final selectedElement = selectedEditorElement.element;

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              '属性面板 - ${selectedElement.runtimeType.toString().replaceAll('Koi', '').replaceAll('Element', '')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                InspectorRegistry.instance.buildInspector(context, selectedId, selectedElement),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContainer(ThemeData theme, String text) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(left: BorderSide(color: theme.dividerColor)),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.grey))),
    );
  }
}

