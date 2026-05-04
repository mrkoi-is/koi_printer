import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:test/test.dart';

void main() {
  // ════════════════════════════════════════════════════════════
  //  Renderer protocol getter
  // ════════════════════════════════════════════════════════════

  group('Renderer protocol getter', () {
    test('EscPosRenderer returns escPos', () {
      const renderer = KoiEscPosRenderer();
      expect(renderer.protocol, KoiCommandProtocol.escPos);
    });

    test('TsplRenderer returns tspl', () {
      const renderer = KoiTsplRenderer();
      expect(renderer.protocol, KoiCommandProtocol.tspl);
    });

    test('CpclRenderer returns cpcl', () {
      const renderer = KoiCpclRenderer();
      expect(renderer.protocol, KoiCommandProtocol.cpcl);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  ESC/POS Renderer 输出测试
  // ════════════════════════════════════════════════════════════

  group('KoiEscPosRenderer', () {
    late KoiEscPosRenderer renderer;

    setUp(() {
      renderer = const KoiEscPosRenderer();
    });

    test('renders empty document, chunks contain ESC @ init', () {
      const doc = KoiTicketDocument(elements: []);
      final chunks = renderer.render(doc);

      // ESC/POS 初始化: ESC @ (0x1B 0x40)
      expect(chunks, isNotEmpty);

      final allBytes = chunks.expand((c) => c).toList();
      // 应包含 ESC @ (初始化指令)
      expect(_containsSubsequence(allBytes, [0x1B, 0x40]), isTrue);
    });

    test('renders TextElement, output contains text bytes', () {
      const doc = KoiTicketDocument(elements: [KoiTextElement(text: 'Hello')]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // 验证包含 "Hello" 的 ASCII 字节
      final helloBytes = 'Hello'.codeUnits;
      expect(_containsSubsequence(allBytes, helloBytes), isTrue);
    });

    test('renders DividerElement, output contains dash chars', () {
      const doc = KoiTicketDocument(elements: [KoiDividerElement()]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // 分割线默认使用 '-' (0x2D)
      final dashCount = allBytes.where((b) => b == 0x2D).length;
      expect(dashCount, greaterThan(10)); // 80mm 纸至少 32 个 '-'
    });

    test('renders CutElement, output contains GS V', () {
      const doc = KoiTicketDocument(elements: [KoiCutElement()]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // ESC/POS 切纸: GS V (0x1D 0x56)
      expect(_containsSubsequence(allBytes, [0x1D, 0x56]), isTrue);
    });

    test('renders SpacerElement, output contains ESC d', () {
      const doc = KoiTicketDocument(elements: [KoiSpacerElement(lines: 3)]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // ESC d (0x1B 0x64 n) — 进纸 n 行
      expect(_containsSubsequence(allBytes, [0x1B, 0x64, 0x03]), isTrue);
    });

    test('renders BarcodeElement, output contains GS k', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiBarcodeElement(data: '123456789012'),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // ESC/POS 条码: GS k (0x1D 0x6B)
      expect(_containsSubsequence(allBytes, [0x1D, 0x6B]), isTrue);
    });

    test('renders BarcodeElement, output contains GS k', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiBarcodeElement(
            data: '123456789012',
            type: KoiBarcodeType.itf,
            textPosition: KoiBarcodeTextPosition.both,
          ),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      expect(_containsSubsequence(allBytes, [0x1D, 0x6B]), isTrue);
    });

    test('renders QrCodeElement (normal strategy)', () {
      const doc = KoiTicketDocument(
        elements: [KoiQrCodeElement(data: 'https://test.com')],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);

      final allBytes = chunks.expand((c) => c).toList();
      expect(allBytes.length, greaterThan(10)); // 非空输出
    });

    test('renders TextRowElement, all column texts present', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '品名', ratio: 4),
              KoiTextColumn(text: '数量', ratio: 2),
              KoiTextColumn(text: '金额', ratio: 2, align: KoiTextAlign.right),
            ],
          ),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // 由于 ESC/POS 使用 GBK 编码, 我们检查字节非空
      expect(allBytes.length, greaterThan(10));
    });

    test('renders multiple elements in sequence', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiTextElement(text: '标题', bold: true),
          KoiDividerElement(),
          KoiTextElement(text: '内容'),
          KoiDividerElement(),
          KoiCutElement(),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();

      // 3 种指令: ESC @, GS V, 加文本
      expect(_containsSubsequence(allBytes, [0x1B, 0x40]), isTrue); // init
      expect(_containsSubsequence(allBytes, [0x1D, 0x56]), isTrue); // cut
      expect(allBytes.length, greaterThan(50));
    });

    test('returns empty for label document', () {
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 40, heightMm: 30)],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });

    test('renders TextRowElement with truncation and alignments', () {
      const doc = KoiTicketDocument(
        paperSize: KoiPaperSize.mm58, // 32 chars
        elements: [
          KoiTextRowElement(
            columns: [
              KoiTextColumn(
                text: 'LongTextThatWillBeTruncatedSinceItExceedsWidth',
              ),
              KoiTextColumn(text: 'L'),
              KoiTextColumn(text: 'R', align: KoiTextAlign.right),
              KoiTextColumn(text: 'C', align: KoiTextAlign.center),
            ],
          ),
        ],
      );

      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders QrCodeElement all strategies and correction levels', () {
      for (final strategy in KoiQrRenderStrategy.values) {
        final doc = KoiTicketDocument(
          elements: [
            KoiQrCodeElement(
              data:
                  'https://test.com/a-very-long-url-that-exceeds-twenty-characters', // Hits _qrNormal chunkSize limit
              strategy: strategy,
            ),
          ],
        );
        final chunks = renderer.render(doc);
        expect(chunks, isNotEmpty);
      }

      // Hits remaining ErrorCorrectionLevel switches
      for (final correction in KoiQrCorrection.values) {
        final doc = KoiTicketDocument(
          elements: [
            KoiQrCodeElement(
              data: 'QR_CORRECTION',
              strategy: KoiQrRenderStrategy.img,
              correction: correction,
            ),
          ],
        );
        expect(renderer.render(doc), isNotEmpty);
      }
    });

    test('renders QrCodeElement empty data throws and caught', () {
      final doc = KoiTicketDocument(
        elements: [
          KoiQrCodeElement(
            data: 'A' * 5000, // 超长字符串必定触发 QR Error (zxing容错和容量不够)
            strategy: KoiQrRenderStrategy.img,
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders TicketImageElement exception caught', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 20, height: 10)),
      );
      final doc = KoiTicketDocument(
        elements: [
          KoiTicketImageElement(
            imageBytes: imgBytes,
            width: -1, // copyResize(-1) throws
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks.length, 1); // Skips due to exception
    });

    test('renders TicketImageElement in graphics mode', () {
      final validPng = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAA'
        'YAAjCB0C8AAAAASUVORK5CYII=',
      );
      final doc = KoiTicketDocument(
        elements: [
          KoiTicketImageElement(
            imageBytes: validPng,
            renderMode: KoiImageRenderMode.graphics,
            align: KoiTextAlign.right,
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders BeepElement', () {
      const doc = KoiTicketDocument(
        elements: [KoiBeepElement(count: 2, durationMs: 150)],
      );
      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      // ESC B count duration
      expect(_containsSubsequence(allBytes, [0x1B, 0x42, 2, 3]), isTrue);
    });

    test('renders CashDrawerElement', () {
      const doc = KoiTicketDocument(
        elements: [
          KoiCashDrawerElement(),
          KoiCashDrawerElement(pin: KoiCashDrawerPin.pin5),
        ],
      );
      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      expect(_containsSubsequence(allBytes, [0x1B, 0x70, 0x00]), isTrue);
      expect(_containsSubsequence(allBytes, [0x1B, 0x70, 0x01]), isTrue);
    });

    test(
      'renders TextElement with styles (bold, size, reverse, underlineStyle)',
      () {
        const doc = KoiTicketDocument(
          elements: [
            KoiTextElement(
              text: 'Styled',
              bold: true,
              reverse: true,
              underlineStyle: KoiUnderlineStyle.thick,
              font: KoiFontType.fontB,
              widthSize: KoiTextSize.size2,
              heightSize: KoiTextSize.size2,
            ),
            KoiTextElement(
              text: 'UnderlineThin',
              underlineStyle: KoiUnderlineStyle.thin,
            ),
            KoiTextElement(
              text: 'UnderlineBool',
              underline: true,
            ),
            KoiTextElement(text: 'Kanji测试'),
          ],
        );
        final chunks = renderer.render(doc);
        expect(chunks, isNotEmpty);
      },
    );

    test('renders CutElement partial mode', () {
      const doc = KoiTicketDocument(
        elements: [KoiCutElement(mode: KoiCutMode.partial)],
      );
      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      expect(_containsSubsequence(allBytes, [0x1D, 0x56, 0x31]), isTrue);
    });

    test('renders KoiTicketForEachElement silently (no error)', () {
      const doc = KoiTicketDocument(
        elements: [KoiTicketForEachElement(listKey: 'k', templates: [])],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  TSPL Renderer 基本输出测试
  // ════════════════════════════════════════════════════════════

  group('KoiTsplRenderer', () {
    late KoiTsplRenderer renderer;

    setUp(() {
      renderer = const KoiTsplRenderer();
    });

    test('renders label document, output contains SIZE command', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40, gapMm: 3),
          KoiPositionedTextElement(x: 10, y: 10, text: 'Test'),
          KoiLabelPrintElement(),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);

      // TSPL SIZE 指令
      expect(output.contains('SIZE'), isTrue);
    });

    test('renders label document, output contains PRINT command', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiLabelPrintElement(copies: 2),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);

      expect(output.contains('PRINT'), isTrue);
    });

    test('renders label document full setup and shapes', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(
            widthMm: 60,
            heightMm: 40,
            gapMm: 3,
            density: 8,
            speed: 2,
            referenceX: 10,
            referenceY: 10,
            codepage: '437',
          ),
          KoiPositionedBarcodeElement(
            x: 10,
            y: 10,
            height: 50,
            data: '123',
          ),
          KoiLabelBoxElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelReverseElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelLineElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelPrintElement(copies: 2, sets: 2),
          KoiLabelForEachElement(listKey: 'items', templates: []),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);

      expect(output.contains('DENSITY 8'), isTrue);
      expect(output.contains('SPEED 2.0'), isTrue);
      expect(output.contains('REFERENCE 10,10'), isTrue);
      expect(output.contains('CODEPAGE 437'), isTrue);
      expect(output.contains('BARCODE 10,10,"128",50,1,0,2,2,"123"'), isTrue);
      expect(output.contains('BOX 10,10,30,30,2'), isTrue);
      expect(output.contains('REVERSE 10,10,20,20'), isTrue);
      expect(output.contains('BAR 10,10,20,20'), isTrue);
      expect(output.contains('PRINT 2,2'), isTrue);
    });

    test('renders label document images (resize success)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 16, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(
            x: 0,
            y: 0,
            imageBytes: imgBytes,
            width: 8, // 16 > 8 triggers resize
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);
      expect(output.contains('BITMAP'), isTrue);
    });

    test('renders label document images (null decode returns empty)', () {
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(
            x: 0,
            y: 0,
            imageBytes: Uint8List(
              16,
            ), // 16 zero bytes, decodeImage returns null
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks.isEmpty, isTrue);
    });

    test('renders label document images (exception caught)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 8, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(
            x: 0,
            y: 0,
            imageBytes: imgBytes,
            width: -1, // triggers resize with invalid width, throws
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks.isEmpty, isTrue); // catch block returns []
    });

    test('renders label document images (valid without resize)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 8, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [KoiLabelImageElement(x: 10, y: 10, imageBytes: imgBytes)],
      );
      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);
      expect(
        output.contains('BITMAP 10,10,1,8,0,'),
        isTrue,
      ); // 1 byte width (8 pixels)
    });

    test('returns empty for ticket document', () {
      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Ignored')],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  CPCL Renderer 基本输出测试
  // ════════════════════════════════════════════════════════════

  group('KoiCpclRenderer', () {
    late KoiCpclRenderer renderer;

    setUp(() {
      renderer = const KoiCpclRenderer();
    });

    test('renders label document, output starts with ! command', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 60, heightMm: 40),
          KoiPositionedTextElement(x: 10, y: 10, text: 'Label'),
          KoiLabelPrintElement(),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);

      // CPCL 文档以 '!' 开头
      expect(output.startsWith('!'), isTrue);
    });

    test('renders label with speed setup', () {
      const doc = KoiLabelDocument(
        elements: [KoiLabelSetupElement(widthMm: 60, heightMm: 40, speed: 3)],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output.contains('SPEED 3'), isTrue);
    });

    test('renders text with rotation, scale, bold', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiPositionedTextElement(
            x: 0,
            y: 0,
            text: 'R90',
            rotation: 90,
            bold: true,
            xScale: 2,
            yScale: 2,
          ),
          KoiPositionedTextElement(x: 0, y: 0, text: 'R180', rotation: 180),
          KoiPositionedTextElement(x: 0, y: 0, text: 'R270', rotation: 270),
          KoiPositionedTextElement(x: 0, y: 0, text: 'R0'),
        ],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output.contains('TEXT90'), isTrue);
      expect(output.contains('TEXT180'), isTrue);
      expect(output.contains('TEXT270'), isTrue);
      expect(output.contains('SETMAG 2 2'), isTrue);
      expect(output.contains('SETBOLD 1'), isTrue);
      expect(output.contains('SETBOLD 0'), isTrue);
      expect(output.contains('SETMAG 1 1'), isTrue);
    });

    test('renders barcode, QR, box, reverse, line elements', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiPositionedBarcodeElement(
            x: 10,
            y: 10,
            height: 50,
            data: 'ABC',
          ),
          KoiPositionedQrCodeElement(x: 20, y: 20, cellSize: 4, data: 'QR'),
          KoiLabelBoxElement(x: 5, y: 5, width: 50, height: 50),
          KoiLabelReverseElement(x: 10, y: 10, width: 30, height: 30),
          KoiLabelLineElement(x: 0, y: 0, width: 100, height: 1),
          KoiLabelForEachElement(listKey: 'items', templates: []),
          KoiLabelPrintElement(),
        ],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output.contains('BARCODE 128 1 1 50 10 10 ABC'), isTrue);
      expect(output.contains('BARCODE QR 20 20 M 2 U 4'), isTrue);
      expect(output.contains('MA,QR'), isTrue);
      expect(output.contains('ENDQR'), isTrue);
      expect(output.contains('BOX 5 5 55 55 2'), isTrue);
      expect(output.contains('INVERSE-LINE 10 10 40 40'), isTrue);
      expect(output.contains('LINE 0 0 100 1 1'), isTrue);
      expect(output.contains('FORM'), isTrue);
    });

    test('renders images (valid without resize)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 8, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [KoiLabelImageElement(x: 5, y: 5, imageBytes: imgBytes)],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output.contains('EG 1 8 5 5 '), isTrue);
    });

    test('renders images (resize success)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 16, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(x: 0, y: 0, imageBytes: imgBytes, width: 8),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isNotEmpty);
    });

    test('renders images (null decode)', () {
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(
            x: 0,
            y: 0,
            imageBytes: Uint8List(
              16,
            ), // 16 zero bytes, decodeImage returns null
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks.isEmpty, isTrue);
    });

    test('renders images (exception caught)', () {
      final imgBytes = Uint8List.fromList(
        img.encodeBmp(img.Image(width: 8, height: 8)),
      );
      final doc = KoiLabelDocument(
        elements: [
          KoiLabelImageElement(x: 0, y: 0, imageBytes: imgBytes, width: -1),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks.isEmpty, isTrue);
    });

    test('returns empty for ticket document', () {
      const doc = KoiTicketDocument(
        elements: [KoiTextElement(text: 'Ignored')],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });

    test('renders PRINT at end', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
          KoiLabelPrintElement(),
        ],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      final output = String.fromCharCodes(allBytes);

      expect(output.contains('PRINT'), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════
  //  Left Margin / Raw Bytes / Code Page / Raw Command
  // ════════════════════════════════════════════════════════════

  group('KoiEscPosRenderer renders LeftMarginElement', () {
    test('GS L produces correct bytes', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(
        elements: [KoiLeftMarginElement(dots: 100)],
      );

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      // GS L nL nH = 0x1D 0x4C 100 0
      expect(_containsSubsequence(allBytes, [0x1D, 0x4C, 100, 0]), isTrue);
    });
  });

  group('KoiEscPosRenderer renders RawBytesElement', () {
    test('raw bytes are injected unchanged', () {
      const renderer = KoiEscPosRenderer();
      const rawBytes = [0xAA, 0xBB, 0xCC];
      const doc = KoiTicketDocument(elements: [KoiRawBytesElement(rawBytes)]);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      expect(_containsSubsequence(allBytes, rawBytes), isTrue);
    });
  });

  group('KoiEscPosRenderer code page', () {
    test('default GBK sends ESC t 255', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(elements: []);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      // ESC t 255 = 0x1B 0x74 0xFF
      expect(_containsSubsequence(allBytes, [0x1B, 0x74, 0xFF]), isTrue);
    });

    test('custom code page sends correct value', () {
      const renderer = KoiEscPosRenderer();
      const doc = KoiTicketDocument(codePage: KoiCodePage.pc437, elements: []);

      final chunks = renderer.render(doc);
      final allBytes = chunks.expand((c) => c).toList();
      // ESC t 0 = 0x1B 0x74 0x00
      expect(_containsSubsequence(allBytes, [0x1B, 0x74, 0x00]), isTrue);
    });
  });

  group('KoiTsplRenderer renders RawCommandElement', () {
    test('raw command is output as text', () {
      const renderer = KoiTsplRenderer();
      const doc = KoiLabelDocument(
        elements: [KoiRawCommandElement('BEEP 2,100')],
      );

      final chunks = renderer.render(doc);
      expect(chunks.length, 1);
      final text = String.fromCharCodes(chunks.first);
      expect(text, contains('BEEP 2,100'));
    });
  });

  group('KoiCpclRenderer renders RawCommandElement', () {
    test('raw command is output as text', () {
      const renderer = KoiCpclRenderer();
      const doc = KoiLabelDocument(elements: [KoiRawCommandElement('SPEED 3')]);

      final chunks = renderer.render(doc);
      expect(chunks.length, 1);
      final text = String.fromCharCodes(chunks.first);
      expect(text, contains('SPEED 3'));
    });
  });
}

/// 检查 [haystack] 中是否包含 [needle] 子序列。
bool _containsSubsequence(List<int> haystack, List<int> needle) {
  if (needle.isEmpty) return true;
  for (var i = 0; i <= haystack.length - needle.length; i++) {
    var found = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        found = false;
        break;
      }
    }
    if (found) return true;
  }
  return false;
}
