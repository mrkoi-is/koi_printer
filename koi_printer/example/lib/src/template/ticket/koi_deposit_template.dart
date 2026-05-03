import 'package:koi_printer/koi_printer.dart';

/// 寄存单模板。
class KoiDepositTemplate implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiDepositTemplate();

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final docs = <KoiTicketDocument>[];
    final code = data['code']?.toString() ?? 'N/A';
    final location = data['location']?.toString() ?? '前台架子';

    for (var i = 0; i < config.copies; i++) {
      final elements = <KoiTicketElement>[
        if (config.headerEmptyLines > 0)
          KoiSpacerElement(lines: config.headerEmptyLines),

        const KoiTextElement(
          text: '寄存凭条',
          size: KoiTextSize.size3,
          align: KoiTextAlign.center,
          bold: true,
        ),
        const KoiSpacerElement(lines: 1),

        KoiTextElement(
          text: '取件码: $code',
          size: KoiTextSize.size2,
          bold: true,
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 1),
        KoiQrCodeElement(
          data: code,
          size: KoiQrSize.size8,
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 1),

        KoiTextElement(text: '寄存位置: $location'),
        const KoiDividerElement(),

        if (config.cutBehavior != KoiCutBehavior.noCut)
          const KoiCutElement(mode: KoiCutMode.full),
      ];

      docs.add(
        KoiTicketDocument(
          name: '寄存单-$code',
          paperSize: config.paperSize,
          elements: elements,
        ),
      );
    }

    return docs;
  }
}
