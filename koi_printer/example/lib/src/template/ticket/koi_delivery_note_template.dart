import 'package:koi_printer/koi_printer.dart';

/// TMS 原返取货小票模板。
/// 1:1 迁移自旧 XIIBackTicketPapper (98 LOC)。
///
/// 原返取货双联: 客户联 + 存根联, 循环打印。
class KoiDeliveryNoteTemplate
    implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiDeliveryNoteTemplate();

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final docs = <KoiTicketDocument>[];
    final titles = ['原返取货客户联', '原返取货存根联'];

    for (var i = 0; i < config.copies; i++) {
      for (final title in titles) {
        docs.add(_buildCopy(data, config, title, isStub: title == titles.last));
      }
    }
    return docs;
  }

  KoiTicketDocument _buildCopy(
    Map<String, dynamic> d,
    KoiPrintConfig config,
    String title, {
    bool isStub = false,
  }) {
    final companyName = d['companyName']?.toString() ?? '';
    final isSafe = d['isSafe'] as bool? ?? false;
    final ticketSn = d['ticketSn']?.toString() ?? '';
    final barCode = d['barCode']?.toString() ?? '';
    final sequnceId = d['sequnceId']?.toString() ?? '';
    final fromNodeName = d['fromNodeName']?.toString() ?? '';
    final toNodeName = d['toNodeName']?.toString() ?? '';
    final roleName = d['roleName']?.toString() ?? '';
    final operatorId = d['operatorId']?.toString() ?? '';
    final startDate = d['startDate']?.toString() ?? '';
    final senderInfo = d['senderInfo']?.toString() ?? '';
    final recieverName = d['recieverName']?.toString() ?? '';
    final cargoInfo = d['cargoInfo']?.toString() ?? '';
    final cargoCount = d['cargoCount']?.toString() ?? '';
    final remark = d['remark']?.toString() ?? '';
    final backView = d['backView'] as Map<String, dynamic>?;

    final elements = <KoiTicketElement>[
      // 公司名
      KoiTextElement(
        text: companyName,
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),

      // 保收
      if (isSafe)
        const KoiTextElement(
          text: '☆保 收 运 单☆',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
          reverse: true,
        ),

      // 联别标题
      KoiTextElement(
        text: ' $title ',
        align: KoiTextAlign.center,
        size: KoiTextSize.size2,
      ),

      // 存根联才有条码/QR (后缀 'B')
      if (isStub) KoiBarcodeElement(data: '${barCode}B'),
      if (isStub) KoiQrCodeElement(data: ticketSn),

      // 流水号
      KoiTextElement(text: sequnceId, size: KoiTextSize.size2),

      // 路由
      KoiTextElement(
        text: '$fromNodeName->$toNodeName / $roleName',
        size: KoiTextSize.size2,
      ),

      // 操作员 + 运单号
      KoiTextRowElement(
        columns: [
          const KoiTextColumn(text: '操作员', ratio: 1),
          KoiTextColumn(text: operatorId, ratio: 4),
        ],
      ),
      KoiTextRowElement(
        columns: [
          const KoiTextColumn(text: '运单号', ratio: 1),
          KoiTextColumn(text: ticketSn, ratio: 2),
          KoiTextColumn(text: startDate, ratio: 3),
        ],
      ),

      // 发货人 (w1h2 大号)
      KoiTextRowElement(
        columns: [
          const KoiTextColumn(text: '发货人', ratio: 1),
          KoiTextColumn(text: senderInfo, ratio: 5),
        ],
      ),

      // 收货人 (w1h2 大号)
      KoiTextRowElement(
        columns: [
          const KoiTextColumn(text: '收货人', ratio: 1),
          KoiTextColumn(text: recieverName, ratio: 5),
        ],
      ),

      // 货物
      const KoiTextElement(text: '货物'),
      KoiTextElement(text: '$cargoInfo 共$cargoCount件', size: KoiTextSize.size2),

      const KoiDividerElement(),
    ];

    // 返前信息 (条件)
    if (backView != null) {
      elements
        ..add(
          KoiTextElement(
            text: '[返前代收]:${backView['behalfFee'] ?? ''}',
            size: KoiTextSize.size2,
          ),
        )
        ..add(
          KoiTextElement(
            text: '原返时间${backView['createTime'] ?? ''}',
            size: KoiTextSize.size2,
          ),
        )
        ..add(
          KoiTextElement(
            text: '运费:${backView['actualFee'] ?? ''}',
            size: KoiTextSize.size2,
          ),
        );
    }

    // 存根联: 备注 + 签字
    if (isStub) {
      elements
        ..add(KoiTextElement(text: '备注:$remark'))
        ..add(const KoiTextElement(text: '客户签字'))
        ..add(const KoiSpacerElement(lines: 4));
    } else {
      elements.add(const KoiSpacerElement(lines: 2));
    }

    elements
      ..add(
        KoiSpacerElement(lines: config.paperSize == KoiPaperSize.mm58 ? 1 : 2),
      )
      ..add(const KoiCutElement());

    return KoiTicketDocument(
      name: title,
      paperSize: config.paperSize,
      elements: elements,
    );
  }
}
