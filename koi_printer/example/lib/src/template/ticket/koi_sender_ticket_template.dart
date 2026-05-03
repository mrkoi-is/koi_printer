import 'package:koi_printer/koi_printer.dart';

/// TMS 寄件小票模板 — 客户联 & 存根联。
/// 1:1 迁移自旧 XIISenderTicketPapper (245 LOC)。
///
/// 数据字段来自 XIITMSTicketInfo 对象, 传入 Map<String, dynamic>。
class KoiSenderTicketTemplate
    implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiSenderTicketTemplate();

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final docs = <KoiTicketDocument>[];

    for (var i = 0; i < config.copies; i++) {
      // 客户联 — 始终打印
      docs.add(_buildClientCopy(data, config));

      // 存根联 — 仅 withStub 时打印
      if (config.stubType == KoiStubType.withStub) {
        docs.add(_buildSubCopy(data, config));
      }
    }

    return docs;
  }

  // ══════════════════════════════════════════════════════════
  //  共用段落: 公司信息头部 (来自旧 makeComapnyData)
  // ══════════════════════════════════════════════════════════

  /// 添加公司/保价/网单等状态头。
  List<KoiTicketElement> _companyHeader(Map<String, dynamic> d) {
    final elements = <KoiTicketElement>[];
    final isSafe = d['isSafe'] as bool? ?? false;
    final isOnline = d['online'] as bool? ?? false;
    final password = d['password']?.toString() ?? '';

    if (isSafe) {
      elements.add(
        const KoiTextElement(
          text: '☆保 收 运 单☆',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
        ),
      );
    }

    if (isOnline) {
      elements.add(
        const KoiTextElement(
          text: '[网单开单]\n此单不作为代收领取凭证',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
        ),
      );
    }

    if (password.isNotEmpty) {
      elements.add(
        const KoiTextElement(
          text: '----已挂失----',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
          reverse: true,
        ),
      );
    }

    // 公司名称 + 广告语
    elements
      ..add(
        KoiTextElement(
          text: d['companyName']?.toString() ?? '',
          size: KoiTextSize.size2,
          align: KoiTextAlign.center,
        ),
      )
      ..add(KoiTextElement(text: d['companyAdv']?.toString() ?? ''));

    // 发货/收货节点信息
    final fromNode = d['fromNodeInfo']?.toString() ?? '';
    final toNode = d['toNodeInfo']?.toString() ?? '';
    elements
      ..add(KoiTextElement(text: '发货:$fromNode'))
      ..add(KoiTextElement(text: '收货:$toNode'));

    return elements;
  }

  // ══════════════════════════════════════════════════════════
  //  共用段落: 表头信息 (来自旧 makeHeaderData)
  // ══════════════════════════════════════════════════════════

  List<KoiTicketElement> _headerData(Map<String, dynamic> d) {
    final operatorId = d['operatorId']?.toString() ?? '';
    final operatorName = d['operatorName']?.toString() ?? '';
    final ticketSn = d['ticketSn']?.toString() ?? '';
    final sequnceId = d['sequnceId']?.toString() ?? '';
    final startDate = d['startDate']?.toString() ?? '';
    final recieverName = d['recieverName']?.toString() ?? '';
    final recieverPhone = d['recieverPhone']?.toString() ?? '';
    final pickMethod = d['pickMethod']?.toString() ?? '';
    final senderInfo = d['senderInfo']?.toString() ?? '';
    final senderPhone = d['senderPhone']?.toString() ?? '';
    final weight = d['weight']?.toString() ?? '';
    final volume = d['volume']?.toString() ?? '';
    final cargoInfo = d['cargoInfo']?.toString() ?? '';
    final cargoCount = d['cargoCount']?.toString() ?? '';
    final nodeRoleInfo = d['nodeRoleInfo']?.toString() ?? '';

    return [
      // 运单号 + 流水号 双列
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '运单号:$ticketSn', ratio: 1),
          KoiTextColumn(text: '流水号:$sequnceId', ratio: 1),
        ],
      ),

      // 节点班次
      KoiTextElement(text: nodeRoleInfo),

      // 操作员 + 日期
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '操作员:$operatorId[$operatorName]', ratio: 1),
          KoiTextColumn(text: startDate, ratio: 1),
        ],
      ),

      // 收货人 + 电话
      KoiTextElement(text: '收货人:$recieverName[$pickMethod] $recieverPhone'),

      // 发货人
      KoiTextElement(text: '发货人:$senderInfo $senderPhone'),

      // 货物信息
      KoiTextElement(text: '货物:$weight 吨 $volume 方 $cargoInfo 合计:$cargoCount'),
    ];
  }

  // ══════════════════════════════════════════════════════════
  //  共用段落: 费用表单 (来自旧 makeFeeFormData)
  // ══════════════════════════════════════════════════════════

  List<KoiTicketElement> _feeForm(Map<String, dynamic> d) {
    final freightFee = d['freightFee']?.toString() ?? '0';
    final preFreightFee = d['preFreightFee']?.toString() ?? '0';
    final settlementMethod = d['settlementMethod']?.toString() ?? '';
    final insureTotal = d['insureTotal']?.toString() ?? '0';
    final insureFee = d['insureFee']?.toString() ?? '0';
    final pickFee = d['pickFee']?.toString() ?? '0';
    final psFee = d['psFee']?.toString() ?? '0';
    final behalfFee = d['behalfFee']?.toString() ?? '0';
    final transFee = d['transFee']?.toString() ?? '0';
    final extFee = d['extFee']?.toString() ?? '0';
    final upReceivedFee = d['upReceivedFee']?.toString() ?? '0';

    final elements = <KoiTicketElement>[
      // 应收 / 现付 / 结算方式
      KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '应收运费:$freightFee', ratio: 1),
          KoiTextColumn(text: '现付运费:$preFreightFee', ratio: 1),
          KoiTextColumn(text: '结算:$settlementMethod', ratio: 1),
        ],
      ),
    ];

    // 保额/保费 (条件显示)
    final insuredSum =
        (double.tryParse(insureFee) ?? 0) + (double.tryParse(insureTotal) ?? 0);
    if (insuredSum > 0) {
      elements.add(
        KoiTextRowElement(
          columns: [
            KoiTextColumn(text: '保额:$insureTotal', ratio: 1),
            KoiTextColumn(text: '保费:$insureFee', ratio: 1),
            const KoiTextColumn(text: '', ratio: 1),
          ],
        ),
      );
    }

    elements
      // 接货费 / 派送费
      ..add(
        KoiTextRowElement(
          columns: [
            KoiTextColumn(text: '接货费:$pickFee', ratio: 1),
            KoiTextColumn(text: '派送费:$psFee', ratio: 1),
            const KoiTextColumn(text: '', ratio: 1),
          ],
        ),
      )
      // 代收 / 分拨费 / 垫付费
      ..add(
        KoiTextRowElement(
          columns: [
            KoiTextColumn(text: '代收:$behalfFee', ratio: 1),
            KoiTextColumn(text: '分拨费:$transFee', ratio: 1),
            KoiTextColumn(text: '垫付费:$extFee', ratio: 1),
          ],
        ),
      )
      // 已收
      ..add(KoiTextElement(text: '已收:$upReceivedFee'));

    return elements;
  }

  // ══════════════════════════════════════════════════════════
  //  客户联
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildClientCopy(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final barCode = data['barCode']?.toString() ?? '';
    final senderClientQR = data['senderClientQR']?.toString() ?? '';
    final agreement = data['agreement']?.toString() ?? '';

    final elements = <KoiTicketElement>[
      ..._companyHeader(data),

      // 标题 — "发货客户联"
      const KoiTextElement(
        text: '发货客户联',
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),

      ..._headerData(data),
      ..._feeForm(data),
      const KoiDividerElement(),

      // 协议条款
      KoiTextElement(text: agreement),

      // 条码 + QR
      KoiBarcodeElement(data: '${barCode}S'),
      if (senderClientQR.isNotEmpty) KoiQrCodeElement(data: senderClientQR),

      const KoiTextElement(
        text: '=查单/领款请关注"商货通"微信公众号！=',
        align: KoiTextAlign.center,
      ),

      // 尾部空行
      KoiSpacerElement(lines: config.paperSize == KoiPaperSize.mm58 ? 1 : 2),

      if (config.cutBehavior != KoiCutBehavior.noCut)
        const KoiCutElement(mode: KoiCutMode.partial),
    ];

    return KoiTicketDocument(
      name: '发货客户联',
      paperSize: config.paperSize,
      elements: elements,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  存根联
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildSubCopy(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final barCode = data['barCode']?.toString() ?? '';
    final senderSubQR = data['senderSubQR']?.toString() ?? '';
    final rebateFee = data['rebateFee']?.toString() ?? '0';
    final remark = data['remark']?.toString() ?? '';

    final elements = <KoiTicketElement>[
      // 标题
      const KoiTextElement(
        text: '发货存根联',
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),
      const KoiTextElement(text: '此联不作为发货和领取代收款凭证!'),

      ..._headerData(data),
      ..._feeForm(data),
      const KoiDividerElement(),

      // 开拓费 (条件)
      if (rebateFee != '0') KoiTextElement(text: '开拓费:$rebateFee'),

      // 备注 (条件)
      if (remark.trim().isNotEmpty) KoiTextElement(text: '备注:$remark'),

      // 条码 + QR
      KoiBarcodeElement(data: '${barCode}S'),
      if (senderSubQR.isNotEmpty) KoiQrCodeElement(data: senderSubQR),

      // 尾部
      KoiSpacerElement(lines: config.paperSize == KoiPaperSize.mm58 ? 1 : 2),

      if (config.cutBehavior != KoiCutBehavior.noCut)
        const KoiCutElement(mode: KoiCutMode.partial),
    ];

    return KoiTicketDocument(
      name: '发货存根联',
      paperSize: config.paperSize,
      elements: elements,
    );
  }
}
