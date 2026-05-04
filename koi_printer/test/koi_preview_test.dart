// 测试: KoiPreviewRenderer — Widget 测试
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  Ticket Preview (Flow Layout / 小票预览)
  // ════════════════════════════════════════════════════════════

  group('KoiPreviewRenderer ticket', () {
    testWidgets('renders empty ticket document', (tester) async {
      const doc = KoiTicketDocument(elements: []);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders TextElement', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiTextElement(text: '测试文本')]);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('测试文本'), findsOneWidget);
    });

    testWidgets('renders TextElement with bold and size', (tester) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(text: 'Bold', bold: true, size: KoiTextSize.size2),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Bold'), findsOneWidget);
    });

    testWidgets('renders TextElement with reverse', (tester) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(
            text: 'Reversed',
            reverse: true,
            align: KoiTextAlign.center,
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Reversed'), findsOneWidget);
    });

    testWidgets('renders TextElement with right alignment', (tester) async {
      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Right', align: KoiTextAlign.right)],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('renders TextElement with all sizes', (tester) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(text: 'S1'),
          KoiTextElement(text: 'S2', size: KoiTextSize.size2),
          KoiTextElement(text: 'S3', size: KoiTextSize.size3),
          KoiTextElement(text: 'S4', size: KoiTextSize.size4),
          KoiTextElement(text: 'S5', size: KoiTextSize.size5),
          KoiTextElement(text: 'S6', size: KoiTextSize.size6),
          KoiTextElement(text: 'S7', size: KoiTextSize.size7),
          KoiTextElement(text: 'S8', size: KoiTextSize.size8),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: widget),
          ),
        ),
      );
      expect(find.text('S1'), findsOneWidget);
      expect(find.text('S8'), findsOneWidget);
    });

    testWidgets('renders TextRowElement', (tester) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: 'Left', ratio: 6),
              KoiTextColumn(
                text: 'Center',
                ratio: 3,
                align: KoiTextAlign.center,
              ),
              KoiTextColumn(text: 'Right', ratio: 3, align: KoiTextAlign.right),
            ],
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('renders TextRowElement with bold column', (tester) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextRowElement(
            columns: [KoiTextColumn(text: 'Bold', ratio: 6, bold: true)],
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Bold'), findsOneWidget);
    });

    testWidgets('renders QrCodeElement', (tester) async {
      const doc = KoiTicketDocument(
        elements: [KoiQrCodeElement(data: 'https://example.com')],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('renders BarcodeElement', (tester) async {
      const doc = KoiTicketDocument(
        elements: [KoiBarcodeElement(data: '123456789')],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      // Check barcode text is rendered
      expect(find.text('123456789'), findsOneWidget);
    });

    testWidgets('renders DividerElement', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiDividerElement()]);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders DividerElement with custom char', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiDividerElement(char: '=')]);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders SpacerElement', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiSpacerElement(lines: 3)]);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders CutElement', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiCutElement()]);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      // Cut renders a dashed line + scissors icon
      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('renders TicketImageElement', (tester) async {
      // 1x1 红色 PNG (最小有效 PNG)
      final pngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, // PNG 签名
        0x00, 0x00, 0x00, 0x0d, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xde, 0x00, 0x00, 0x00, 0x0c, 0x49, 0x44, 0x41, // IDAT chunk
        0x54, 0x08, 0xd7, 0x63, 0xf8, 0xcf, 0xc0, 0x00,
        0x00, 0x00, 0x02, 0x00, 0x01, 0xe2, 0x21, 0xbc,
        0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4e, // IEND chunk
        0x44, 0xae, 0x42, 0x60, 0x82,
      ]);
      final doc = KoiTicketDocument(
        elements: [
          KoiTicketImageElement(
            imageBytes: pngBytes,
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders complex document with multiple elements', (
      tester,
    ) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(
            text: 'Header',
            bold: true,
            align: KoiTextAlign.center,
          ),
          KoiDividerElement(),
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: 'Item', ratio: 6),
              KoiTextColumn(text: '10.00', ratio: 6, align: KoiTextAlign.right),
            ],
          ),
          KoiSpacerElement(),
          KoiQrCodeElement(data: 'https://pay.example.com'),
          KoiCutElement(),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Item'), findsOneWidget);
    });

    testWidgets('renders with custom parameters', (tester) async {
      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Custom')]);
      final widget = KoiPreviewRenderer.build(
        document: doc,
        paperWidthPx: 300,
        backgroundColor: Colors.grey,
        textColor: Colors.blue,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Custom'), findsOneWidget);
    });

    testWidgets('renders ForEachElement silently (passthrough)', (
      tester,
    ) async {
      const doc = KoiTicketDocument(
        elements: [
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [KoiTextElement(text: '{{name}}')],
          ),
        ],
      );
      // ForEach isn't rendered in preview, it should pass through silently
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Column), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  Label Preview (Positioned Layout / 标签预览)
  // ════════════════════════════════════════════════════════════

  group('KoiPreviewRenderer label', () {
    testWidgets('renders label document with setup', (tester) async {
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40)],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders positioned text', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiPositionedTextElement(x: 10, y: 10, text: 'Label Text'),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Label Text'), findsOneWidget);
    });

    testWidgets('renders positioned barcode', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiPositionedBarcodeElement(
            x: 10,
            y: 10,
            data: 'BC123',
            height: 50,
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('BC123'), findsOneWidget);
    });

    testWidgets('renders positioned QR code', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiPositionedQrCodeElement(
            x: 10,
            y: 10,
            data: 'qr-data',
            cellSize: 4,
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders box element', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiLabelBoxElement(x: 5, y: 5, width: 50, height: 30),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders reverse element', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiLabelReverseElement(x: 10, y: 10, width: 30, height: 20),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders empty label document', (tester) async {
      const doc = KoiLabelDocument(elements: []);
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('renders complex label with all elements', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 80, heightMm: 50),
          KoiPositionedTextElement(x: 5, y: 5, text: '标题', bold: true),
          KoiPositionedBarcodeElement(
            x: 5,
            y: 30,
            data: 'BC-001',
            height: 40,
          ),
          KoiPositionedQrCodeElement(
            x: 200,
            y: 5,
            data: 'https://qr.test',
            cellSize: 3,
          ),
          KoiLabelBoxElement(x: 0, y: 0, width: 300, height: 200, thickness: 1),
          KoiLabelReverseElement(x: 10, y: 10, width: 50, height: 20),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('标题'), findsOneWidget);
      expect(find.text('BC-001'), findsOneWidget);
    });

    testWidgets('renders with custom colors', (tester) async {
      const doc = KoiLabelDocument(
        elements: [KoiPositionedTextElement(x: 0, y: 0, text: 'Color Test')],
      );
      final widget = KoiPreviewRenderer.build(
        document: doc,
        paperWidthPx: 384,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.text('Color Test'), findsOneWidget);
    });

    testWidgets('renders ForEachElement silently in label', (tester) async {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(
            listKey: 'items',
            templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{name}}')],
          ),
        ],
      );
      final widget = KoiPreviewRenderer.build(document: doc, paperWidthPx: 384);
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      expect(find.byType(Stack), findsWidgets);
    });
  });
}
