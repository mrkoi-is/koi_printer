import 'package:koi_printer/koi_printer.dart';

/// TMS 到件小票模板 — 提货客户联 & 提货存根联。
/// 1:1 迁移自旧 XIIReceiverTicketPapper (174 LOC)。
class KoiReceiverTicketTemplate
    implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiReceiverTicketTemplate();

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final docs = <KoiTicketDocument>[];

    for (var i = 0; i < config.copies; i++) {
      // 提货客户联 — 始终打印
      docs.add(_buildClientCopy(data, config));

      // 提货存根联 — 仅 withStub 时打印
      if (config.stubType == KoiStubType.withStub) {
        docs.add(_buildSubCopy(data, config));
      }
    }
    return docs;
  }

  // ── 条件头 (isSafe / online) ──
  List<KoiTicketElement> _stateHeader(Map<String, dynamic> d) {
    final elements = <KoiTicketElement>[];
    if (d['isSafe'] == true) {
      elements.add(
        const KoiTextElement(
          text: '☆保 收 运 单☆',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
        ),
      );
    }
    if (d['online'] == true) {
      elements.add(
        const KoiTextElement(
          text: '[网单开单]',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
        ),
      );
    }
    return elements;
  }

  // ── 人员→费用段落 (来自旧 _fromStaffToFee) ──
  List<KoiTicketElement> _staffToFee(Map<String, dynamic> d) {
    final operatorInfo = d['operatorInfo']?.toString() ?? '';
    final ticketSn = d['ticketSn']?.toString() ?? '';
    final startDate = d['startDate']?.toString() ?? '';
    final senderInfo = d['senderInfo']?.toString() ?? '';
    final senderPhone = d['senderPhone']?.toString() ?? '';
    final recieverName = d['recieverName']?.toString() ?? '';
    final recieverPhone = d['recieverPhone']?.toString() ?? '';
    final pickMethod = d['pickMethod']?.toString() ?? '';
    final cargoInfo = d['cargoInfo']?.toString() ?? '';
    final cargoCount = d['cargoCount']?.toString() ?? '';

    return [
      KoiTextElement(text: '操作员:$operatorInfo'),
      KoiTextElement(text: '运单号:$ticketSn'),
      KoiTextElement(text: '发货日期:$startDate'),
      KoiTextElement(text: '发货人:$senderInfo $senderPhone'),
      const KoiTextElement(text: '收货人'),
      KoiTextElement(
        text: '$recieverName $recieverPhone',
        size: KoiTextSize.size2,
      ),
      KoiTextElement(text: '提货方式:$pickMethod'),
      KoiTextElement(
        text: '$cargoInfo 合计:$cargoCount',
        size: KoiTextSize.size2,
      ),
      ..._feeComment(d),
    ];
  }

  // ── 费用注释 (来自旧 _feeComment) ──
  List<KoiTicketElement> _feeComment(Map<String, dynamic> d) {
    final preFreightFee = d['preFreightFee']?.toString() ?? '0';
    final unpaidFreight = d['unpaidFreight']?.toString() ?? '0';
    final pickFee = d['pickFee']?.toString() ?? '0';
    final psFee = d['psFee']?.toString() ?? '0';
    final behalfFee = d['behalfFee']?.toString() ?? '0';
    final transFee = d['transFee']?.toString() ?? '0';
    final extFee = d['extFee']?.toString() ?? '0';
    final settlementMethod = d['settlementMethod']?.toString() ?? '';
    final downReceivable = d['downReceivableTotalFee']?.toString() ?? '0';

    return [
      const KoiDividerElement(),
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '现付运费:$preFreightFee', ratio: 1),
          KoiTextColumn(text: '到付运费:$unpaidFreight', ratio: 1),
        ],
      ),
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '接货费:$pickFee', ratio: 1),
          KoiTextColumn(text: '派送费:$psFee', ratio: 1),
        ],
      ),
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '代收:$behalfFee', ratio: 1),
          KoiTextColumn(text: '分拨费:$transFee', ratio: 1),
          KoiTextColumn(text: '垫付费:$extFee', ratio: 1),
        ],
      ),
      KoiTextElement(text: '结算方式:$settlementMethod', size: KoiTextSize.size2),
      KoiTextElement(text: '提货应收:$downReceivable', size: KoiTextSize.size2),
    ];
  }

  // ══════════════════════════════════════════════════════════
  //  提货客户联
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildClientCopy(
    Map<String, dynamic> d,
    KoiPrintConfig config,
  ) {
    final sequnceId = d['sequnceId']?.toString() ?? '';
    final nodeRoleInfo = d['nodeRoleInfo']?.toString() ?? '';
    final bottomOfPage = d['bottomOfPage']?.toString() ?? '';

    final elements = <KoiTicketElement>[
      if (config.headerEmptyLines > 0)
        KoiSpacerElement(lines: config.headerEmptyLines),

      // 页顶信息 (bottomOfPage 实际是页顶横幅)
      if (bottomOfPage.trim().isNotEmpty)
        KoiTextElement(text: bottomOfPage, align: KoiTextAlign.right),

      ..._stateHeader(d),

      KoiTextElement(
        text: d['companyName']?.toString() ?? '',
        align: KoiTextAlign.center,
        size: KoiTextSize.size2,
      ),

      KoiTextElement(text: '发货:${d['fromNodeInfo'] ?? ''}'),
      KoiTextElement(text: '收货:${d['toNodeInfo'] ?? ''}'),

      const KoiTextElement(
        text: '---提货客户联---',
        align: KoiTextAlign.center,
        size: KoiTextSize.size2,
      ),

      KoiTextElement(text: '流水号:$sequnceId', size: KoiTextSize.size2),
      KoiTextElement(text: nodeRoleInfo, size: KoiTextSize.size2),

      ..._staffToFee(d),

      const KoiDividerElement(),
      const KoiSpacerElement(lines: 4),

      KoiSpacerElement(lines: config.paperSize == KoiPaperSize.mm58 ? 1 : 2),

      if (config.cutBehavior != KoiCutBehavior.noCut)
        const KoiCutElement(mode: KoiCutMode.partial),
    ];

    return KoiTicketDocument(
      name: '提货客户联',
      paperSize: config.paperSize,
      elements: elements,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  提货存根联
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildSubCopy(
    Map<String, dynamic> d,
    KoiPrintConfig config,
  ) {
    final ticketSn = d['ticketSn']?.toString() ?? '';
    final barCode = d['barCode']?.toString() ?? '';
    final sequnceId = d['sequnceId']?.toString() ?? '';
    final nodeRoleInfo = d['nodeRoleInfo']?.toString() ?? '';
    final remark = d['remark']?.toString() ?? '';
    final bottomOfPage = d['bottomOfPage']?.toString() ?? '';

    final elements = <KoiTicketElement>[
      if (bottomOfPage.trim().isNotEmpty)
        KoiTextElement(text: bottomOfPage, align: KoiTextAlign.right),

      ..._stateHeader(d),

      KoiTextElement(
        text: '${d['companyName'] ?? ''}\n---提货存根联---',
        align: KoiTextAlign.center,
      ),

      KoiTextElement(text: '流水号:$sequnceId', size: KoiTextSize.size2),

      // 条码 + QR (后缀 'R')
      KoiBarcodeElement(data: '${barCode}R'),
      KoiQrCodeElement(data: ticketSn),

      KoiTextElement(text: nodeRoleInfo),
      ..._staffToFee(d),

      if (remark.trim().isNotEmpty) KoiTextElement(text: '备注:$remark'),

      const KoiDividerElement(),
      const KoiTextElement(text: '客户签字:'),
      const KoiSpacerElement(lines: 4),

      KoiSpacerElement(lines: config.paperSize == KoiPaperSize.mm58 ? 1 : 2),

      if (config.cutBehavior != KoiCutBehavior.noCut)
        const KoiCutElement(mode: KoiCutMode.partial),
    ];

    return KoiTicketDocument(
      name: '提货存根联',
      paperSize: config.paperSize,
      elements: elements,
    );
  }
}
