import 'dart:developer';

import 'package:gbk_codec/gbk_codec.dart';

import 'package:image/image.dart' as img;
import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';
import 'package:koi_printer_command/src/renderer/koi_command_renderer.dart';

/// TSPL 指令渲染器。
/// Converts [KoiLabelDocument] (positioned layout) into TSPL byte sequences.
class KoiTsplRenderer implements KoiCommandRenderer {
  /// 创建 TSPL 渲染器实例。
  const KoiTsplRenderer();

  @override
  KoiCommandProtocol get protocol => KoiCommandProtocol.tspl;

  @override
  List<List<int>> render(
    KoiPrintDocument document, {
    KoiQrRenderStrategy? qrStrategy,
    int? dotsPerLine,
  }) {
    if (document is! KoiLabelDocument) return [];
    final labelDoc = document;
    final commands = <List<int>>[];

    for (final element in labelDoc.elements) {
      switch (element) {
        case KoiLabelSetupElement():
          commands
            ..add(_cmd('SIZE ${element.widthMm} mm, ${element.heightMm} mm'))
            ..add(
              _cmd(
                switch (element.paperType) {
                  KoiLabelPaperType.gap => 'GAP ${element.gapMm} mm,0 mm',
                  KoiLabelPaperType.blackMark =>
                    'BLINE ${element.blackMarkMm} mm,0 mm',
                  KoiLabelPaperType.continuous => 'GAP 0 mm,0 mm',
                },
              ),
            )
            ..add(_cmd('DIRECTION ${element.direction.value}'));
          if (element.density != null) {
            commands.add(_cmd('DENSITY ${element.density!.clamp(0, 15)}'));
          }
          if (element.speed != null) {
            commands.add(_cmd('SPEED ${element.speed}'));
          }
          if (element.referenceX != 0 || element.referenceY != 0) {
            commands.add(
              _cmd('REFERENCE ${element.referenceX},${element.referenceY}'),
            );
          }
          if (element.codepage != null) {
            commands.add(_cmd('CODEPAGE ${element.codepage}'));
          }
          commands.add(_cmd('CLS'));

        case KoiPositionedTextElement():
          final parts = [
            'TEXT ${element.x}',
            '${element.y}',
            '"${element.font}"',
            '${element.rotation}',
            '${element.xScale}',
            '${element.yScale}',
            '"${element.text}"',
          ];
          commands.add(_cmd(parts.join(',')));
        case KoiPositionedBarcodeElement():
          final parts = [
            'BARCODE ${element.x}',
            '${element.y}',
            '"${element.type}"',
            '${element.height}',
            '${element.readable}',
            '${element.rotation}',
            '${element.narrow}',
            '${element.wide}',
            '"${element.data}"',
          ];
          commands.add(_cmd(parts.join(',')));
        case KoiPositionedQrCodeElement():
          final parts = [
            'QRCODE ${element.x}',
            '${element.y}',
            element.eccLevel,
            '${element.cellSize}',
            'A',
            '${element.rotation}',
            '"${element.data}"',
          ];
          commands.add(_cmd(parts.join(',')));
        case KoiLabelBoxElement():
          final xEnd = element.x + element.width;
          final yEnd = element.y + element.height;
          commands.add(
            _cmd(
              'BOX ${element.x},${element.y},$xEnd,$yEnd,${element.thickness}',
            ),
          );
        case KoiLabelReverseElement():
          commands.add(
            _cmd(
              'REVERSE ${element.x},${element.y},'
              '${element.width},${element.height}',
            ),
          );
        case KoiLabelLineElement():
          commands.add(
            _cmd(
              'BAR ${element.x},${element.y},'
              '${element.width},${element.height}',
            ),
          );
        case KoiLabelImageElement():
          commands.addAll(_renderBitmap(element));
        case KoiLabelPrintElement():
          if (element.sets > 1) {
            commands.add(_cmd('PRINT ${element.copies},${element.sets}'));
          } else {
            commands.add(_cmd('PRINT ${element.copies}'));
          }
        case KoiLabelCircleElement():
          commands.add(
            _cmd(
              'CIRCLE ${element.x},${element.y},'
              '${element.diameter},${element.thickness}',
            ),
          );
        case KoiLabelEllipseElement():
          commands.add(
            _cmd(
              'ELLIPSE ${element.x},${element.y},'
              '${element.width},${element.height},'
              '${element.thickness}',
            ),
          );
        case KoiLabelDiagonalElement():
          commands.add(
            _cmd(
              'DIAGONAL ${element.x},${element.y},'
              '${element.xEnd},${element.yEnd},'
              '${element.thickness}',
            ),
          );
        case KoiLabelBlockTextElement():
          final parts = [
            'BLOCK ${element.x}',
            '${element.y}',
            '${element.width}',
            '${element.height}',
            '"${element.font}"',
            '${element.rotation}',
            '${element.xScale}',
            '${element.yScale}',
            '${element.space}',
            '${element.align}',
            '${element.fit}',
            '"${element.text}"',
          ];
          commands.add(_cmd(parts.join(',')));
        case KoiLabelBeepElement():
          commands.add(_cmd('BEEP ${element.level},${element.interval}'));
        case KoiLabelCutElement():
          commands.add(_cmd('CUT'));
        case KoiLabelFeedElement():
          commands.add(_cmd('FEED ${element.dots}'));
        case KoiLabelPdf417Element():
          final optPart = element.option.isNotEmpty ? '${element.option},' : '';
          commands.add(
            _cmd(
              'PDF417 ${element.x},${element.y},'
              '${element.width},${element.height},'
              '${element.rotation},'
              '$optPart'
              '"${element.data}"',
            ),
          );
        case KoiRawCommandElement():
          commands.add(_cmd(element.command));
        case KoiLabelForEachElement():
          // ForEach 在模板引擎层展开
          break;
      }
    }

    return commands;
  }

