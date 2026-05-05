// ignore_for_file: lines_longer_than_80_chars, avoid_redundant_argument_values // rationale: test files
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';

void main() {
  group('KoiElementEditor', () {
    testWidgets('renders fallback text for unsupported element', (
      tester,
    ) async {
      const element = KoiCutElement();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KoiElementEditor(
              element: element,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.textContaining('此元素暂不支持编辑'), findsOneWidget);
    });

    testWidgets('edits KoiTextElement successfully', (tester) async {
      const element = KoiTextElement(text: 'Initial Text');
      Object? updatedElement;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KoiElementEditor(
              element: element,
              onChanged: (val) => updatedElement = val,
            ),
          ),
        ),
      );

      final textFinder = find.widgetWithText(TextFormField, '文本内容 (Text)');
      expect(textFinder, findsOneWidget);

      await tester.enterText(textFinder, 'New Text');
      await tester.pump();

      expect(updatedElement, isA<KoiTextElement>());
      expect((updatedElement! as KoiTextElement).text, 'New Text');
    });

    testWidgets('edits KoiBarcodeElement successfully', (tester) async {
      const element = KoiBarcodeElement(data: '12345');
      Object? updatedElement;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KoiElementEditor(
              element: element,
              onChanged: (val) => updatedElement = val,
            ),
          ),
        ),
      );

      final dataFinder = find.widgetWithText(TextFormField, '条码数据 (Data)');
      expect(dataFinder, findsOneWidget);

      await tester.enterText(dataFinder, '54321');
      await tester.pump();

      expect(updatedElement, isA<KoiBarcodeElement>());
      expect((updatedElement! as KoiBarcodeElement).data, '54321');
    });

    testWidgets('updates controllers when element prop changes', (
      tester,
    ) async {
      const element1 = KoiTextElement(text: 'Text 1');
      const element2 = KoiTextElement(text: 'Text 2');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KoiElementEditor(
              element: element1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Text 1'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KoiElementEditor(
              element: element2,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Text 2'), findsOneWidget);
    });
    testWidgets('edits KoiTextElement switches and dropdowns', (tester) async {
      const element = KoiTextElement(text: 'Initial Text');
      Object? updatedElement;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: KoiElementEditor(
            element: element,
            onChanged: (val) => updatedElement = val,
          ),
        ),
      ));

      // Test Align
      final alignFinder = find.widgetWithText(DropdownButtonFormField<KoiTextAlign>, '对齐方式 (Align)');
      expect(alignFinder, findsOneWidget);
      await tester.tap(alignFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('center').last);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiTextElement).align, KoiTextAlign.center);

      // Test Size
      final sizeFinder = find.widgetWithText(DropdownButtonFormField<KoiTextSize>, '字体大小 (Size)');
      expect(sizeFinder, findsOneWidget);
      await tester.tap(sizeFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('size2').last);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiTextElement).size, KoiTextSize.size2);

      // Test Bold
      final boldFinder = find.widgetWithText(SwitchListTile, '加粗 (Bold)');
      expect(boldFinder, findsOneWidget);
      await tester.tap(boldFinder);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiTextElement).bold, true);

      // Test Reverse
      final reverseFinder = find.widgetWithText(SwitchListTile, '反白 (Reverse)');
      expect(reverseFinder, findsOneWidget);
      await tester.tap(reverseFinder);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiTextElement).reverse, true);
    });

    testWidgets('edits KoiBarcodeElement align', (tester) async {
      const element = KoiBarcodeElement(data: '12345');
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      final alignFinder = find.widgetWithText(DropdownButtonFormField<KoiTextAlign>, '对齐方式 (Align)');
      await tester.tap(alignFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('center').last);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiBarcodeElement).align, KoiTextAlign.center);
    });

    testWidgets('edits KoiQrCodeElement align', (tester) async {
      const element = KoiQrCodeElement(data: '123');
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      final alignFinder = find.widgetWithText(DropdownButtonFormField<KoiTextAlign>, '对齐方式 (Align)');
      await tester.tap(alignFinder);
      await tester.pumpAndSettle();
      await tester.tap(find.text('center').last);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiQrCodeElement).align, KoiTextAlign.center);
    });

    testWidgets('edits KoiPositionedTextElement X Y and Bold', (tester) async {
      const element = KoiPositionedTextElement(text: 'Pos', x: 10, y: 20);
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      final xFinder = find.widgetWithText(TextFormField, 'X');
      final yFinder = find.widgetWithText(TextFormField, 'Y');
      
      await tester.enterText(xFinder, '15');
      await tester.pump();
      expect((updatedElement! as KoiPositionedTextElement).x, 15);

      await tester.enterText(yFinder, '25');
      await tester.pump();
      expect((updatedElement! as KoiPositionedTextElement).y, 25);

      final boldFinder = find.widgetWithText(SwitchListTile, '加粗 (Bold)');
      await tester.tap(boldFinder);
      await tester.pumpAndSettle();
      expect((updatedElement! as KoiPositionedTextElement).bold, true);
    });

    testWidgets('edits KoiPositionedBarcodeElement X Y and Data', (tester) async {
      const element = KoiPositionedBarcodeElement(data: '123', x: 10, y: 20);
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      await tester.enterText(find.widgetWithText(TextFormField, 'X'), '15');
      await tester.pump();
      expect((updatedElement! as KoiPositionedBarcodeElement).x, 15);

      await tester.enterText(find.widgetWithText(TextFormField, 'Y'), '25');
      await tester.pump();
      expect((updatedElement! as KoiPositionedBarcodeElement).y, 25);

      await tester.enterText(find.widgetWithText(TextFormField, '条码数据 (Data)'), '456');
      await tester.pump();
      expect((updatedElement! as KoiPositionedBarcodeElement).data, '456');
    });

    testWidgets('edits KoiPositionedQrCodeElement X Y and Data', (tester) async {
      const element = KoiPositionedQrCodeElement(data: '123', x: 10, y: 20);
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      await tester.enterText(find.widgetWithText(TextFormField, 'X'), '15');
      await tester.pump();
      expect((updatedElement! as KoiPositionedQrCodeElement).x, 15);

      await tester.enterText(find.widgetWithText(TextFormField, 'Y'), '25');
      await tester.pump();
      expect((updatedElement! as KoiPositionedQrCodeElement).y, 25);

      await tester.enterText(find.widgetWithText(TextFormField, 'QR数据 (Data)'), '456');
      await tester.pump();
      expect((updatedElement! as KoiPositionedQrCodeElement).data, '456');
    });

    testWidgets('edits KoiLabelBoxElement Y', (tester) async {
      const element = KoiLabelBoxElement(x: 10, y: 10, width: 100, height: 100, thickness: 2);
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      await tester.enterText(find.widgetWithText(TextFormField, 'X'), '15');
      await tester.pump();
      expect((updatedElement! as KoiLabelBoxElement).x, 15);

      await tester.enterText(find.widgetWithText(TextFormField, 'Y'), '25');
      await tester.pump();
      expect((updatedElement! as KoiLabelBoxElement).y, 25);
    });

    testWidgets('edits KoiLabelReverseElement X Y', (tester) async {
      const element = KoiLabelReverseElement(x: 10, y: 10, width: 100, height: 100);
      Object? updatedElement;
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: KoiElementEditor(element: element, onChanged: (val) => updatedElement = val))));

      await tester.enterText(find.widgetWithText(TextFormField, 'X'), '15');
      await tester.pump();
      expect((updatedElement! as KoiLabelReverseElement).x, 15);

      await tester.enterText(find.widgetWithText(TextFormField, 'Y'), '25');
      await tester.pump();
      expect((updatedElement! as KoiLabelReverseElement).y, 25);
    });
  });
}
