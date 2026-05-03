import 'package:gbk_codec/gbk_codec.dart';
import 'package:image/image.dart' as img;
import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';
import 'package:koi_printer_command/src/renderer/koi_command_renderer.dart';

/// TSPL 指令渲染器。
/// Converts [KoiLabelDocument] (positioned layout) into TSPL byte sequences.
class KoiTsplRenderer implements KoiCommandRenderer {
  /// Documented.
  /// Constant constructor.
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
            ..add(_cmd('GAP ${element.gapMm} mm,0 mm'))
            ..add(_cmd('DIRECTION 1'));
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
          commands.add(
            _cmd(
              'TEXT ${element.x},${element.y},'
              '"${element.font}",${element.rotation},'
              '${element.xScale},${element.yScale},"${element.text}"',
            ),
          );
        case KoiPositionedBarcodeElement():
          commands.add(
            _cmd(
              'BARCODE ${element.x},${element.y},'
              '"${element.type}",${element.height},'
              '1,0,2,2,"${element.data}"',
            ),
          );
        case KoiPositionedQrCodeElement():
          commands.add(
            _cmd(
              'QRCODE ${element.x},${element.y},'
              'L,${element.cellSize},A,0,"${element.data}"',
            ),
          );
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

      final widthBytes = (image.width + 7) ~/ 8;
      final heightPx = image.height;

      final bitmapData = <int>[];
      for (var y = 0; y < heightPx; y++) {
        for (var bx = 0; bx < widthBytes; bx++) {
          var byte = 0;
          for (var bit = 0; bit < 8; bit++) {
            final px = bx * 8 + bit;
            if (px < image.width) {
              final pixel = image.getPixel(px, y);
              if (pixel.luminance < 128) {
                byte |= 0x80 >> bit;
              }
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
      // 位图解码可能抛出多种异常, 统一忽略以保证打印流程不中断。
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return [];
    }
  }

  List<int> _cmd(String command) {
    return gbk_bytes.encode('$command\r\n');
  }
}
