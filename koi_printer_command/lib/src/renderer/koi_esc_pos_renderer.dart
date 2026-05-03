import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:gbk_codec/gbk_codec.dart';
import 'package:image/image.dart' as img;
import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';
import 'package:koi_printer_command/src/renderer/koi_command_renderer.dart';
import 'package:zxing2/qrcode.dart' as zxing;

// ══════════════════════════════════════════════════════════
// ESC/POS 常量 — 直接使用字节, 不依赖字符串编码
// ══════════════════════════════════════════════════════════
const _esc = 0x1B;
const _gs = 0x1D;
const _fs = 0x1C;
// 初始化
const List<int> _cmdInit = [_esc, 0x40]; // ESC @

// 对齐
const List<int> _cmdAlignLeft = [_esc, 0x61, 0x00]; // ESC a 0
const List<int> _cmdAlignCenter = [_esc, 0x61, 0x01]; // ESC a 1
const List<int> _cmdAlignRight = [_esc, 0x61, 0x02]; // ESC a 2

// 字体样式
const List<int> _cmdBoldOn = [_esc, 0x45, 0x01]; // ESC E 1
const List<int> _cmdBoldOff = [_esc, 0x45, 0x00]; // ESC E 0
const List<int> _cmdUnderlineOn = [_esc, 0x2D, 0x01]; // ESC - 1
const List<int> _cmdUnderlineOff = [_esc, 0x2D, 0x00]; // ESC - 0
const List<int> _cmdReverseOn = [_gs, 0x42, 0x01]; // GS B 1
const List<int> _cmdReverseOff = [_gs, 0x42, 0x00]; // GS B 0

// 字体选择
const List<int> _cmdFontA = [_esc, 0x4D, 0x00]; // ESC M 0
const List<int> _cmdFontB = [_esc, 0x4D, 0x01]; // ESC M 1

// 字符大小 GS !
const List<int> _cmdSizePrefix = [_gs, 0x21]; // GS ! n

// 切纸
const List<int> _cmdCutFull = [_gs, 0x56, 0x00]; // GS V 0
const List<int> _cmdCutPartial = [_gs, 0x56, 0x01]; // GS V 1

// 换行
const _newLine = [0x0A]; // \n

// 中文模式
const List<int> _cmdKanjiOn = [_fs, 0x26]; // FS &
const List<int> _cmdKanjiOff = [_fs, 0x2E]; // FS .

// 蜂鸣器
const List<int> _cmdBeep = [_esc, 0x42]; // ESC B count duration

// 钱箱
const List<int> _cmdDrawerPin2 = [_esc, 0x70, 0x00, 0x30, 0x30]; // ESC p 0
const List<int> _cmdDrawerPin5 = [_esc, 0x70, 0x01, 0x30, 0x30]; // ESC p 1

// 进纸
const List<int> _cmdFeedN = [_esc, 0x64]; // ESC d n

// 左边距
const List<int> _cmdLeftMargin = [_gs, 0x4C]; // GS L nL nH

// 代码页
const List<int> _cmdCodePage = [_esc, 0x74]; // ESC t n

// QR 码头部
const List<int> _cmdQrHeader = [_gs, 0x28, 0x6B]; // GS ( k

// 光栅图像
const List<int> _cmdRasterImg = [_gs, 0x76, 0x30]; // GS v 0

/// ESC/POS 指令渲染器。
/// Converts [KoiTicketDocument] (flow layout) into ESC/POS byte sequences.
///
/// 支持功能: 文本/多列/QR(6策略)/条码/图片/分隔线/切纸/蜂鸣/钱箱。
/// 来源: 旧 EscPosGenerator (904 LOC, 8 文件) 的逻辑重组。
class KoiEscPosRenderer implements KoiCommandRenderer {
  /// 创建 ESC/POS 渲染器。
  ///
  /// [defaultStrategy] 默认 QR 渲染策略, 可被元素级别覆盖。
  const KoiEscPosRenderer({this.defaultStrategy = KoiQrRenderStrategy.normal});

