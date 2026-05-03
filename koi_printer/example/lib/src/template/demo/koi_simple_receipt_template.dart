import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 简单收据 Demo 模板。
/// 面向新开发者的最简单上手示例，展示核心元素用法。
class KoiSimpleReceiptTemplate extends KoiPrintTemplate {
  const KoiSimpleReceiptTemplate();

  @override
  String get templateId => 'simple_receipt';

  @override
  String get displayName => '简单收据 (Demo)';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiTicketDocument(
      elements: [
        // 店铺名称 — 居中大字
        const KoiTextElement(
          text: 'Mr.Koi Store',
          align: KoiTextAlign.center,
          bold: true,
          size: KoiTextSize.size2,
        ),
        const KoiTextElement(
          text: 'www.mrkoi.com',
          align: KoiTextAlign.center,
        ),
        const KoiDividerElement(),

        // 商品列表
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '商品', ratio: 6),
          const KoiTextColumn(text: '数量', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right),
        ]),
        const KoiDividerElement(char: '-'),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: 'Koi Premium', ratio: 6),
          const KoiTextColumn(text: '1', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '¥99.00', ratio: 4, align: KoiTextAlign.right),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: 'Koi Basic', ratio: 6),
          const KoiTextColumn(text: '2', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '¥39.00', ratio: 4, align: KoiTextAlign.right),
        ]),
        const KoiDividerElement(),

        // 合计
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '合计', ratio: 8, bold: true),
          const KoiTextColumn(
            text: '¥177.00',
            ratio: 4,
            align: KoiTextAlign.right,
          ),
        ]),
        const KoiSpacerElement(lines: 1),

        // QR 码
        const KoiQrCodeElement(
          data: 'https://github.com/mrkoi-is/koi_printer',
          align: KoiTextAlign.center,
          size: KoiQrSize.size5,
        ),
        const KoiTextElement(
          text: '扫码了解 koi_printer SDK',
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 2),
        const KoiCutElement(),
      ],
    );
  }
}
