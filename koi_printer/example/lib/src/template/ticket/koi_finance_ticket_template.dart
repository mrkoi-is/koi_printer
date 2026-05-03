import 'package:koi_printer/koi_printer.dart';

/// TMS 代收发放明细 / 缴款明细 通用模板。
/// 1:1 迁移自旧 XIIIssuedPapper (134 LOC) + XIIPaymentRequestPapper (90 LOC)。
///
/// [isPayment] = true → 缴款明细; false → 代收发放明细。
class KoiFinanceTicketTemplate
    implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiFinanceTicketTemplate({this.isPayment = false});

  final bool isPayment;

  @override
  List<KoiTicketDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    if (isPayment) {
      return [_buildPayment(data, config)];
    } else {
      return [_buildIssued(data, config)];
    }
  }

  // ══════════════════════════════════════════════════════════
  //  代收发放明细 (来自旧 XIIIssuedPapper)
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildIssued(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final companyName = data['companyName']?.toString() ?? '';
    final nodeName = data['nodeName']?.toString() ?? '';
    final operatorName = data['operatorName']?.toString() ?? '';
    final date = data['date']?.toString() ?? '';
    final totalPrice = data['totalPrice']?.toString() ?? '0';
    final issuedFee = data['issuedFee']?.toString() ?? '0';
    final procedureFee = data['procedureFee']?.toString() ?? '0';
    final deductibleFee = data['deductibleFee']?.toString() ?? '0';
    final totalCount = data['totalCount']?.toString() ?? '0';
    final method = data['method']?.toString() ?? '';
    final client = data['client']?.toString() ?? '';
    final fotter = data['fotter']?.toString() ?? '';
    final bankInfo = data['bankInfo'] as Map<String, dynamic>?;
    final items = data['items'] as List<dynamic>? ?? [];

    final elements = <KoiTicketElement>[
      // 标题
      KoiTextElement(text: '$companyName代收发放明细', align: KoiTextAlign.center),
      KoiTextElement(text: '节点:$nodeName'),
      KoiTextElement(text: '操作员: $operatorName'),
      KoiTextElement(text: '日  期: $date'),
    ];

    // 银行信息 (条件段)
    if (bankInfo != null) {
      final bankNumber = bankInfo['bankNumber']?.toString() ?? '';
      final bankName = bankInfo['bankName']?.toString() ?? '';
      final bankAccount = bankInfo['bankAccount']?.toString() ?? '';
      final phone = bankInfo['phone']?.toString() ?? '';

      elements
        ..add(KoiTextElement(text: '账号:$bankNumber'))
        ..add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '开户行:$bankName', ratio: 1),
              KoiTextColumn(text: '委托代收:$totalPrice', ratio: 1),
            ],
          ),
        )
        ..add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '户名:$bankAccount', ratio: 1),
              KoiTextColumn(text: '实收金额:$issuedFee', ratio: 1),
            ],
          ),
        )
        ..add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '电话:$phone', ratio: 1),
              KoiTextColumn(text: '减手续费:$procedureFee', ratio: 1),
            ],
          ),
        );
    } else {
      elements
        ..add(KoiTextElement(text: '节  点: $nodeName'))
        ..add(KoiTextElement(text: '领款方式: $method'))
        ..add(KoiTextElement(text: '领款人: $client'));
    }

    // 表头
    elements
      ..add(const KoiDividerElement())
      ..add(
        const KoiTextRowElement(
          columns: [
            KoiTextColumn(text: '货号', ratio: 5),
            KoiTextColumn(text: '收货人', ratio: 3),
            KoiTextColumn(text: '代收', ratio: 3),
          ],
        ),
      )
      ..add(const KoiDividerElement());

    // 列表行 (forEach)
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        elements.add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: item['ticketSN']?.toString() ?? '', ratio: 5),
              KoiTextColumn(
                text: item['receiverName']?.toString() ?? '',
                ratio: 3,
              ),
              KoiTextColumn(
                text: item['behalfFee']?.toString() ?? '',
                ratio: 3,
              ),
            ],
          ),
        );
      }
    }

    // 页脚
    elements.add(const KoiDividerElement());

    if (bankInfo == null) {
      elements
        ..add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '合计:$totalCount单', ratio: 1),
              KoiTextColumn(text: '代收款:$totalPrice', ratio: 1),
              KoiTextColumn(text: '手续费:$procedureFee', ratio: 1),
              KoiTextColumn(text: '抵扣:$deductibleFee', ratio: 1),
            ],
          ),
        )
        ..add(const KoiSpacerElement(lines: 1))
        ..add(KoiTextElement(text: '结算:$issuedFee', size: KoiTextSize.size2));
    }

    elements
      ..add(KoiTextElement(text: fotter))
      ..add(const KoiSpacerElement(lines: 2))
      ..add(const KoiCutElement());

    return KoiTicketDocument(
      name: '代收发放明细',
      paperSize: config.paperSize,
      elements: elements,
    );
  }

  // ══════════════════════════════════════════════════════════
  //  缴款明细 (来自旧 XIIPaymentRequestPapper)
  // ══════════════════════════════════════════════════════════

  KoiTicketDocument _buildPayment(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final companyName = data['companyName']?.toString() ?? '';
    final type = data['type']?.toString() ?? '';
    final nodeName = data['nodeName']?.toString() ?? '';
    final operatorName = data['operatorName']?.toString() ?? '';
    final date = data['date']?.toString() ?? '';
    final totalPrice = data['totalPrice']?.toString() ?? '0';
    final items = data['items'] as List<dynamic>? ?? [];

    final elements = <KoiTicketElement>[
      KoiTextElement(
        text: companyName,
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),
      KoiTextElement(
        text: '$type缴款明细',
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
      ),
      KoiTextElement(text: '节  点: $nodeName'),
      KoiTextElement(text: '操作员: $operatorName'),
      KoiTextElement(text: '日  期: $date'),
      const KoiDividerElement(),

      // 表头
      const KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '单号', ratio: 3),
          KoiTextColumn(text: '运费', ratio: 2),
          KoiTextColumn(text: '代收', ratio: 3),
          KoiTextColumn(text: '垫付', ratio: 2),
          KoiTextColumn(text: '现付', ratio: 2),
        ],
      ),
      const KoiDividerElement(),
    ];

    // 列表行
    for (final item in items) {
      if (item is Map<String, dynamic>) {
        elements.add(
          KoiTextRowElement(
            columns: [
              KoiTextColumn(text: item['ticketSN']?.toString() ?? '', ratio: 3),
              KoiTextColumn(
                text: item['freightFee']?.toString() ?? '',
                ratio: 2,
              ),
              KoiTextColumn(
                text: item['behalfFee']?.toString() ?? '',
                ratio: 3,
              ),
              KoiTextColumn(text: item['extFee']?.toString() ?? '', ratio: 2),
              KoiTextColumn(
                text: item['preFreightFee']?.toString() ?? '',
                ratio: 2,
              ),
            ],
          ),
        );
      }
    }

    // 页脚
    elements
      ..add(const KoiDividerElement())
      ..add(KoiTextElement(text: '合计:$totalPrice', size: KoiTextSize.size2))
      ..add(const KoiSpacerElement(lines: 5))
      ..add(const KoiCutElement());

    return KoiTicketDocument(
      name: '$type缴款明细',
      paperSize: config.paperSize,
      elements: elements,
    );
  }
}