  /// TSPL BITMAP 指令。
  List<List<int>> _renderBitmap(KoiLabelImageElement element) {
    try {
      var image = img.decodeImage(element.imageBytes);
      if (image == null) return [];

      if (element.width != null && image.width > element.width!) {
        image = img.copyResize(image, width: element.width);
      }

      img.grayscale(image);

      // 根据 ditherMode 选择二值化算法
      final binaryPixels =
          element.ditherMode == KoiImageDitherMode.floydSteinberg
              ? _floydSteinbergDither(image)
              : _thresholdDither(image);

      final widthBytes = (image.width + 7) ~/ 8;
      final heightPx = image.height;

      final bitmapData = <int>[];
      for (var y = 0; y < heightPx; y++) {
        for (var bx = 0; bx < widthBytes; bx++) {
          var byte = 0;
          for (var bit = 0; bit < 8; bit++) {
            final px = bx * 8 + bit;
            if (px < image.width && binaryPixels[y * image.width + px]) {
              byte |= 0x80 >> bit;
            }
          }
          bitmapData.add(byte);
        }
      }

      final header = gbk_bytes.encode(
        'BITMAP ${element.x},${element.y},$widthBytes,$heightPx,0,',
      );
      return [
        <int>[...header, ...bitmapData, 0x0D, 0x0A],
      ];
      // 位图解码可能抛出多种异常类型 (image, codec 等)，记录日志以保证打印流程不中断。
    } on Object catch (e, st) {
      log('Image Decode Error: $e\n$st', name: 'KoiTsplRenderer', error: e);
      return [];
    }
  }

  /// 简单阈值二值化 — 适合文字、条码、Logo。
  List<bool> _thresholdDither(img.Image image) {
    final result = List<bool>.filled(image.width * image.height, false);
    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        result[y * image.width + x] = pixel.luminance < 128;
      }
    }
    return result;
  }

  /// Floyd-Steinberg 误差扩散二值化 — 适合照片、渐变图像。
  /// 行业标准算法: 将量化误差按 7/16, 3/16, 5/16, 1/16 分配到相邻像素。
  List<bool> _floydSteinbergDither(img.Image image) {
    final w = image.width;
    final h = image.height;
    // 使用 double 精度缓冲区存储误差传播后的灰度值
    final buffer = List<double>.generate(
      w * h,
      (i) => image.getPixel(i % w, i ~/ w).luminance.toDouble(),
    );

    final result = List<bool>.filled(w * h, false);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        final oldVal = buffer[idx];
        final newVal = oldVal < 128.0 ? 0.0 : 255.0;
        result[idx] = newVal == 0.0; // 黑点 = true
        final error = oldVal - newVal;

        // 向右传播 7/16
        if (x + 1 < w) {
          buffer[idx + 1] += error * 7.0 / 16.0;
        }
        // 左下 3/16
        if (x - 1 >= 0 && y + 1 < h) {
          buffer[(y + 1) * w + (x - 1)] += error * 3.0 / 16.0;
        }
        // 正下 5/16
        if (y + 1 < h) {
          buffer[(y + 1) * w + x] += error * 5.0 / 16.0;
        }
        // 右下 1/16
        if (x + 1 < w && y + 1 < h) {
          buffer[(y + 1) * w + (x + 1)] += error * 1.0 / 16.0;
        }
      }
    }

    return result;
  }

  List<int> _cmd(String command) {
    return gbk_bytes.encode('$command\r\n');
  }
}