  /// 默认 QR 码渲染策略。
  final KoiQrRenderStrategy defaultStrategy;

  @override
  KoiCommandProtocol get protocol => KoiCommandProtocol.escPos;

  @override
  List<List<int>> render(
    KoiPrintDocument document, {
    KoiQrRenderStrategy? qrStrategy,
    int? dotsPerLine,
  }) {
    if (document is! KoiTicketDocument) return [];
    final ticketDoc = document;

    // qrStrategy 来自 KoiPrinterProfile.bestQrStrategy, 优先级最高
    final effectiveQrStrategy = qrStrategy ?? defaultStrategy;
    final chunks = <List<int>>[];
    final bytes = <int>[];

    // 初始化打印机
    bytes.addAll(_cmdInit);

    // 设置代码页 (ESC t n)
    bytes.addAll([..._cmdCodePage, ticketDoc.codePage.value]);

    for (final element in ticketDoc.elements) {
      switch (element) {
        case KoiTextElement():
          bytes.addAll(_renderText(element, ticketDoc.paperSize));
        case KoiTextRowElement():
          bytes.addAll(_renderTextRow(element, ticketDoc.paperSize));
        case KoiQrCodeElement():
          final qrChunks = _renderQrCode(element, effectiveQrStrategy);
          if (qrChunks.length == 1) {
            bytes.addAll(qrChunks.first);
          } else {
            if (bytes.isNotEmpty) {
              chunks.add(List<int>.from(bytes));
              bytes.clear();
            }
            chunks.addAll(qrChunks);
          }
        case KoiBarcodeElement():
          bytes.addAll(_renderBarcode(element));
        case KoiTicketImageElement():
          bytes.addAll(_renderImage(element, ticketDoc.paperSize));
        case KoiDividerElement():
          bytes.addAll(_renderDivider(element, ticketDoc.paperSize));
        case KoiSpacerElement():
          bytes.addAll(_renderSpacer(element));
        case KoiCutElement():
          bytes.addAll(_renderCut(element));
        case KoiBeepElement():
          bytes.addAll(_renderBeep(element));
        case KoiCashDrawerElement():
          bytes.addAll(_renderCashDrawer(element));
        case KoiLeftMarginElement():
          bytes.addAll(_renderLeftMargin(element));
        case KoiRawBytesElement():
          bytes.addAll(element.bytes);
        case KoiTicketForEachElement():
          // ForEach 在模板引擎层展开, renderer 不处理
          break;
      }
    }

    // 将剩余字节加入
    if (bytes.isNotEmpty) {
      chunks.add(bytes);
    }

    return chunks;
  }

  // ══════════════════════════════════════════════════════════
  // 文本渲染
  // ══════════════════════════════════════════════════════════

  List<int> _renderText(KoiTextElement element, KoiPaperSize paperSize) {
    return <int>[
      ..._alignCmd(element.align),
      ..._styleCmd(
        bold: element.bold,
        underline: element.underline,
        underlineStyle: element.underlineStyle,
        reverse: element.reverse,
        size: element.size,
        widthSize: element.widthSize,
        heightSize: element.heightSize,
        font: element.font,
      ),
      ..._encodeText(element.text),
      ..._newLine,
      ..._resetStyle(),
    ];
  }

  // ══════════════════════════════════════════════════════════
  // 多列文本
  // ══════════════════════════════════════════════════════════

