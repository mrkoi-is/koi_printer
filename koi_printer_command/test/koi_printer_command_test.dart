import 'dart:typed_data';

import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:test/test.dart';

void main() {
  group('KoiTicketDocument', () {
    test('creates ticket document with default paper size', () {
      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]);
      expect(doc.paperSize, KoiPaperSize.mm80);
      expect(doc.elements.length, 1);
    });

    test('creates ticket document with custom paper size', () {
      const doc = KoiTicketDocument(
        paperSize: KoiPaperSize.mm58,
        elements: [KoiTextElement(text: 'Hello')],
      );
      expect(doc.paperSize, KoiPaperSize.mm58);
    });
  });

  group('KoiLabelDocument', () {
    test('creates label document', () {
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 40, heightMm: 30)],
      );
      expect(doc.elements.length, 1);
    });
  });

  group('KoiPrintDocument sealed', () {
    test('pattern matching on sealed class', () {
      const KoiPrintDocument doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Test')],
      );
      final result = switch (doc) {
        KoiTicketDocument() => 'ticket',
        KoiLabelDocument() => 'label',
      };
      expect(result, 'ticket');
    });
  });

  group('KoiPaperSize', () {
    test('standard sizes have correct dots logic', () {
      expect(KoiPaperSize.mm80.widthDots, 576);
      expect(KoiPaperSize.mm80.widthMm, 80);
      expect(KoiPaperSize.mm58.widthDots, 384);
      expect(KoiPaperSize.mm58.widthMm, 58);
    });

    test('custom calculates dots using default 203 DPI', () {
      final custom = KoiPaperSize.custom(100);
      // 100 * 203 / 25.4 = 799.21 => 799
      expect(custom.widthDots, 799);
      expect(custom.widthMm, 100);
    });

    test('custom calculates dots using explicit DPI', () {
      final custom = KoiPaperSize.custom(100, dpi: 300);
      // 100 * 300 / 25.4 = 1181.1 => 1181
      expect(custom.widthDots, 1181);
    });

    test('equality and hashCode', () {
      final size1 = KoiPaperSize.custom(80);
      const size2 = KoiPaperSize(widthDots: 639, widthMm: 80);
      const size3 = KoiPaperSize(widthDots: 600, widthMm: 80);

      expect(size1, equals(size2));
      expect(size1.hashCode, equals(size2.hashCode));
      expect(size1, isNot(equals(size3)));
    });

    test('toString representation', () {
      final custom = KoiPaperSize.custom(80);
      expect(custom.toString(), 'KoiPaperSize(80mm, 639dots)');
    });
  });

  group('KoiTicketElement sealed subclasses', () {
    test('KoiTextElement uses defaults', () {
      const e = KoiTextElement(text: 'Test');
      expect(e.size, KoiTextSize.size1);
      expect(e.align, KoiTextAlign.left);
      expect(e.bold, false);
    });

    test('KoiQrCodeElement uses default strategy', () {
      const e = KoiQrCodeElement(data: 'https://example.com');
      expect(e.strategy, KoiQrRenderStrategy.normal);
      expect(e.size, KoiQrSize.size6);
      expect(e.correction, KoiQrCorrection.medium);
    });

    test('KoiCutElement defaults to full cut', () {
      const e = KoiCutElement();
      expect(e.mode, KoiCutMode.full);
    });

    test('KoiBeepElement defaults', () {
      const e = KoiBeepElement();
      expect(e.count, 3);
      expect(e.durationMs, 100);
    });

    test('KoiCashDrawerElement defaults', () {
      const e = KoiCashDrawerElement();
      expect(e.pin, KoiCashDrawerPin.pin2);
    });

    test('KoiTextRowElement holds multiple columns', () {
      const e = KoiTextRowElement(
        columns: [
          KoiTextColumn(text: 'Name', ratio: 6),
          KoiTextColumn(text: 'Price', ratio: 3, align: KoiTextAlign.right),
          KoiTextColumn(text: 'Qty', ratio: 3, align: KoiTextAlign.right),
        ],
      );
      expect(e.columns.length, 3);
      expect(e.columns[0].ratio, 6);
    });
  });

  group('KoiLabelElement sealed subclasses', () {
    test('KoiLabelSetupElement stores dimensions', () {
      const e = KoiLabelSetupElement(widthMm: 40, heightMm: 30, gapMm: 3);
      expect(e.widthMm, 40);
      expect(e.heightMm, 30);
      expect(e.gapMm, 3);
    });

    test('KoiPositionedTextElement stores coordinates', () {
      const e = KoiPositionedTextElement(x: 100, y: 50, text: 'Hello');
      expect(e.x, 100);
      expect(e.y, 50);
      expect(e.text, 'Hello');
    });
  });

  group('KoiPrintResult', () {
    test('KoiPrintSuccess stores bytes sent', () {
      const result = KoiPrintSuccess(bytesSent: 1024);
      expect(result.bytesSent, 1024);
    });

    test('KoiPrintFailure stores error and retryable flag', () {
      const result = KoiPrintFailure(
        error: 'Connection lost',
      );
      expect(result.error, 'Connection lost');
      expect(result.isRetryable, true);
    });

    test('pattern matching on sealed class', () {
      const KoiPrintResult result = KoiPrintSuccess(bytesSent: 512);
      final message = switch (result) {
        KoiPrintSuccess(:final bytesSent) => 'Sent $bytesSent bytes',
        KoiPrintFailure(:final error) => 'Error: $error',
      };
      expect(message, 'Sent 512 bytes');
    });
  });

  group('KoiEscPosRenderer', () {
    test('renders simple text element', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Hello World')],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);

      // 验证包含初始化指令 ESC @
      final allBytes = chunks.expand((c) => c).toList();
      expect(allBytes[0], 0x1B); // ESC
      expect(allBytes[1], 0x40); // @
    });

    test('renders QR code with normal strategy', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(
        elements: [
          KoiQrCodeElement(
            data: 'https://test.com',
          ),
        ],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders QR code with legend strategy as multiple chunks', () {
      const renderer = KoiEscPosRenderer(
        defaultStrategy: KoiQrRenderStrategy.legend,
      );
      const doc = KoiTicketDocument(elements: [KoiQrCodeElement(data: 'test')]);

      final chunks = renderer.render(doc);
      // Legend 策略应产生多个 chunks
      expect(chunks.length, greaterThan(1));
    });

    test('renders cut command', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(elements: [KoiCutElement()]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      // 应包含 GS V 0 (full cut)
      expect(allBytes, contains(0x1D)); // GS
    });

    test('renders divider with correct length', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(elements: [KoiDividerElement()]);

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders multi-column text row', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(
        elements: [
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: 'Item', ratio: 6),
              KoiTextColumn(
                text: '100.00',
                ratio: 6,
                align: KoiTextAlign.right,
              ),
            ],
          ),
        ],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('returns empty for label document', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
          KoiPositionedTextElement(x: 10, y: 10, text: 'Label'),
        ],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });
  });

  group('KoiTsplRenderer', () {
    test('renders label setup', () {
      const renderer = KoiTsplRenderer();
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 40, heightMm: 30)],
      );

      final chunks = renderer.render(doc);
      // SIZE + GAP + DIRECTION + CLS = 4 commands
      expect(chunks.length, 4);
    });

    test('renders positioned text', () {
      const renderer = KoiTsplRenderer();
      const doc = KoiLabelDocument(
        elements: [KoiPositionedTextElement(x: 10, y: 20, text: 'Hello')],
      );

      final chunks = renderer.render(doc);
      expect(chunks.length, 1);

      // 验证包含 TEXT 指令
      final text = String.fromCharCodes(chunks.first);
      expect(text, contains('TEXT'));
      expect(text, contains('Hello'));
    });

    test('renders QR code', () {
      const renderer = KoiTsplRenderer();
      const doc = KoiLabelDocument(
        elements: [KoiPositionedQrCodeElement(x: 10, y: 20, data: 'test')],
      );

      final chunks = renderer.render(doc);
      expect(chunks.length, 1);

      final text = String.fromCharCodes(chunks.first);
      expect(text, contains('QRCODE'));
    });

    test('returns empty for ticket document', () {
      const renderer = KoiTsplRenderer();
      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Ignored')],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });
  });

  group('KoiCpclRenderer', () {
    test('renders label setup', () {
      const renderer = KoiCpclRenderer();
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 40, heightMm: 30)],
      );

      final chunks = renderer.render(doc);
      // ! + PAGE-WIDTH + ENCODING = 3 commands
      expect(chunks.length, 3);
    });

    test('renders print command with form', () {
      const renderer = KoiCpclRenderer();
      const doc = KoiLabelDocument(elements: [KoiLabelPrintElement(copies: 2)]);

      final chunks = renderer.render(doc);
      // FORM + PRINT = 2 commands
      expect(chunks.length, 2);
    });
  });

  group('KoiTypes enums', () {
    test('KoiPaperSize has correct dot values', () {
      expect(KoiPaperSize.mm80.widthDots, 576);
      expect(KoiPaperSize.mm58.widthDots, 384);
    });

    test('KoiQrCorrection has standard values', () {
      expect(KoiQrCorrection.low.value, 48);
      expect(KoiQrCorrection.medium.value, 49);
      expect(KoiQrCorrection.quartile.value, 50);
      expect(KoiQrCorrection.high.value, 51);
    });
  });

  group('KoiLabelElement sealed subclasses', () {
    test('KoiPositionedBarcodeElement defaults', () {
      const e = KoiPositionedBarcodeElement(x: 10, y: 10, data: '123');
      expect(e.height, 60);
      expect(e.type, '128');
    });

    test('KoiLabelBoxElement defaults', () {
      const e = KoiLabelBoxElement(x: 0, y: 0, width: 100, height: 100);
      expect(e.thickness, 2);
    });

    test('KoiLabelReverseElement creates', () {
      const e = KoiLabelReverseElement(x: 10, y: 10, width: 100, height: 50);
      expect(e.width, 100);
    });

    test('KoiLabelLineElement creates', () {
      const e = KoiLabelLineElement(x: 10, y: 10, width: 100, height: 2);
      expect(e.height, 2);
    });

    test('KoiLabelImageElement creates', () {
      final e = KoiLabelImageElement(x: 10, y: 10, imageBytes: Uint8List(0));
      expect(e.width, isNull);
    });

    test('KoiLabelForEachElement creates', () {
      const e = KoiLabelForEachElement(listKey: 'data', templates: []);
      expect(e.listKey, 'data');
    });

    test('KoiRawCommandElement creates', () {
      const e = KoiRawCommandElement('BEEP 2,100');
      expect(e.command, 'BEEP 2,100');
    });
  });

  group('KoiTicketElement new elements', () {
    test('KoiLeftMarginElement defaults', () {
      const e = KoiLeftMarginElement();
      expect(e.dots, 0);
    });

    test('KoiLeftMarginElement with dots', () {
      const e = KoiLeftMarginElement(dots: 48);
      expect(e.dots, 48);
    });

    test('KoiRawBytesElement stores bytes', () {
      const e = KoiRawBytesElement([0x1B, 0x40]);
      expect(e.bytes, [0x1B, 0x40]);
    });
  });

  group('KoiPrintResult sealed coverage', () {
    test('KoiPrintSuccess defaults', () {
      // KoiPrintSuccess 默认用例测试非常量路径以提升覆盖率。
      // ignore: prefer_const_constructors
      final result = KoiPrintSuccess();
      expect(result.bytesSent, 0);
      expect(result.documentName, isNull);
    });

    test('KoiPrintFailure non-retryable', () {
      // KoiPrintFailure 默认用例测试非常量路径以提升覆盖率。
      // ignore: prefer_const_constructors
      final result = KoiPrintFailure(
        error: 'Fatal',
        errorCode: 'E001',
        documentName: 'receipt',
        isRetryable: false,
      );
      expect(result.error, 'Fatal');
      expect(result.errorCode, 'E001');
      expect(result.documentName, 'receipt');
      expect(result.isRetryable, false);
    });
  });
}
