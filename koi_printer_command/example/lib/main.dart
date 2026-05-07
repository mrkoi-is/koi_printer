import 'package:koi_printer_command/koi_printer_command.dart';

void main() async {
  // 1. Create a print document with abstract elements
  final document = KoiPrintDocument.ticket(
    elements: [
      KoiTextElement(
        text: 'Koi Printer Studio',
        bold: true,
        size: KoiTextSize.size2,
        alignment: KoiPrintAlignment.center,
      ),
      KoiTextElement(text: '--------------------------------'),
      KoiBarcodeElement(
        data: '20260507',
        type: KoiBarcodeType.code128,
        alignment: KoiPrintAlignment.center,
      ),
      KoiTextElement(text: '--------------------------------'),
      KoiCutElement(),
    ],
  );

  // 2. Render to ESC/POS bytes
  final escPosRenderer = KoiEscPosRenderer();
  final escPosBytes = await escPosRenderer.render(document);
  print('Generated ${escPosBytes.length} bytes for ESC/POS.');

  // 3. Render to TSPL bytes
  final tsplRenderer = KoiTsplRenderer();
  final tsplBytes = await tsplRenderer.render(document);
  print('Generated ${tsplBytes.length} bytes for TSPL.');
}