  List<int> _renderTextRow(KoiTextRowElement element, KoiPaperSize paperSize) {
    final bytes = <int>[];
    final totalRatio = element.columns.fold<int>(0, (s, c) => s + c.ratio);

    // 计算每列可用字符数
    final charsPerLine = paperSize == KoiPaperSize.mm80 ? 48 : 32;

    final buffer = StringBuffer();
    for (final col in element.columns) {
      final colWidth = (charsPerLine * col.ratio / totalRatio).floor();
      final text = col.text;

      // 计算文本实际宽度 (中文字符占2格)
      var textWidth = 0;
      for (var i = 0; i < text.length; i++) {
        textWidth += text.codeUnitAt(i) > 255 ? 2 : 1;
      }

      if (textWidth >= colWidth) {
        // 截断
        var currentWidth = 0;
        final truncated = StringBuffer();
        for (var i = 0; i < text.length; i++) {
          final charWidth = text.codeUnitAt(i) > 255 ? 2 : 1;
          if (currentWidth + charWidth > colWidth) break;
          truncated.write(text[i]);
          currentWidth += charWidth;
        }
        buffer.write(truncated);
        // 补空格
        final padding = colWidth - currentWidth;
        buffer.write(' ' * padding);
      } else {
        // 对齐填充
        final padding = colWidth - textWidth;
        switch (col.align) {
          case KoiTextAlign.left:
            buffer
              ..write(text)
              ..write(' ' * padding);
          case KoiTextAlign.right:
            buffer
              ..write(' ' * padding)
              ..write(text);
          case KoiTextAlign.center:
            final leftPad = padding ~/ 2;
            final rightPad = padding - leftPad;
            buffer
              ..write(' ' * leftPad)
              ..write(text)
              ..write(' ' * rightPad);
        }
      }
    }

    bytes
      ..addAll(_encodeText(buffer.toString()))
      ..addAll(_newLine);

    return bytes;
  }

  // ══════════════════════════════════════════════════════════
  // QR 码渲染 (6 种策略)
  // ══════════════════════════════════════════════════════════

  List<List<int>> _renderQrCode(
    KoiQrCodeElement element,
    KoiQrRenderStrategy profileStrategy,
  ) {
    // 优先级: 元素级别显式指定 > profile 策略 > 默认
    final strategy =
        element.strategy != KoiQrRenderStrategy.normal
            ? element.strategy
            : profileStrategy;

    return switch (strategy) {
      KoiQrRenderStrategy.normal => [_qrNormal(element)],
      KoiQrRenderStrategy.legend => _qrLegend(element),
      KoiQrRenderStrategy.original => [_qrOriginal(element)],
      KoiQrRenderStrategy.zk => [_qrZk(element)],
      KoiQrRenderStrategy.img => [_qrAsImage(element)],
      KoiQrRenderStrategy.barcode => [_qrAsBarcode(element)],
    };
  }

  /// 标准 QR (GS ( k) — 大多数现代打印机。
  /// 来源: 旧 QRCode 类。
  List<int> _qrNormal(KoiQrCodeElement element) {
    final textBytes = latin1.encode(element.data);
    final dataLen = textBytes.length + 3;

    return <int>[
      ..._alignCmd(element.align),
      ..._cmdQrHeader,
      0x03,
      0x00,
      0x31,
      0x43,
      element.size.value,
      ..._cmdQrHeader,
      0x03,
      0x00,
      0x31,
      0x45,
      element.correction.value,
      ..._cmdQrHeader,
      dataLen & 0xFF,
      (dataLen >> 8) & 0xFF,
      0x31,
      0x50,
      0x30,
      ...textBytes,
      ..._cmdQrHeader,
      0x03,
      0x00,
      0x31,
      0x52,
      0x30,
      ..._cmdQrHeader,
      0x03,
      0x00,
      0x31,
      0x51,
      0x30,
    ]
    // FN 167: 设置 QR 模块大小
    // FN 169: 设置纠错等级
    // FN 180: 存储数据
    // FN 182: 获取大小信息
    // FN 181: 打印 QR 码
    ;
  }

