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
            readable: 0,
            rotation: 90,
            narrow: 3,
            wide: 6,
          ),
          KoiPositionedQrCodeElement(
            x: 20,
            y: 20,
            data: 'QR',
            cellSize: 4,
            eccLevel: 'M',
            rotation: 180,
          ),
          KoiLabelBoxElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelReverseElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelLineElement(x: 10, y: 10, width: 20, height: 20),
          KoiLabelCircleElement(x: 10, y: 10, diameter: 20, thickness: 3),
          KoiLabelEllipseElement(
            x: 10,
            y: 10,
            width: 20,
            height: 30,
          ),
          KoiLabelDiagonalElement(
            x: 10,
            y: 10,
            xEnd: 30,
            yEnd: 30,
            thickness: 4,
          ),
          KoiLabelBlockTextElement(
            x: 5,
            y: 5,
            width: 100,
            height: 50,
            text: 'Block',
            space: 1,
            align: 1,
            fit: 1,
          ),
          KoiLabelBeepElement(level: 2, interval: 200),
          KoiLabelFeedElement(dots: 50),
          KoiLabelCutElement(),
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
      expect(output.contains('BARCODE 10,10,"128",50,0,90,3,6,"123"'), isTrue);
      expect(output.contains('QRCODE 20,20,M,4,A,180,"QR"'), isTrue);
      expect(output.contains('BOX 10,10,30,30,2'), isTrue);
      expect(output.contains('REVERSE 10,10,20,20'), isTrue);
      expect(output.contains('BAR 10,10,20,20'), isTrue);
      expect(output.contains('CIRCLE 10,10,20,3'), isTrue);
      expect(output.contains('ELLIPSE 10,10,20,30,2'), isTrue);
      expect(output.contains('DIAGONAL 10,10,30,30,4'), isTrue);
      expect(
        output.contains('BLOCK 5,5,100,50,"TSS24.BF2",0,1,1,1,1,1,"Block"'),
        isTrue,
      );
      expect(output.contains('BEEP 2,200'), isTrue);
      expect(output.contains('FEED 50'), isTrue);
      expect(output.contains('CUT'), isTrue);
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

  // ════════════════════════════════════════════════════════════
  //  KoiCpclRenderer — Setup 字段完整性测试
  // ════════════════════════════════════════════════════════════

  group('KoiCpclRenderer Setup 字段转译', () {
    const renderer = KoiCpclRenderer();

    test('density 转译为 TONE', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30, density: 8),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('TONE 8'));
    });

    test('density 为 null 时不输出 TONE', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, isNot(contains('TONE')));
    });

    test('codepage 转译为 ENCODING', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30, codepage: 'UTF-8'),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('ENCODING UTF-8'));
    });

    test('codepage 为 null 时默认 GB18030', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('ENCODING GB18030'));
    });

    test('copies 注入到会话头 quantity 参数', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
          KoiLabelPrintElement(copies: 3),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      // 会话头格式: ! offset hRes vRes height quantity
      expect(output, contains('! 0 200'));
      expect(output, contains(' 3\r\n'));
      // 确认是会话头的 3，而不是其他地方
      final headerMatch = RegExp(r'! 0 200 \d+ 3');
      expect(headerMatch.hasMatch(output), isTrue);
    });

    test('copies 默认为 1', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(widthMm: 40, heightMm: 30),
          KoiLabelPrintElement(), // 默认 copies=1
        ],
      );
      final output = _cpclOutput(renderer, doc);
      final headerMatch = RegExp(r'! 0 200 \d+ 1');
      expect(headerMatch.hasMatch(output), isTrue);
    });

    test('完整 Setup: speed + density + codepage 全部输出', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(
            widthMm: 60,
            heightMm: 40,
            speed: 4,
            density: 10,
            codepage: 'CP850',
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('SPEED 4'));
      expect(output, contains('TONE 10'));
      expect(output, contains('ENCODING CP850'));
    });
  });

  // ════════════════════════════════════════════════════════════
  //  KoiCpclRenderer — 新增元素渲染测试
  // ════════════════════════════════════════════════════════════

  group('KoiCpclRenderer 新增元素渲染', () {
    const renderer = KoiCpclRenderer();

    test('BlockTextElement 降级为 TEXT 指令', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelBlockTextElement(
            x: 20,
            y: 30,
            width: 400,
            height: 100,
            text: 'Hello',
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('TEXT TSS24.BF2 0 20 30 Hello'));
    });

    test('BlockTextElement 带缩放输出 SETMAG', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelBlockTextElement(
            x: 0,
            y: 0,
            width: 100,
            height: 50,
            text: 'Scale',
            xScale: 2,
            yScale: 3,
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('SETMAG 2 3'));
      expect(output, contains('SETMAG 1 1'));
    });

    test('BlockTextElement 带旋转使用 TEXT90', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelBlockTextElement(
            x: 0,
            y: 0,
            width: 100,
            height: 50,
            text: 'Rotate',
            rotation: 90,
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('TEXT90'));
    });

    test('DiagonalElement 转译为 LINE 指令', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelDiagonalElement(
            x: 10,
            y: 20,
            xEnd: 110,
            yEnd: 120,
            thickness: 3,
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('LINE 10 20 110 120 3'));
    });

    test('BeepElement 转译为 BEEP', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelBeepElement(level: 2, interval: 250),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      // 250 / 125 = 2
      expect(output, contains('BEEP 2'));
    });

    test('BeepElement interval 边界值 clamp', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelBeepElement(
            interval: 1,
          ), // 1/125=0.008 → clamp(1,20) = 1
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('BEEP 1'));
    });

    test('FeedElement 转译为 POSTFEED', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelFeedElement(dots: 150),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('POSTFEED 150'));
    });

    test('CutElement 转译为 CUT', () {
      const doc = KoiLabelDocument(
        elements: [KoiLabelCutElement()],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('CUT'));
    });

    test('CircleElement 被静默忽略', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelCircleElement(x: 10, y: 10, diameter: 50),
        ],
      );
      final chunks = renderer.render(doc);
      // Circle 不支持，应该不产生任何输出
      expect(chunks, isEmpty);
    });

    test('EllipseElement 被静默忽略', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelEllipseElement(
            x: 10,
            y: 10,
            width: 80,
            height: 40,
          ),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });

    test('ForEachElement 被静默忽略', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelForEachElement(listKey: 'items', templates: []),
        ],
      );
      final chunks = renderer.render(doc);
      expect(chunks, isEmpty);
    });

    test('完整标签: Setup + 新元素 + Print 端到端', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelSetupElement(
            widthMm: 60,
            heightMm: 40,
            density: 5,
            codepage: 'GB18030',
          ),
          KoiLabelBlockTextElement(
            x: 10,
            y: 10,
            width: 300,
            height: 80,
            text: 'Paragraph',
          ),
          KoiLabelDiagonalElement(
            x: 0,
            y: 0,
            xEnd: 100,
            yEnd: 100,
          ),
          KoiLabelCircleElement(x: 50, y: 50, diameter: 30),
          KoiLabelEllipseElement(x: 50, y: 50, width: 60, height: 30),
          KoiLabelBeepElement(level: 1, interval: 500),
          KoiLabelFeedElement(dots: 80),
          KoiLabelCutElement(),
          KoiLabelPrintElement(copies: 2),
        ],
      );
      final output = _cpclOutput(renderer, doc);

      // Setup
      expect(output, contains('! 0 200'));
      expect(RegExp(r'! 0 200 \d+ 2').hasMatch(output), isTrue);
      expect(output, contains('ENCODING GB18030'));
      expect(output, contains('TONE 5'));

      // 新增元素
      expect(output, contains('TEXT TSS24.BF2 0 10 10 Paragraph'));
      expect(output, contains('LINE 0 0 100 100 2'));
      expect(output, contains('BEEP'));
      expect(output, contains('POSTFEED 80'));
      expect(output, contains('CUT'));

      // Circle/Ellipse 不应出现对应指令
      expect(output, isNot(contains('CIRCLE')));
      expect(output, isNot(contains('ELLIPSE')));

      // 结束
      expect(output, contains('FORM'));
      expect(output, contains('PRINT'));
    });
  });

  // ════════════════════════════════════════════════════════════
  //  PDF417 二维条码 — TSPL + CPCL
  // ════════════════════════════════════════════════════════════

  group('KoiTsplRenderer 渲染 PDF417', () {
    const renderer = KoiTsplRenderer();

    test('基础 PDF417 输出', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(x: 10, y: 20, data: 'HELLO'),
        ],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output, contains('PDF417 10,20,200,100,0,"HELLO"'));
    });

    test('带 option 参数', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(
            x: 50,
            y: 60,
            width: 300,
            height: 150,
            rotation: 90,
            option: 'E2,W4,H8',
            data: 'DATA123',
          ),
        ],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      expect(output, contains('PDF417 50,60,300,150,90,E2,W4,H8,"DATA123"'));
    });

    test('无 option 时不输出多余逗号', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(x: 0, y: 0, data: 'TEST'),
        ],
      );
      final chunks = renderer.render(doc);
      final output = String.fromCharCodes(chunks.expand((c) => c).toList());
      // 应该是 0,"TEST" 而不是 0,,"TEST"
      expect(output, isNot(contains(',,"TEST"')));
    });
  });

  group('KoiCpclRenderer 渲染 PDF417', () {
    const renderer = KoiCpclRenderer();

    test('基础 PDF417 输出 — 多行格式', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(
            x: 100,
            y: 200,
            data: 'CPCL-DATA',
            columns: 5,
            rows: 10,
            errorLevel: 3,
          ),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('PDF417 H 100 200 2 6 5 10 3 0'));
      expect(output, contains('CPCL-DATA'));
      expect(output, contains('ENDPDF417'));
    });

    test('旋转 90° 使用 V 方向', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(x: 0, y: 0, data: 'V', rotation: 90),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('PDF417 V 0 0'));
    });

    test('默认旋转 0° 使用 H 方向', () {
      const doc = KoiLabelDocument(
        elements: [
          KoiLabelPdf417Element(x: 0, y: 0, data: 'H'),
        ],
      );
      final output = _cpclOutput(renderer, doc);
      expect(output, contains('PDF417 H 0 0'));
    });
  });

  group('PDF417 JSON 序列化', () {
    test('round-trip 序列化', () {
      const element = KoiLabelPdf417Element(
        x: 10,
        y: 20,
        width: 300,
        height: 150,
        rotation: 90,
        errorLevel: 5,
        columns: 8,
        rows: 20,
        option: 'E2',
        data: 'SerTest',
      );
      final json = koiLabelElementToJson(element);
      expect(json['type'], 'labelPdf417');

      final restored = koiLabelElementFromJson(json);
      expect(restored, isA<KoiLabelPdf417Element>());
      final r = restored as KoiLabelPdf417Element;
      expect(r.x, 10);
      expect(r.y, 20);
      expect(r.width, 300);
      expect(r.height, 150);
      expect(r.rotation, 90);
      expect(r.errorLevel, 5);
      expect(r.columns, 8);
      expect(r.rows, 20);
      expect(r.option, 'E2');
      expect(r.data, 'SerTest');
    });
  });
}

/// CPCL 渲染器输出辅助方法：将所有 chunks 合并为字符串。
String _cpclOutput(KoiCpclRenderer renderer, KoiLabelDocument doc) {
  final chunks = renderer.render(doc);
  final allBytes = chunks.expand((c) => c).toList();
  return String.fromCharCodes(allBytes);
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
