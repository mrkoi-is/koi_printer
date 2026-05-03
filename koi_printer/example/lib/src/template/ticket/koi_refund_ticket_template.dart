import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 退票模板。
/// 打印退款/退货小票，含退款金额和原单号。
class KoiRefundTicketTemplate extends KoiPrintTemplate {
  const KoiRefundTicketTemplate();

  @override
  String get templateId => 'refund_ticket';

  @override
  String get displayName => '退票';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiTicketDocument(
      elements: [
        // 标题
        const KoiTextElement(
          text: '退  款  凭  证',
          align: KoiTextAlign.center,
          bold: true,
          size: KoiTextSize.size2,
        ),
        const KoiSpacerElement(lines: 1),
        const KoiDividerElement(),

        // 公司信息
        KoiTextElement(
          text: '{{company_name}}',
          align: KoiTextAlign.center,
        ),
        KoiTextElement(
          text: '{{company_address}}',
          align: KoiTextAlign.center,
        ),
        const KoiDividerElement(),

        // 退款信息
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '原单号', ratio: 4),
          KoiTextColumn(text: '{{original_sn}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款单号', ratio: 4),
          KoiTextColumn(text: '{{refund_sn}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款原因', ratio: 4),
          KoiTextColumn(text: '{{reason}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款时间', ratio: 4),
          KoiTextColumn(text: '{{refund_time}}', ratio: 8),
        ]),
        const KoiDividerElement(),

        // 金额
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '原金额', ratio: 6),
          KoiTextColumn(
            text: '¥{{original_amount}}',
            ratio: 6,
            align: KoiTextAlign.right,
          ),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款金额', ratio: 6, bold: true),
          KoiTextColumn(
            text: '¥{{refund_amount}}',
            ratio: 6,
            align: KoiTextAlign.right,
          ),
        ]),
        const KoiDividerElement(),

        // 操作员
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '经手人', ratio: 4),
          KoiTextColumn(text: '{{operator}}', ratio: 8),
        ]),
        const KoiSpacerElement(lines: 1),

        // 声明
        const KoiTextElement(
          text: '此票据作为退款凭证，请妥善保管',
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 2),
        const KoiCutElement(),
      ],
    );
  }
}