  /// V1 老台式机 — 需分块发送 (partition)。
  /// 来源: 旧 QRCodeV1 类。
  List<List<int>> _qrLegend(KoiQrCodeElement element) {
    final chunks = <List<int>>[];
    final textBytes = latin1.encode(element.data);

    // 初始化
    chunks.add([_esc, 0x40]);

    // 设置 QR 大小
    chunks.add([_gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, element.size.value]);

    // 设置纠错等级
    chunks.add([
      _gs,
      0x28,
      0x6B,
      0x03,
      0x00,
      0x31,
      0x45,
      element.correction.value,
    ]);

    // 存储数据 (头部)
    final dataLen = textBytes.length + 3;
    chunks.add([
      _gs,
      0x28,
      0x6B,
      dataLen & 0xFF,
      (dataLen >> 8) & 0xFF,
      0x31,
      0x50,
      0x30,
    ]);

    // 数据分块 (每 20 字节一块)
    const chunkSize = 20;
    for (var i = 0; i < textBytes.length; i += chunkSize) {
      final end =
          (i + chunkSize > textBytes.length) ? textBytes.length : i + chunkSize;
      chunks.add(textBytes.sublist(i, end).toList());
    }

    // 居中 + 获取大小 + 打印
    chunks.add([_esc, 0x61, 0x01]);
    chunks.add([_gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x52, 0x30]);
    chunks.add([_gs, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

    // 重置
    chunks.add([_gs, 0x40]);

    return chunks;
  }

  /// V2 老便携 (2019前) — 简化指令。
  /// 来源: 旧 QRCodeV2 类。
  List<int> _qrOriginal(KoiQrCodeElement element) {
    final textBytes = latin1.encode(element.data);

    return <int>[
      _esc,
      0x61,
      0x01,
      _gs,
      0x77,
      element.size.value,
      _gs,
      0x6B,
      0x61,
      0x06,
      0x02,
      textBytes.length,
      0x00,
      ...textBytes,
    ]
    // 居中
    // QR 大小
    ;
  }

  /// 芝科 XT-423 — GBK 编码。
  /// 来源: 旧 QRCodeXT423 类。
  List<int> _qrZk(KoiQrCodeElement element) {
    final textBytes = gbk_bytes.encode(element.data);
    final strLen = textBytes.length;

    return <int>[
      _esc,
      0x61,
      0x01,
      _gs,
      0x77,
      element.size.value,
      _gs,
      0x5A,
      0x02,
      _esc,
      0x5A,
      0x00,
      0x01,
      0x00,
      strLen & 0x00FF,
      strLen ~/ 256,
      ...textBytes,
    ]
    // 居中
    // 条码宽度
    ;
  }

  /// 降级为图片 — 使用 zxing2 生成 QR 矩阵, 转 image 库光栅化。
  /// 来源: 旧 addQRAllInOne() → img 分支。
  List<int> _qrAsImage(KoiQrCodeElement element) {
    try {
      // 1. 生成 QR 矩阵
      final ecLevel = switch (element.correction) {
        KoiQrCorrection.low => zxing.ErrorCorrectionLevel.l,
        KoiQrCorrection.medium => zxing.ErrorCorrectionLevel.m,
        KoiQrCorrection.quartile => zxing.ErrorCorrectionLevel.q,
        KoiQrCorrection.high => zxing.ErrorCorrectionLevel.h,
      };
      final qrCode = zxing.Encoder.encode(element.data, ecLevel);
      final matrix = qrCode.matrix!;

      // 2. 矩阵 → image 像素图 (每个 module = cellSize px)
      final cellSize = element.size.value.clamp(2, 12);
      final imgWidth = matrix.width * cellSize;
      final imgHeight = matrix.height * cellSize;

      final image = img.Image(width: imgWidth, height: imgHeight);
      // 白底
      img.fill(image, color: img.ColorRgb8(255, 255, 255));

      // 绘制黑色 modules
      for (var y = 0; y < matrix.height; y++) {
        for (var x = 0; x < matrix.width; x++) {
          if (matrix.get(x, y) == 1) {
            for (var dy = 0; dy < cellSize; dy++) {
              for (var dx = 0; dx < cellSize; dx++) {
                image.setPixelRgb(
                  x * cellSize + dx,
                  y * cellSize + dy,
                  0,
                  0,
                  0,
                );
              }
            }
          }
        }
      }

      // 3. 编码为 PNG 字节, 通过现有 _renderImage 走光栅写入
      final pngBytes = Uint8List.fromList(img.encodePng(image));
      return _renderImage(
        KoiTicketImageElement(
          imageBytes: pngBytes,
          width: imgWidth,
          align: element.align,
        ),
        KoiPaperSize.mm80,
      );
      // zxing / image 库均可能因数据过长等原因异常, 统一降级为文本。
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      // QR 生成失败时记录日志，由于 renderer 内部无注入 logger，使用 dart:developer log 降级。
      log('QR Error: $e\n$st', name: 'KoiEscPosRenderer', error: e);
      // 降级: 如果 QR 生成失败, 输出纯文本占位
      return _renderText(
        KoiTextElement(text: '[QR:${element.data}]', align: element.align),
        KoiPaperSize.mm80,
      );
    }
  }

  /// 降级为条形码。
  List<int> _qrAsBarcode(KoiQrCodeElement element) {
    return _renderBarcode(
      KoiBarcodeElement(data: element.data, align: element.align),
    );
  }

  // ══════════════════════════════════════════════════════════
  // 条码渲染
  // ══════════════════════════════════════════════════════════

  List<int> _renderBarcode(KoiBarcodeElement element) {
    final barcodeData = latin1.encode(element.data);
    final barcodeType = _barcodeTypeValue(element.type);

    return <int>[
      ..._alignCmd(element.align),
      _gs,
      0x48,
      _hriPositionValue(element.textPosition),
      _gs,
      0x66,
      if (element.font == KoiFontType.fontB) 1 else 0,
      _gs,
      0x68,
      element.height & 0xFF,
      _gs,
      0x77,
      element.width & 0xFF,
      _gs,
      0x6B,
      barcodeType,
      barcodeData.length,
      ...barcodeData,
    ]
    // HRI 文字位置
    // HRI 字体选择
    // 条码高度
    // 条码宽度
    ;
  }

  int _hriPositionValue(KoiBarcodeTextPosition pos) {
    return switch (pos) {
      KoiBarcodeTextPosition.none => 0,
      KoiBarcodeTextPosition.above => 1,
      KoiBarcodeTextPosition.below => 2,
      KoiBarcodeTextPosition.both => 3,
    };
  }

  int _barcodeTypeValue(KoiBarcodeType type) {
    return switch (type) {
      KoiBarcodeType.upcA => 65,
      KoiBarcodeType.upcE => 66,
      KoiBarcodeType.jan13 => 67,
      KoiBarcodeType.jan8 => 68,
      KoiBarcodeType.code39 => 69,
      KoiBarcodeType.itf => 70,
      KoiBarcodeType.codabar => 71,
      KoiBarcodeType.code93 => 72,
      KoiBarcodeType.code128 => 73,
    };
  }

  // ══════════════════════════════════════════════════════════
  // 图片渲染 (光栅化)
  // ══════════════════════════════════════════════════════════

  List<int> _renderImage(
    KoiTicketImageElement element,
    KoiPaperSize paperSize,
  ) {
    final bytes = <int>[];

    try {
      var image = img.decodeImage(element.imageBytes);
      if (image == null) return bytes;

      // 缩放到纸张宽度
      final maxWidth = element.width ?? paperSize.widthDots;
      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

      // 光栅化
      final rasterData = _toRasterFormat(image);
      final widthBytes = (image.width + 7) ~/ 8;

      bytes.addAll(_alignCmd(element.align));

      if (element.renderMode == KoiImageRenderMode.graphics) {
        // GS ( L — FN_112 (新标准图形模式)
        final dataLen = widthBytes * image.height + 10;
        bytes
          ..addAll([_gs, 0x28, 0x4C]) // GS ( L
          ..addAll(_intLowHigh(dataLen, 2)) // pL pH
          ..addAll([48, 112, 48]) // m=48, fn=112, a=48
          ..addAll([1, 1]) // bx=1, by=1
          ..addAll([49]) // c=49
          ..addAll(_intLowHigh(widthBytes, 2)) // xL xH
          ..addAll(_intLowHigh(image.height, 2)) // yL yH
          ..addAll(rasterData);

        // GS ( L — FN_50 (Run print)
        bytes
          ..addAll([_gs, 0x28, 0x4C]) // GS ( L
          ..addAll([2, 0]) // pL pH
          ..addAll([48, 50]); // m fn[2,50]
      } else {
        // GS v 0 (旧标准光栅模式)
        bytes
          ..addAll(_cmdRasterImg)
          ..add(0) // m (normal density)
          ..addAll(_intLowHigh(widthBytes, 2)) // xL xH
          ..addAll(_intLowHigh(image.height, 2)) // yL yH
          ..addAll(rasterData);
      }

      // 图片解码/处理可能抛出多种异常类型, 统一忽略以保证打印流程不中断。
      // ignore: avoid_catches_without_on_clauses
    } catch (e, st) {
      // Renderer 内部无 logger 依赖，使用 dart:developer log 记录图片解码错误。
      log('Image Decode Error: $e\n$st', name: 'KoiEscPosRenderer', error: e);
      // 图片解码失败, 跳过
    }

    return bytes;
  }

  /// 图片光栅化 — 来源: 旧 _toRasterFormat。
  List<int> _toRasterFormat(img.Image imgSrc) {
    final image = img.Image.from(imgSrc);
    final widthPx = image.width;
    final heightPx = image.height;

    img.grayscale(image);
    img.invert(image);

    // 提取单通道
    final oneChannelBytes = <int>[];
    final buffer = image.getBytes(order: img.ChannelOrder.rgba);
    for (var i = 0; i < buffer.length; i += 4) {
      oneChannelBytes.add(buffer[i]);
    }

    // 补齐到 8 的倍数
    if (widthPx % 8 != 0) {
      final targetWidth = (widthPx + 8) - (widthPx % 8);
      final missingPx = targetWidth - widthPx;
      final extra = Uint8List(missingPx);
      for (var i = 0; i < heightPx; i++) {
        final pos = (i * widthPx + widthPx) + i * missingPx;
        oneChannelBytes.insertAll(pos, extra);
      }
    }

    return _packBitsIntoBytes(oneChannelBytes);
  }

  /// 将每 8 个像素值打包为 1 个字节。
  List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    const threshold = 127;
    final result = <int>[];

    for (var i = 0; i < bytes.length; i += pxPerLine) {
      var newVal = 0;
      for (var j = 0; j < pxPerLine; j++) {
        if (i + j < bytes.length && bytes[i + j] > threshold) {
          newVal |= 1 << (pxPerLine - 1 - j);
        }
      }
      result.add(newVal);
    }

    return result;
  }

  // ══════════════════════════════════════════════════════════
  // 分隔线 / 空行 / 切纸
  // ══════════════════════════════════════════════════════════

  List<int> _renderDivider(KoiDividerElement element, KoiPaperSize paperSize) {
    final charsPerLine = paperSize == KoiPaperSize.mm80 ? 48 : 32;
    final char = element.char.isEmpty ? '-' : element.char[0];
    final line = char * charsPerLine;
    return [..._encodeText(line), ..._newLine];
  }

  List<int> _renderSpacer(KoiSpacerElement element) {
    // 使用 ESC d (进纸 N 行) 替代多个 LF
    if (element.lines <= 0) return [];
    return [..._cmdFeedN, element.lines & 0xFF];
  }

  List<int> _renderCut(KoiCutElement element) {
    return switch (element.mode) {
      KoiCutMode.full => _cmdCutFull,
      KoiCutMode.partial => _cmdCutPartial,
    };
  }

  // ══════════════════════════════════════════════════════════
  // 工具方法
  // ══════════════════════════════════════════════════════════

  /// 文本编码 (中英文混排自动处理)。
  /// 来源: 旧 _encode + _mixedKanji 逻辑合并。
  List<int> _encodeText(String text) {
    final bytes = <int>[];
    var isInKanjiMode = false;

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      final isChinese = ch.codeUnitAt(0) > 255;

      if (isChinese && !isInKanjiMode) {
        bytes.addAll(_cmdKanjiOn);
        isInKanjiMode = true;
      } else if (!isChinese && isInKanjiMode) {
        bytes.addAll(_cmdKanjiOff);
        isInKanjiMode = false;
      }

      if (isChinese) {
        bytes.addAll(gbk_bytes.encode(ch));
      } else {
        bytes.add(ch.codeUnitAt(0));
      }
    }

    // 退出 Kanji 模式
    if (isInKanjiMode) {
      bytes.addAll(_cmdKanjiOff);
    }

    return bytes;
  }

