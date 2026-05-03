import 'dart:typed_data';

import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:test/test.dart';

void main() {
  group('KoiTicketElement JSON 序列化', () {
    test('TextElement round-trip', () {
      const original = KoiTextElement(
        text: '测试文本',
        size: KoiTextSize.size2,
        bold: true,
        align: KoiTextAlign.center,
      );

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiTextElement;

      expect(restored.text, '测试文本');
      expect(restored.size, KoiTextSize.size2);
      expect(restored.bold, true);
      expect(restored.align, KoiTextAlign.center);
      expect(restored.underline, false);
    });

    test('TextElement all properties round-trip', () {
      const original = KoiTextElement(
        text: 'AllProps',
        widthSize: KoiTextSize.size2,
        heightSize: KoiTextSize.size3,
        underlineStyle: KoiUnderlineStyle.thick,
      );

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiTextElement;

      expect(restored.text, 'AllProps');
      expect(restored.widthSize, KoiTextSize.size2);
      expect(restored.heightSize, KoiTextSize.size3);
      expect(restored.underlineStyle, KoiUnderlineStyle.thick);
    });

    test('TextRowElement round-trip', () {
      const original = KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '商品', ratio: 3),
          KoiTextColumn(
            text: '价格',
            align: KoiTextAlign.right,
            bold: true,
          ),
        ],
      );

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiTextRowElement;

      expect(restored.columns.length, 2);
      expect(restored.columns[0].text, '商品');
      expect(restored.columns[0].ratio, 3);
      expect(restored.columns[1].align, KoiTextAlign.right);
      expect(restored.columns[1].bold, true);
    });

    test('QrCodeElement round-trip', () {
      const original = KoiQrCodeElement(
        data: 'https://example.com',
        size: KoiQrSize.size8,
        strategy: KoiQrRenderStrategy.zk,
        correction: KoiQrCorrection.high,
      );

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiQrCodeElement;

      expect(restored.data, 'https://example.com');
      expect(restored.size, KoiQrSize.size8);
      expect(restored.strategy, KoiQrRenderStrategy.zk);
      expect(restored.correction, KoiQrCorrection.high);
    });

    test('QrCodeElement non-default strategy round-trip', () {
      const original = KoiQrCodeElement(
        data: '123',
        strategy: KoiQrRenderStrategy.legend,
      );
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiQrCodeElement;
      expect(restored.strategy, KoiQrRenderStrategy.legend);
    });

    test('BarcodeElement round-trip', () {
      const original = KoiBarcodeElement(
        data: '123456789',
        type: KoiBarcodeType.code39,
        height: 80,
      );

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiBarcodeElement;

      expect(restored.data, '123456789');
      expect(restored.type, KoiBarcodeType.code39);
      expect(restored.height, 80);
    });

    test('BarcodeElement non-default height and text round-trip', () {
      const original = KoiBarcodeElement(
        data: '123',
        height: 50,
        textPosition: KoiBarcodeTextPosition.above,
      );
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiBarcodeElement;
      expect(restored.height, 50);
      expect(restored.textPosition, KoiBarcodeTextPosition.above);
    });

    test('TicketImageElement round-trip with base64', () {
      final bytes = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]);
      final original = KoiTicketImageElement(imageBytes: bytes, width: 200);

      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiTicketImageElement;

      expect(restored.imageBytes, bytes);
      expect(restored.width, 200);
    });

    test('TicketImageElement non-default renderMode round-trip', () {
      final bytes = Uint8List.fromList([0xAA, 0xBB]);
      final original = KoiTicketImageElement(
        imageBytes: bytes,
        renderMode: KoiImageRenderMode.graphics,
      );
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiTicketImageElement;
      expect(restored.renderMode, KoiImageRenderMode.graphics);
    });

    test('DividerElement default omitted', () {
      const original = KoiDividerElement();
      final json = koiTicketElementToJson(original);

      expect(json.containsKey('char'), false); // 默认值不序列化
      final restored = koiTicketElementFromJson(json) as KoiDividerElement;
      expect(restored.char, '-');
    });

    test('TicketForEachElement round-trip (nested)', () {
      const original = KoiTicketForEachElement(
        listKey: 'items',
        templates: [
          KoiTextElement(text: '{{name}}'),
          KoiDividerElement(),
        ],
      );

      final json = koiTicketElementToJson(original);
      final restored =
          koiTicketElementFromJson(json) as KoiTicketForEachElement;

      expect(restored.listKey, 'items');
      expect(restored.templates.length, 2);
      expect(restored.templates[0], isA<KoiTextElement>());
      expect(restored.templates[1], isA<KoiDividerElement>());
    });

    test('CutElement round-trip', () {
      const original = KoiCutElement(mode: KoiCutMode.partial);
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiCutElement;
      expect(restored.mode, KoiCutMode.partial);
    });

    test('unknown ticket type throws FormatException', () {
      expect(
        () => koiTicketElementFromJson({'type': 'unknown'}),
        throwsFormatException,
      );
    });

    test('label element in ticket context throws FormatException', () {
      expect(
        () => koiTicketElementFromJson({'type': 'labelSetup'}),
        throwsFormatException,
      );
    });

    test('DividerElement custom char round-trip', () {
      const original = KoiDividerElement(char: '=');
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiDividerElement;
      expect(restored.char, '=');
    });

    test('SpacerElement round-trip', () {
      const original = KoiSpacerElement(lines: 3);
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiSpacerElement;
      expect(restored.lines, 3);
    });

    test('CutElement default mode round-trip', () {
      const original = KoiCutElement();
      final json = koiTicketElementToJson(original);
      expect(json.containsKey('mode'), false);
      final restored = koiTicketElementFromJson(json) as KoiCutElement;
      expect(restored.mode, KoiCutMode.full);
    });

    test('BeepElement round-trip', () {
      const original = KoiBeepElement(count: 5, durationMs: 200);
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiBeepElement;
      expect(restored.count, 5);
      expect(restored.durationMs, 200);
    });

    test('CashDrawerElement round-trip', () {
      const original = KoiCashDrawerElement(pin: KoiCashDrawerPin.pin5);
      final json = koiTicketElementToJson(original);
      final restored = koiTicketElementFromJson(json) as KoiCashDrawerElement;
      expect(restored.pin, KoiCashDrawerPin.pin5);
    });
  });

  group('KoiLabelElement JSON 序列化', () {
    test('LabelSetupElement round-trip', () {
      const original = KoiLabelSetupElement(
        widthMm: 60,
        heightMm: 40,
        gapMm: 3,
      );

      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelSetupElement;

      expect(restored.widthMm, 60);
      expect(restored.heightMm, 40);
      expect(restored.gapMm, 3);
      expect(restored.dpi, 203);
    });

    test('PositionedTextElement round-trip', () {
      const original = KoiPositionedTextElement(
        x: 100,
        y: 50,
        text: '标签文本',
        rotation: 90,
      );

      final json = koiLabelElementToJson(original);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedTextElement;

      expect(restored.x, 100);
      expect(restored.y, 50);
      expect(restored.text, '标签文本');
      expect(restored.rotation, 90);
    });

    test('ticket element in label context throws FormatException', () {
      expect(
        () => koiLabelElementFromJson({'type': 'text'}),
        throwsFormatException,
      );
    });

    test('unknown label type throws FormatException', () {
      expect(
        () => koiLabelElementFromJson({'type': 'unknown'}),
        throwsFormatException,
      );
    });

    test('PositionedBarcodeElement default values round-trip', () {
      const original = KoiPositionedBarcodeElement(x: 10, y: 20, data: '123');
      final json = koiLabelElementToJson(original);
      expect(json.containsKey('height'), false);
      expect(json.containsKey('barcodeType'), false);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedBarcodeElement;
      expect(restored.height, 60);
      expect(restored.type, '128');
    });

    test('PositionedQrCodeElement default values round-trip', () {
      const original = KoiPositionedQrCodeElement(x: 15, y: 25, data: 'QR');
      final json = koiLabelElementToJson(original);
      expect(json.containsKey('cellSize'), false);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedQrCodeElement;
      expect(restored.cellSize, 6);
    });

    test('PositionedBarcodeElement round-trip', () {
      const original = KoiPositionedBarcodeElement(
        x: 10,
        y: 20,
        data: '12345',
        height: 80,
        type: 'EAN13',
      );
      final json = koiLabelElementToJson(original);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedBarcodeElement;
      expect(restored.x, 10);
      expect(restored.y, 20);
      expect(restored.data, '12345');
      expect(restored.height, 80);
      expect(restored.type, 'EAN13');
    });

    test('PositionedQrCodeElement round-trip', () {
      const original = KoiPositionedQrCodeElement(
        x: 15,
        y: 25,
        data: 'QRData',
        cellSize: 8,
      );
      final json = koiLabelElementToJson(original);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedQrCodeElement;
      expect(restored.x, 15);
      expect(restored.y, 25);
      expect(restored.data, 'QRData');
      expect(restored.cellSize, 8);
    });

    test('PositionedBarcodeElement non-default height round-trip', () {
      const original = KoiPositionedBarcodeElement(
        x: 10,
        y: 20,
        data: '123',
        height: 55,
      );
      final json = koiLabelElementToJson(original);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedBarcodeElement;
      expect(restored.height, 55);
    });

    test('PositionedQrCodeElement non-default cellSize round-trip', () {
      const original = KoiPositionedQrCodeElement(
        x: 15,
        y: 25,
        data: 'QR',
        cellSize: 10,
      );
      final json = koiLabelElementToJson(original);
      final restored =
          koiLabelElementFromJson(json) as KoiPositionedQrCodeElement;
      expect(restored.cellSize, 10);
    });

    test('LabelBoxElement round-trip', () {
      const original = KoiLabelBoxElement(
        x: 0,
        y: 0,
        width: 100,
        height: 50,
        thickness: 5,
      );
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelBoxElement;
      expect(restored.x, 0);
      expect(restored.width, 100);
      expect(restored.thickness, 5);
    });

    test('LabelReverseElement round-trip', () {
      const original = KoiLabelReverseElement(
        x: 5,
        y: 5,
        width: 20,
        height: 20,
      );
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelReverseElement;
      expect(restored.width, 20);
      expect(restored.height, 20);
    });

    test('LabelLineElement round-trip', () {
      const original = KoiLabelLineElement(x: 1, y: 2, width: 200, height: 3);
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelLineElement;
      expect(restored.width, 200);
      expect(restored.height, 3);
    });

    test('LabelImageElement round-trip', () {
      final bytes = Uint8List.fromList([0xAA, 0xBB]);
      final original = KoiLabelImageElement(
        x: 20,
        y: 30,
        imageBytes: bytes,
        width: 50,
      );
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelImageElement;
      expect(restored.imageBytes, bytes);
      expect(restored.width, 50);
    });

    test('LabelPrintElement round-trip', () {
      const original = KoiLabelPrintElement(copies: 2, sets: 3);
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelPrintElement;
      expect(restored.copies, 2);
      expect(restored.sets, 3);
    });

    test('LabelForEachElement round-trip', () {
      const original = KoiLabelForEachElement(
        listKey: 'labels',
        templates: [KoiPositionedTextElement(x: 0, y: 0, text: '{{text}}')],
      );
      final json = koiLabelElementToJson(original);
      final restored = koiLabelElementFromJson(json) as KoiLabelForEachElement;
      expect(restored.listKey, 'labels');
      expect(restored.templates.length, 1);
      expect(restored.templates[0], isA<KoiPositionedTextElement>());
    });
  });

  group('KoiPrintDocument JSON 序列化', () {
    test('ticket document round-trip', () {
      const doc = KoiTicketDocument(
        name: '测试小票',
        elements: [
          KoiTextElement(text: '标题', bold: true),
          KoiDividerElement(),
          KoiQrCodeElement(data: 'https://test.com'),
          KoiCutElement(),
        ],
      );

      final json = doc.toJson();
      final restored = koiPrintDocumentFromJson(json);

      expect(restored, isA<KoiTicketDocument>());
      final ticket = restored as KoiTicketDocument;
      expect(ticket.paperSize, KoiPaperSize.mm80);
      expect(ticket.name, '测试小票');
      expect(ticket.elements.length, 4);
      expect(ticket.elements[0], isA<KoiTextElement>());
      expect(ticket.elements[3], isA<KoiCutElement>());
    });

    test('label document round-trip', () {
      const doc = KoiLabelDocument(
        name: '测试标签',
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiPositionedTextElement(x: 10, y: 10, text: 'ABC'),
          KoiLabelPrintElement(copies: 2),
        ],
      );

      final json = doc.toJson();
      final restored = koiPrintDocumentFromJson(json);

      expect(restored, isA<KoiLabelDocument>());
      final label = restored as KoiLabelDocument;
      expect(label.elements.length, 3);
    });

    test('unknown document type throws FormatException', () {
      expect(
        () => koiPrintDocumentFromJson({'documentType': 'unknown'}),
        throwsFormatException,
      );
    });

    test('parsePaperSize handles int 58', () {
      final json = {'documentType': 'ticket', 'paperSize': 58, 'elements': []};
      final doc = koiPrintDocumentFromJson(json) as KoiTicketDocument;
      expect(doc.paperSize, KoiPaperSize.mm58);
    });

    test('parsePaperSize handles custom int', () {
      final json = {'documentType': 'ticket', 'paperSize': 104, 'elements': []};
      final doc = koiPrintDocumentFromJson(json) as KoiTicketDocument;
      expect(doc.paperSize.widthMm, 104);
    });

    test('parsePaperSize handles string mm80', () {
      final json = {
        'documentType': 'ticket',
        'paperSize': 'mm80',
        'elements': [],
      };
      final doc = koiPrintDocumentFromJson(json) as KoiTicketDocument;
      expect(doc.paperSize, KoiPaperSize.mm80);
    });

    test('parsePaperSize handles string mm58', () {
      final json = {
        'documentType': 'ticket',
        'paperSize': 'mm58',
        'elements': [],
      };
      final doc = koiPrintDocumentFromJson(json) as KoiTicketDocument;
      expect(doc.paperSize, KoiPaperSize.mm58);
    });

    test('JSON string round-trip', () {
      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]);

      final jsonStr = doc.toJsonString();
      final restored = koiPrintDocumentFromJsonString(jsonStr);

      expect(restored, isA<KoiTicketDocument>());
      final ticket = restored as KoiTicketDocument;
      expect(ticket.elements.length, 1);
      final text = ticket.elements[0] as KoiTextElement;
      expect(text.text, 'Hello');
    });

    test('LeftMarginElement round-trip', () {
      const original = KoiLeftMarginElement(dots: 48);
      final json = koiTicketElementToJson(original);
      expect(json['type'], 'leftMargin');
      expect(json['dots'], 48);
      final restored = koiTicketElementFromJson(json) as KoiLeftMarginElement;
      expect(restored.dots, 48);
    });

    test('LeftMarginElement round-trip default dots', () {
      const original = KoiLeftMarginElement();
      final json = koiTicketElementToJson(original);
      expect(json['type'], 'leftMargin');
      expect(json.containsKey('dots'), isFalse);
      final restored = koiTicketElementFromJson(json) as KoiLeftMarginElement;
      expect(restored.dots, 0);
    });

    test('RawBytesElement round-trip', () {
      const original = KoiRawBytesElement([0x1B, 0x40, 0xFF]);
      final json = koiTicketElementToJson(original);
      expect(json['type'], 'rawBytes');
      expect(json['bytes'], [0x1B, 0x40, 0xFF]);
      final restored = koiTicketElementFromJson(json) as KoiRawBytesElement;
      expect(restored.bytes, [0x1B, 0x40, 0xFF]);
    });
  });

  group('KoiLabelElement JSON 序列化 — rawCommand', () {
    test('RawCommandElement round-trip', () {
      const original = KoiRawCommandElement('BLOCK 10,10,200,100');
      final json = koiLabelElementToJson(original);
      expect(json['type'], 'rawCommand');
      expect(json['command'], 'BLOCK 10,10,200,100');
      final restored = koiLabelElementFromJson(json) as KoiRawCommandElement;
      expect(restored.command, 'BLOCK 10,10,200,100');
    });
  });
}
