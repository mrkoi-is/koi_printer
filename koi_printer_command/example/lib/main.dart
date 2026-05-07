// ignore_for_file: avoid_print

import 'package:koi_printer_command/koi_printer_command.dart';

void main() async {
  // 1. Create a print document with abstract elements
  final document = KoiTicketDocument(
    elements: [
      const KoiTextElement(
        text: 'Koi Printer Studio',
        bold: true,
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),
      const KoiTextElement(text: '--------------------------------'),
      const KoiBarcodeElement(
        data: '20260507',
        type: KoiBarcodeType.code128,
        align: KoiTextAlign.center,
      ),
      const KoiTextElement(text: '--------------------------------'),
      const KoiCutElement(),
    ],
  );

  // 2. Render to ESC/POS bytes
  final escPosRenderer = KoiEscPosRenderer();
  final escPosBytes = escPosRenderer.render(document);
  print('Generated ${escPosBytes.length} chunks for ESC/POS.');

  // 3. Render to TSPL bytes
  final tsplRenderer = KoiTsplRenderer();
  final tsplBytes = tsplRenderer.render(document);
  print('Generated ${tsplBytes.length} chunks for TSPL.');
}
