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
  });
}
