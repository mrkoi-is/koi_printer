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
      expect(
        (copy.templates[0] as KoiTextElement).text,
        'inner',
      );
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
      final copy = original.copyWith(columns: [const KoiTextColumn(text: 'B', ratio: 2)]);
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
}