  /// 对齐指令。
  List<int> _alignCmd(KoiTextAlign align) {
    return switch (align) {
      KoiTextAlign.left => _cmdAlignLeft,
      KoiTextAlign.center => _cmdAlignCenter,
      KoiTextAlign.right => _cmdAlignRight,
    };
  }

  /// 样式指令。
  List<int> _styleCmd({
    required bool bold,
    required bool underline,
    required KoiUnderlineStyle underlineStyle,
    required bool reverse,
    required KoiTextSize size,
    required KoiFontType font,
    KoiTextSize? widthSize,
    KoiTextSize? heightSize,
  }) {
    final bytes = <int>[];

    // 字体选择
    if (font == KoiFontType.fontB) {
      bytes.addAll(_cmdFontB);
    }

    if (bold) bytes.addAll(_cmdBoldOn);

    // 下划线: underlineStyle 优先于 underline bool
    if (underlineStyle != KoiUnderlineStyle.none) {
      bytes.addAll([
        _esc,
        0x2D,
        if (underlineStyle == KoiUnderlineStyle.thick) 2 else 1,
      ]);
    } else if (underline) {
      bytes.addAll(_cmdUnderlineOn);
    }

    if (reverse) bytes.addAll(_cmdReverseOn);

    // 字符大小: GS ! n  (n = (width-1) * 16 + (height-1))
    // 支持独立宽高设置
    final w = widthSize?.value ?? size.value;
    final h = heightSize?.value ?? size.value;
    if (w != 1 || h != 1) {
      final n = (w - 1) * 16 + (h - 1);
      bytes.addAll([..._cmdSizePrefix, n]);
    }

    return bytes;
  }

