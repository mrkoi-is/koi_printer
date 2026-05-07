import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/widgets/left_palette.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp(EditorState state) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<EditorState>.value(
          value: state,
          child: const LeftPalette(),
        ),
      ),
    );
  }

  group('LeftPalette Components Tab Tests', () {
    testWidgets('Renders 3 tabs', (tester) async {
      final state = EditorState();
      await tester.pumpWidget(buildTestApp(state));

      expect(find.text('组件库'), findsOneWidget);
      expect(find.text('图层'), findsOneWidget);
      expect(find.text('数据源'), findsOneWidget);
    });

    testWidgets('Adds ticket elements in ticket mode', (tester) async {
      final state = EditorState();
      state.loadManifest(const KoiTemplateManifest(
        id: '1',
        name: 'Ticket',
        document: KoiTicketDocument(elements: []),
      ), []);
      await tester.pumpWidget(buildTestApp(state));

      final items = [
        '文本 (Text)', '分割线 (Divider)', '二维码 (QR Code)', '条形码 (Barcode)', '空白行 (Spacer)', '原始指令 (Raw)'
      ];
      for (final item in items) {
        final finder = find.text(item);
        if (finder.evaluate().isNotEmpty) {
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }
      }

      expect(state.elements.length, greaterThan(1));
    });

    testWidgets('Adds label elements in label mode', (tester) async {
      final state = EditorState();
      state.setExplicitLabelMode(true);
      await tester.pumpWidget(buildTestApp(state));

      final items = [
        '绝对文本 (Text)', '绝对条码 (Barcode)', '绝对二维码 (QR)', '矩形框 (Box)', '直线 (Line)', '原始指令 (Raw)'
      ];
      for (final item in items) {
        final finder = find.text(item);
        if (finder.evaluate().isNotEmpty) {
          await tester.ensureVisible(finder);
          await tester.tap(finder);
          await tester.pumpAndSettle();
        }
      }

      expect(state.elements.length, greaterThan(2));
    });
  });

  group('LeftPalette Layer Tree Tab Tests', () {
    testWidgets('Renders layer tree elements', (tester) async {
      final state = EditorState();
      state.loadManifest(const KoiTemplateManifest(
        id: '1',
        name: 'Ticket',
        document: KoiTicketDocument(elements: []),
      ), [
        EditorElement(id: '1', element: const KoiTextElement(text: 'Hello', size: KoiTextSize.size1)),
        EditorElement(id: '2', element: const KoiTicketForEachElement(listKey: 'items', templates: [])),
        EditorElement(id: '3', element: const KoiDividerElement()),
        EditorElement(id: '4', element: const KoiQrCodeElement(data: 'qr')),
        EditorElement(id: '5', element: const KoiBarcodeElement(data: 'bar')),
        EditorElement(id: '6', element: const KoiTextRowElement(columns: [])),
        EditorElement(id: '7', element: const KoiSpacerElement(lines: 1)),
        EditorElement(id: '8', element: const KoiLabelSetupElement(widthMm: 10, heightMm: 10)),
        EditorElement(id: '9', element: const KoiPositionedTextElement(text: 'pos', x: 0, y: 0)),
        EditorElement(id: '10', element: const KoiLabelBoxElement(x: 0, y: 0, width: 10, height: 10)),
        EditorElement(id: '11', element: const KoiPositionedBarcodeElement(data: 'bpos', x: 0, y: 0)),
        EditorElement(id: '12', element: const KoiPositionedQrCodeElement(data: 'qpos', x: 0, y: 0)),
        EditorElement(id: '13', element: const KoiLabelLineElement(x: 0, y: 0, width: 10, height: 1)),
        EditorElement(id: '14', element: const KoiLabelReverseElement(x: 0, y: 0, width: 10, height: 10)),
        EditorElement(id: '15', element: KoiLabelImageElement(x: 0, y: 0, width: 10, imageBytes: Uint8List(0))),
        EditorElement(id: '16', element: const KoiLabelPrintElement(copies: 1)),
        EditorElement(id: '17', element: const KoiLabelForEachElement(listKey: 'k', templates: [])),
        EditorElement(id: '18', element: const KoiRawCommandElement('raw')),
      ]);
      await tester.pumpWidget(buildTestApp(state));

      await tester.tap(find.text('图层'));
      await tester.pumpAndSettle();

      expect(find.text('文本: Hello'), findsWidgets);
      
      // Select layer
      await tester.tap(find.text('文本: Hello').first);
      await tester.pumpAndSettle();
      expect(state.selectedElementId, '1');
    });
  });

  group('LeftPalette Data Schema Tab Tests', () {
    testWidgets('Renders data schema fields', (tester) async {
      final state = EditorState();
      state.loadManifest(const KoiTemplateManifest(
        id: '1',
        name: 'Ticket',
        document: KoiTicketDocument(elements: []),
        schema: [
          KoiTemplateField(key: 'price', label: 'Price', type: KoiFieldType.string),
        ],
      ), []);
      await tester.pumpWidget(buildTestApp(state));

      await tester.tap(find.text('数据源'));
      await tester.pumpAndSettle();

      expect(find.text('{{price}}'), findsOneWidget);
      
      // Delete field
      await tester.tap(find.byIcon(Icons.delete).first);
      await tester.pumpAndSettle();
      expect(state.schema.length, 0);
      
      // Add field
      await tester.tap(find.byTooltip('添加字段'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'newKey');
      await tester.enterText(find.byType(TextField).last, 'New Label');
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      expect(state.schema.length, 1);
    });
  });
}
