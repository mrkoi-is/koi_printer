import 'package:gbk_codec/gbk_codec.dart';
import 'package:image/image.dart' as img;
import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';
import 'package:koi_printer_command/src/renderer/koi_command_renderer.dart';

/// CPCL 指令渲染器。
/// Converts [KoiLabelDocument] (positioned layout) into CPCL byte sequences.
class KoiCpclRenderer implements KoiCommandRenderer {
  const KoiCpclRenderer();

  @override
  KoiCommandProtocol get protocol => KoiCommandProtocol.cpcl;

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
          final heightDots = (element.heightMm * element.dpi / 25.4).round();
          commands
            ..add(_cmd('! 0 200 $heightDots 1'))
            ..add(
              _cmd(
                'PAGE-WIDTH ${(element.widthMm * element.dpi / 25.4).round()}',
              ),
            )
            ..add(_cmd('ENCODING GB18030'));
          if (element.speed != null) {
            commands.add(_cmd('SPEED ${element.speed!.round()}'));
          }
        case KoiPositionedTextElement():
          if (element.xScale != 1 || element.yScale != 1) {
            commands.add(_cmd('SETMAG ${element.xScale} ${element.yScale}'));
          }
          if (element.bold) {
            commands.add(_cmd('SETBOLD 1'));
          }
          final textCmd = _rotatedTextCommand(element.rotation);
          commands.add(
            _cmd(
              '$textCmd ${element.font} ${element.fontSize} '
              '${element.x} ${element.y} ${element.text}',
            ),
          );
          if (element.bold) {
            commands.add(_cmd('SETBOLD 0'));
          }
          if (element.xScale != 1 || element.yScale != 1) {
            commands.add(_cmd('SETMAG 1 1'));
          }
        case KoiPositionedBarcodeElement():
          commands.add(
            _cmd(
              'BARCODE ${element.type} 1 1 ${element.height} '
              '${element.x} ${element.y} ${element.data}',
            ),
          );
        case KoiPositionedQrCodeElement():
          commands
            ..add(
              _cmd(
                'BARCODE QR ${element.x} ${element.y} M 2 U ${element.cellSize}',
              ),
            )
            ..add(_cmd('MA,${element.data}'))
            ..add(_cmd('ENDQR'));
        case KoiLabelBoxElement():
          commands.add(
            _cmd(
              'BOX ${element.x} ${element.y} '
              '${element.x + element.width} ${element.y + element.height} '
              '${element.thickness}',
            ),
          );
        case KoiLabelReverseElement():
          commands.add(
            _cmd(
              'INVERSE-LINE ${element.x} ${element.y} '
              '${element.x + element.width} ${element.y + element.height}',
            ),
          );
        case KoiLabelLineElement():
          commands.add(
            _cmd(
              'LINE ${element.x} ${element.y} '
              '${element.x + element.width} ${element.y + element.height} 1',
            ),
          );
        case KoiLabelImageElement():
          commands.addAll(_renderBitmap(element));
        case KoiLabelPrintElement():
          commands
            ..add(_cmd('FORM'))
            ..add(_cmd('PRINT'));
        case KoiRawCommandElement():
          commands.add(_cmd(element.command));
        case KoiLabelForEachElement():
          break;
      }
    }

    return commands;
  }

  String _rotatedTextCommand(int rotation) {
    return switch (rotation) {
      90 => 'TEXT90',
      180 => 'TEXT180',
      270 => 'TEXT270',
      _ => 'TEXT',
    };
  }

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
        'EG $widthBytes $heightPx ${element.x} ${element.y} ',
      );
      return [
        <int>[...header, ...bitmapData, 0x0D, 0x0A],
      ];
      // 位图解码可能抛出多种异常类型 (image, codec 等)，统一忽略以保证打印流程不中断。
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      return [];
    }
  }

  List<int> _cmd(String command) {
    return gbk_bytes.encode('$command\r\n');
  }
}
