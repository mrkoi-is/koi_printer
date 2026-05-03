import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 15, height: 2, numChannels: 4);
  image.setPixelRgba(0, 0, 0, 0, 0, 255); // Black
  image.setPixelRgba(1, 0, 255, 255, 255, 255); // White
  
  // Current logic
  final image1 = image.convert(format: img.Format.uint8, numChannels: 4);
  img.grayscale(image1);
  img.invert(image1);
  
  final oneChannelBytes = <int>[];
  final buffer = image1.getBytes(order: img.ChannelOrder.rgba);
  for (var i = 0; i < buffer.length; i += 4) {
    final r = buffer[i];
    final a = buffer[i + 3];
    if (a < 128) {
      oneChannelBytes.add(0);
    } else {
      oneChannelBytes.add(r);
    }
  }
  
  final widthPx = image1.width;
  final heightPx = image1.height;
  if (widthPx % 8 != 0) {
    final targetWidth = (widthPx + 8) - (widthPx % 8);
    final missingPx = targetWidth - widthPx;
    final extra = Uint8List(missingPx);
    for (var i = 0; i < heightPx; i++) {
      final pos = (i * widthPx + widthPx) + i * missingPx;
      oneChannelBytes.insertAll(pos, extra);
    }
  }
  print('Current logic length: ${oneChannelBytes.length}');
  
  // Better logic using getPixel
  final targetWidth = (widthPx + 7) ~/ 8 * 8;
  final newRaster = <int>[];
  for (var y = 0; y < heightPx; y++) {
    for (var x = 0; x < targetWidth; x += 8) {
      int b = 0;
      for (var bit = 0; bit < 8; bit++) {
        final realX = x + bit;
        if (realX < widthPx) {
          final p = image.getPixel(realX, y);
          // Calculate luminance: 0.299 R + 0.587 G + 0.114 B
          final lum = (p.r * 299 + p.g * 587 + p.b * 114) ~/ 1000;
          // Invert and check threshold (white = 255, lum=255. Inverted lum = 0. 0 > 127 is false)
          // Actually, just check if lum < 128 (dark) and alpha > 128 (opaque)
          if (p.a > 128 && lum < 128) {
            b |= (1 << (7 - bit));
          }
        }
      }
      newRaster.add(b);
    }
  }
  print('New logic length: ${newRaster.length}');
}
