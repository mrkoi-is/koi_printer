import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/koi_print_element_ext.dart';

/// T2: 验证 copyWith 扩展的完整性 — "只改一个字段，其余不变"。
void main() {
  group('KoiTextElement.copyWith', () {
    const original = KoiTextElement(
      text: '原始',
      size: KoiTextSize.size2,
      widthSize: KoiTextSize.size3,
      heightSize: KoiTextSize.size4,
      align: KoiTextAlign.center,
      bold: true,
      reverse: true,
      underline: true,
      underlineStyle: KoiUnderlineStyle.thin,
      font: KoiFontType.fontB,
    );

    test('只改 text，其余不变', () {
      final copy = original.copyWith(text: '新文本');
      expect(copy.text, '新文本');
      expect(copy.size, original.size);
      expect(copy.widthSize, original.widthSize);
      expect(copy.heightSize, original.heightSize);
      expect(copy.align, original.align);
      expect(copy.bold, original.bold);
      expect(copy.reverse, original.reverse);
      expect(copy.underline, original.underline);
      expect(copy.underlineStyle, original.underlineStyle);
      expect(copy.font, original.font);
    });

    test('只改 bold 为 false', () {
      final copy = original.copyWith(bold: false);
      expect(copy.bold, false);
      expect(copy.text, original.text);
      expect(copy.reverse, original.reverse);
    });

    test('不传任何参数返回等价副本', () {
      final copy = original.copyWith();
      expect(copy.text, original.text);
      expect(copy.size, original.size);
      expect(copy.align, original.align);
      expect(copy.bold, original.bold);
      expect(copy.reverse, original.reverse);
      expect(copy.underline, original.underline);
    });
  });

  group('KoiQrCodeElement.copyWith', () {
    const original = KoiQrCodeElement(
      data: 'https://example.com',
      size: KoiQrSize.size6,
      correction: KoiQrCorrection.quartile,
      align: KoiTextAlign.right,
    );

    test('只改 data', () {
      final copy = original.copyWith(data: 'new');
      expect(copy.data, 'new');
      expect(copy.size, original.size);
      expect(copy.correction, original.correction);
      expect(copy.align, original.align);
    });

    test('只改 correction', () {
      final copy = original.copyWith(correction: KoiQrCorrection.low);
      expect(copy.correction, KoiQrCorrection.low);
      expect(copy.data, original.data);
    });
  });

  group('KoiBarcodeElement.copyWith', () {
    const original = KoiBarcodeElement(
      data: '123',
      type: KoiBarcodeType.code128,
      height: 80,
      width: 3,
      align: KoiTextAlign.center,
      textPosition: KoiBarcodeTextPosition.below,
      font: KoiFontType.fontB,
    );

    test('只改 data', () {
      final copy = original.copyWith(data: '456');
      expect(copy.data, '456');
      expect(copy.type, original.type);
      expect(copy.height, original.height);
      expect(copy.width, original.width);
      expect(copy.align, original.align);
      expect(copy.textPosition, original.textPosition);
      expect(copy.font, original.font);
    });

    test('只改 height', () {
      final copy = original.copyWith(height: 120);
      expect(copy.height, 120);
      expect(copy.data, original.data);
    });
  });

  group('KoiTicketForEachElement.copyWith', () {
    const original = KoiTicketForEachElement(
      listKey: 'items',
      templates: [KoiTextElement(text: 'inner')],
    );

    test('只改 listKey', () {
      final copy = original.copyWith(listKey: 'orders');
      expect(copy.listKey, 'orders');
      expect(copy.templates.length, 1);
      expect((copy.templates[0] as KoiTextElement).text, 'inner');
    });

    test('只改 templates', () {
      final copy = original.copyWith(templates: []);
      expect(copy.templates, isEmpty);
      expect(copy.listKey, 'items');
    });
  });

  group('KoiTextRowElement.copyWith', () {
    const original = KoiTextRowElement(
      columns: [KoiTextColumn(text: 'A', ratio: 1)],
    );

    test('只改 columns', () {
      final copy = original.copyWith(
        columns: [const KoiTextColumn(text: 'B', ratio: 2)],
      );
      expect(copy.columns.length, 1);
      expect(copy.columns[0].text, 'B');
      expect(copy.columns[0].ratio, 2);
    });
  });

  group('KoiTextColumn.copyWith', () {
    const original = KoiTextColumn(
      text: 'A',
      ratio: 1,
      align: KoiTextAlign.left,
      bold: true,
    );

    test('只改 text', () {
      final copy = original.copyWith(text: 'B');
      expect(copy.text, 'B');
      expect(copy.ratio, original.ratio);
      expect(copy.align, original.align);
      expect(copy.bold, original.bold);
    });

    test('只改 ratio', () {
      final copy = original.copyWith(ratio: 2);
      expect(copy.ratio, 2);
      expect(copy.text, original.text);
    });
  });

  group('KoiLabelBoxElement.copyWith', () {
    const original = KoiLabelBoxElement(
      x: 10,
      y: 10,
      width: 100,
      height: 100,
      thickness: 2,
    );
    test('copyWith', () {
      final copy = original.copyWith(thickness: 5);
      expect(copy.thickness, 5);
      expect(copy.x, 10);
    });
  });

  group('KoiPositionedTextElement.copyWith', () {
    const original = KoiPositionedTextElement(text: 'A', x: 0, y: 0);
    test('copyWith', () {
      final copy = original.copyWith(text: 'B');
      expect(copy.text, 'B');
      expect(copy.x, 0);
    });
  });

  group('KoiPositionedBarcodeElement.copyWith', () {
    const original = KoiPositionedBarcodeElement(data: '123', x: 0, y: 0);
    test('copyWith', () {
      final copy = original.copyWith(data: '456');
      expect(copy.data, '456');
      expect(copy.x, 0);
    });
  });

  group('KoiPositionedQrCodeElement.copyWith', () {
    const original = KoiPositionedQrCodeElement(data: '123', x: 0, y: 0);
    test('copyWith', () {
      final copy = original.copyWith(data: '456');
      expect(copy.data, '456');
      expect(copy.x, 0);
    });
  });

  group('KoiLabelReverseElement.copyWith', () {
    const original = KoiLabelReverseElement(x: 0, y: 0, width: 10, height: 10);
    test('copyWith', () {
      final copy = original.copyWith(x: 5);
      expect(copy.x, 5);
      expect(copy.width, 10);
    });
  });

  group('KoiLabelImageElement.copyWith', () {
    final original = KoiLabelImageElement(
      imageBytes: Uint8List.fromList([1]),
      x: 0,
      y: 0,
      width: 10,
    );
    test('copyWith', () {
      final copy = original.copyWith(imageBytes: Uint8List.fromList([2]));
      expect(copy.imageBytes, Uint8List.fromList([2]));
      expect(copy.x, 0);
    });
  });

  group('KoiLabelForEachElement.copyWith', () {
    const original = KoiLabelForEachElement(listKey: 'a', templates: []);
    test('copyWith', () {
      final copy = original.copyWith(listKey: 'b');
      expect(copy.listKey, 'b');
    });
  });

  group('KoiLabelBlockTextElement.copyWith', () {
    const original = KoiLabelBlockTextElement(
      text: 'A',
      x: 0,
      y: 0,
      width: 10,
      height: 10,
    );
    test('copyWith', () {
      final copy = original.copyWith(text: 'B');
      expect(copy.text, 'B');
      expect(copy.x, 0);
    });
  });

  group('KoiLabelCircleElement.copyWith', () {
    const original = KoiLabelCircleElement(x: 0, y: 0, diameter: 10);
    test('copyWith', () {
      final copy = original.copyWith(diameter: 20);
      expect(copy.diameter, 20);
      expect(copy.x, 0);
    });
  });

  group('KoiLabelEllipseElement.copyWith', () {
    const original = KoiLabelEllipseElement(x: 0, y: 0, width: 10, height: 10);
    test('copyWith', () {
      final copy = original.copyWith(width: 20);
      expect(copy.width, 20);
      expect(copy.x, 0);
    });
  });

  group('KoiLabelDiagonalElement.copyWith', () {
    const original = KoiLabelDiagonalElement(x: 0, y: 0, xEnd: 10, yEnd: 10);
    test('copyWith', () {
      final copy = original.copyWith(xEnd: 20);
      expect(copy.xEnd, 20);
      expect(copy.x, 0);
    });
  });

  group('KoiLabelBeepElement.copyWith', () {
    const original = KoiLabelBeepElement();
    test('copyWith', () {
      final copy = original.copyWith();
      expect(copy, isA<KoiLabelBeepElement>());
    });
  });

  group('KoiLabelFeedElement.copyWith', () {
    const original = KoiLabelFeedElement();
    test('copyWith', () {
      final copy = original.copyWith();
      expect(copy, isA<KoiLabelFeedElement>());
    });
  });

  group('KoiLabelLineElement.copyWith', () {
    const original = KoiLabelLineElement(x: 0, y: 0, width: 10, height: 10);
    test('copyWith', () {
      final copy = original.copyWith(width: 20);
      expect(copy.width, 20);
      expect(copy.x, 0);
    });
  });

  group('KoiLabelSetupElement.copyWith', () {
    const original = KoiLabelSetupElement(widthMm: 10, heightMm: 10);
    test('copyWith', () {
      final copy = original.copyWith(widthMm: 20);
      expect(copy.widthMm, 20);
      expect(copy.heightMm, 10);
    });
  });

  group('KoiLabelPdf417Element.copyWith', () {
    const original = KoiLabelPdf417Element(data: 'A', x: 0, y: 0);
    test('copyWith', () {
      final copy = original.copyWith(data: 'B');
      expect(copy.data, 'B');
      expect(copy.x, 0);
    });
  });
}