  /// 重置样式到默认。
  List<int> _resetStyle() {
    return [
      ..._cmdFontA,
      ..._cmdBoldOff,
      ..._cmdUnderlineOff,
      ..._cmdReverseOff,
      ..._cmdSizePrefix, 0x00, // size 1x1
    ];
  }

  /// 数值分高低字节。
  /// 来源: 旧 _intLowHigh。
  List<int> _intLowHigh(int value, int bytesNb) {
    final result = <int>[];
    var buf = value;
    for (var i = 0; i < bytesNb; i++) {
      result.add(buf % 256);
      buf = buf ~/ 256;
    }
    return result;
  }

  // ════════════════════════════════════════════════════════
  // 蜂鸣器 / 钱箱
  // ════════════════════════════════════════════════════════

  /// ESC B 蜂鸣器。
  List<int> _renderBeep(KoiBeepElement element) {
    // ESC B n t  (n=次数, t=持续时间 50ms单位)
    final count = element.count.clamp(1, 9);
    final duration = (element.durationMs / 50).round().clamp(1, 9);
    return [..._cmdBeep, count, duration];
  }

  /// ESC p 钱箱开启。
  List<int> _renderCashDrawer(KoiCashDrawerElement element) {
    return switch (element.pin) {
      KoiCashDrawerPin.pin2 => _cmdDrawerPin2,
      KoiCashDrawerPin.pin5 => _cmdDrawerPin5,
    };
  }

  /// GS L nL nH 左边距。
  List<int> _renderLeftMargin(KoiLeftMarginElement element) {
    return [..._cmdLeftMargin, ..._intLowHigh(element.dots.clamp(0, 65535), 2)];
  }
}
