import 'package:koi_printer/koi_printer.dart';

/// 交款申请模板。
/// 用于 TMS 场景下司机向财务交款的凭证打印。
class KoiPaymentRequestTemplate
    implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiPaymentRequestTemplate();

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    return [
      KoiTicketDocument(
        name: '交款申请',
        paperSize: config.paperSize,
        elements: [
          // 标题
          const KoiTextElement(
            text: '交  款  申  请  单',
            align: KoiTextAlign.center,
            bold: true,
            size: KoiTextSize.size2,
          ),
          const KoiSpacerElement(lines: 1),
          const KoiDividerElement(),

          // 基本信息
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '申请单号', ratio: 4),
              KoiTextColumn(text: '{{request_sn}}', ratio: 8),
            ],
          ),
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '申请日期', ratio: 4),
              KoiTextColumn(text: '{{request_date}}', ratio: 8),
            ],
          ),
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '司机姓名', ratio: 4),
              KoiTextColumn(text: '{{driver_name}}', ratio: 8),
            ],
          ),
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '车牌号码', ratio: 4),
              KoiTextColumn(text: '{{plate_number}}', ratio: 8),
            ],
          ),
          const KoiDividerElement(),

          // 货物明细标题
          const KoiTextElement(text: '运费明细', bold: true),
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '单号', ratio: 5),
              const KoiTextColumn(
                text: '金额',
                ratio: 3,
                align: KoiTextAlign.right,
              ),
              const KoiTextColumn(text: '备注', ratio: 4),
            ],
          ),
          const KoiDividerElement(char: '-'),

          // 动态列表 (由模板引擎展开)
          KoiTicketForEachElement(
            listKey: 'items',
            templates: [
              KoiTextRowElement(
                columns: [
                  const KoiTextColumn(text: '{{item.sn}}', ratio: 5),
                  KoiTextColumn(
                    text: '{{item.amount}}',
                    ratio: 3,
                    align: KoiTextAlign.right,
                  ),
                  const KoiTextColumn(text: '{{item.note}}', ratio: 4),
                ],
              ),
            ],
          ),
          const KoiDividerElement(),

          // 合计
          KoiTextRowElement(
            columns: [
              const KoiTextColumn(text: '合计金额', ratio: 6, bold: true),
              KoiTextColumn(
                text: '¥{{total_amount}}',
                ratio: 6,
                align: KoiTextAlign.right,
              ),
            ],
          ),
          const KoiSpacerElement(lines: 1),

          // 签名区
          const KoiTextElement(text: '财务签字: _______________'),
          const KoiSpacerElement(lines: 1),
          const KoiTextElement(text: '司机签字: _______________'),
          const KoiSpacerElement(lines: 2),
          const KoiCutElement(),
        ],
      ),
    ];
  }
}
