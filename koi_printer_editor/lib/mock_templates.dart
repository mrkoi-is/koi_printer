import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

int _idCounter = 0;
String _genId() => '${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';

// ═══════════════════════════════════════════════════════════
// 模板清单库 — 每个模板携带完整的元数据 + Schema + 分组
// ═══════════════════════════════════════════════════════════

final List<KoiTemplateManifest> templateManifests = [
  // ── 寄件客户联 (TMS) ──
  KoiTemplateManifest(
    id: 'tms_sender_v1',
    name: '寄件客户联 (TMS)',
    category: 'tms',
    description: '标准物流寄件面单，含条码、二维码、运费明细、收发件人信息',
    schema: const [
      KoiTemplateField(key: 'companyName', label: '公司名称'),
      KoiTemplateField(key: 'companyAdv', label: '宣传语'),
      KoiTemplateField(key: 'fromNodeInfo', label: '发件网点'),
      KoiTemplateField(key: 'toNodeInfo', label: '目的网点'),
      KoiTemplateField(key: 'ticketSn', label: '运单号'),
      KoiTemplateField(key: 'sequnceId', label: '流水号'),
      KoiTemplateField(key: 'operatorName', label: '操作员'),
      KoiTemplateField(key: 'startDate', label: '开单时间'),
      KoiTemplateField(key: 'recieverName', label: '收件人'),
      KoiTemplateField(key: 'recieverPhone', label: '收件电话'),
      KoiTemplateField(key: 'pickMethod', label: '取件方式'),
      KoiTemplateField(key: 'senderInfo', label: '发件人'),
      KoiTemplateField(key: 'senderPhone', label: '发件电话'),
      KoiTemplateField(key: 'weight', label: '重量'),
      KoiTemplateField(key: 'volume', label: '体积'),
      KoiTemplateField(key: 'cargoInfo', label: '品名'),
      KoiTemplateField(key: 'cargoCount', label: '件数'),
      KoiTemplateField(key: 'freightFee', label: '应收运费'),
      KoiTemplateField(key: 'preFreightFee', label: '现付运费'),
      KoiTemplateField(key: 'settlementMethod', label: '结算方式'),
      KoiTemplateField(key: 'pickFee', label: '接货费'),
      KoiTemplateField(key: 'psFee', label: '派送费'),
      KoiTemplateField(key: 'totalFee', label: '总运费'),
      KoiTemplateField(key: 'remark', label: '备注'),
    ],
    groups: const [
      KoiTemplateGroup(label: '标题区', startIndex: 0, endIndex: 3),
      KoiTemplateGroup(label: '条码 & 单号', startIndex: 4, endIndex: 7),
      KoiTemplateGroup(label: '收发件人信息', startIndex: 8, endIndex: 10),
      KoiTemplateGroup(label: '费用明细', startIndex: 11, endIndex: 14),
      KoiTemplateGroup(label: '底部', startIndex: 15, endIndex: 16),
    ],
    mockData: const {
      'companyName': '顺丰速运 (SF Express)',
      'companyAdv': '一站式供应链解决方案提供商',
      'fromNodeInfo': '深圳南山科技园网点',
      'toNodeInfo': '北京朝阳国贸网点',
      'ticketSn': 'SF1234567890123',
      'sequnceId': '0001',
      'operatorName': '张三丰',
      'startDate': '2026-05-04 12:00:00',
      'recieverName': '李四',
      'pickMethod': '派送',
      'recieverPhone': '138****8000',
      'senderInfo': '王五',
      'senderPhone': '139****9000',
      'weight': '2.5',
      'volume': '0.01',
      'cargoInfo': '电子产品',
      'cargoCount': '1',
      'freightFee': '18.00',
      'preFreightFee': '18.00',
      'settlementMethod': '现付',
      'pickFee': '0.00',
      'psFee': '0.00',
      'totalFee': '18.00',
      'remark': '易碎物品，请轻拿轻放',
    },
    document: KoiTicketDocument(elements: [
      KoiTextElement(text: '{{companyName}}', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: '{{companyAdv}}', align: KoiTextAlign.center),
      KoiTextElement(text: '发货: {{fromNodeInfo}}'),
      KoiTextElement(text: '收货: {{toNodeInfo}}'),
      KoiDividerElement(),
      KoiBarcodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center),
      KoiTextRowElement(columns: [KoiTextColumn(text: '运单号: {{ticketSn}}', ratio: 1), KoiTextColumn(text: '流水号: {{sequnceId}}', ratio: 1)]),
      KoiTextRowElement(columns: [KoiTextColumn(text: '操作员: {{operatorName}}', ratio: 1), KoiTextColumn(text: '{{startDate}}', ratio: 1)]),
      KoiTextElement(text: '收货人: {{recieverName}} [{{pickMethod}}] {{recieverPhone}}', bold: true),
      KoiTextElement(text: '发货人: {{senderInfo}} {{senderPhone}}'),
      KoiTextElement(text: '货物: {{weight}}吨 {{volume}}方 {{cargoInfo}} 合计:{{cargoCount}}'),
      KoiDividerElement(char: '-'),
      KoiTextRowElement(columns: [KoiTextColumn(text: '应收运费: {{freightFee}}', ratio: 1), KoiTextColumn(text: '现付运费: {{preFreightFee}}', ratio: 1), KoiTextColumn(text: '结算: {{settlementMethod}}', ratio: 1)]),
      KoiTextRowElement(columns: [KoiTextColumn(text: '接货费: {{pickFee}}', ratio: 1), KoiTextColumn(text: '派送费: {{psFee}}', ratio: 1)]),
      KoiTextElement(text: '总计总额: {{totalFee}}', bold: true, size: KoiTextSize.size2),
      KoiDividerElement(char: '-'),
      KoiTextElement(text: '备注: {{remark}}'),
      KoiQrCodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center),
      KoiCutElement(),
    ]),
  ),

  // ── 收件查货单 (TMS) ──
  KoiTemplateManifest(
    id: 'tms_receiver_v1',
    name: '收件查货单 (TMS)',
    category: 'tms',
    description: '收货方查货凭证，含代收货款信息',
    schema: const [
      KoiTemplateField(key: 'ticketSn', label: '运单号'),
      KoiTemplateField(key: 'recieverName', label: '收件人'),
      KoiTemplateField(key: 'recieverPhone', label: '收件电话'),
      KoiTemplateField(key: 'behalfFee', label: '代收货款'),
    ],
    mockData: const {
      'ticketSn': 'SF1234567890123',
      'recieverName': '李四',
      'recieverPhone': '138****8000',
      'behalfFee': '0.00',
    },
    document: KoiTicketDocument(elements: [
      KoiTextElement(text: 'TMS 查货凭证', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2),
      KoiBarcodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center),
      KoiDividerElement(),
      KoiTextElement(text: '运单号: {{ticketSn}}', bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: '收货人: {{recieverName}} {{recieverPhone}}', bold: true),
      KoiTextElement(text: '代收货款: {{behalfFee}}', bold: true),
      KoiCutElement(),
    ]),
  ),

  // ── 交款单 (Finance) ──
  KoiTemplateManifest(
    id: 'finance_handover_v1',
    name: '交款单 (Finance)',
    category: 'finance',
    description: '财务交款单，含业务员交接明细列表 (ForEach)',
    schema: const [
      KoiTemplateField(key: 'nodeInfo', label: '网点信息'),
      KoiTemplateField(key: 'bizerName', label: '业务员'),
      KoiTemplateField(key: 'handUser', label: '交款人'),
      KoiTemplateField(key: 'handDate', label: '交款时间'),
      KoiTemplateField(key: 'totalAmount', label: '总计金额'),
      KoiTemplateField(key: 'items', label: '交接明细列表', type: KoiFieldType.array),
    ],
    groups: const [
      KoiTemplateGroup(label: '标题 & 信息', startIndex: 0, endIndex: 4),
      KoiTemplateGroup(label: '明细列表', startIndex: 5, endIndex: 8),
      KoiTemplateGroup(label: '合计', startIndex: 9, endIndex: 10),
    ],
    mockData: const {
      'nodeInfo': '深圳高新园财务中心',
      'bizerName': '李四',
      'handUser': '王五',
      'handDate': '2026-05-04 18:00',
      'totalAmount': '¥ 50,000',
      'items': [
        {'name': '顺丰特快', 'count': 100, 'amount': '¥1,800'},
        {'name': '顺丰标快', 'count': 500, 'amount': '¥6,000'},
        {'name': '包装费', 'count': 100, 'amount': '¥500'},
      ],
    },
    document: KoiTicketDocument(elements: [
      KoiTextElement(text: '交款单', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: '网点: {{nodeInfo}}', align: KoiTextAlign.center),
      KoiDividerElement(),
      KoiTextRowElement(columns: [KoiTextColumn(text: '业务员: {{bizerName}}', ratio: 1), KoiTextColumn(text: '交款人: {{handUser}}', ratio: 1)]),
      KoiTextElement(text: '交款时间: {{handDate}}'),
      KoiDividerElement(char: '-'),
      KoiTextRowElement(columns: [KoiTextColumn(text: '项目', ratio: 6), KoiTextColumn(text: '票数', ratio: 2, align: KoiTextAlign.center), KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right)]),
      KoiDividerElement(char: '-'),
      KoiTicketForEachElement(listKey: 'items', templates: [
        KoiTextRowElement(columns: [KoiTextColumn(text: '{{name}}', ratio: 6), KoiTextColumn(text: '{{count}}', ratio: 2, align: KoiTextAlign.center), KoiTextColumn(text: '{{amount}}', ratio: 4, align: KoiTextAlign.right)]),
      ]),
      KoiDividerElement(char: '-'),
      KoiTextElement(text: '总计交款: {{totalAmount}}', bold: true, size: KoiTextSize.size2),
      KoiCutElement(),
    ]),
  ),

  // ── 请款单 (Payment) ──
  KoiTemplateManifest(
    id: 'payment_request_v1',
    name: '请款单 (Payment)',
    category: 'payment',
    description: '请款申请单，含审批签字留白',
    schema: const [
      KoiTemplateField(key: 'requestUser', label: '请款人'),
      KoiTemplateField(key: 'requestAmount', label: '请款金额'),
      KoiTemplateField(key: 'reason', label: '请款事由'),
    ],
    mockData: const {
      'requestUser': '赵六',
      'requestAmount': '¥ 5,000.00',
      'reason': '采购新一批打印纸和碳带',
    },
    document: KoiTicketDocument(elements: [
      KoiTextElement(text: '请款单', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: '请款人: {{requestUser}}'),
      KoiTextElement(text: '请款金额: {{requestAmount}}', bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: '请款事由: {{reason}}'),
      KoiSpacerElement(lines: 2),
      KoiTextRowElement(columns: [KoiTextColumn(text: '审批人签字:', ratio: 1), KoiTextColumn(text: '财务签字:', ratio: 1)]),
      KoiSpacerElement(lines: 3),
      KoiCutElement(),
    ]),
  ),

  // ── 简单收据 (Demo) ──
  KoiTemplateManifest(
    id: 'demo_receipt_v1',
    name: '简单收据 (Demo)',
    category: 'demo',
    description: '演示模板，含 ForEach 商品循环和二维码',
    schema: const [
      KoiTemplateField(key: 'fee.total', label: '合计金额'),
      KoiTemplateField(key: 'items', label: '商品列表', type: KoiFieldType.array),
    ],
    mockData: const {
      'fee': {'total': 188.0},
      'items': [
        {'name': 'Koi 机械键盘', 'qty': 1, 'price': 99.0},
        {'name': 'Type-C 数据线', 'qty': 2, 'price': 19.9},
      ],
    },
    document: KoiTicketDocument(elements: [
      KoiTextElement(text: 'Mr.Koi Store', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2),
      KoiTextElement(text: 'www.mrkoi.com', align: KoiTextAlign.center),
      KoiDividerElement(),
      KoiTextRowElement(columns: [KoiTextColumn(text: '商品', ratio: 6), KoiTextColumn(text: '数量', ratio: 2, align: KoiTextAlign.center), KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right)]),
      KoiDividerElement(char: '-'),
      KoiTicketForEachElement(listKey: 'items', templates: [
        KoiTextRowElement(columns: [KoiTextColumn(text: '{{name}}', ratio: 6), KoiTextColumn(text: '{{qty}}', ratio: 2, align: KoiTextAlign.center), KoiTextColumn(text: '{{price}}', ratio: 4, align: KoiTextAlign.right)]),
      ]),
      KoiDividerElement(),
      KoiTextRowElement(columns: [KoiTextColumn(text: '合计', ratio: 8, bold: true), KoiTextColumn(text: '¥{{fee.total}}', ratio: 4, align: KoiTextAlign.right)]),
      KoiSpacerElement(lines: 1),
      KoiQrCodeElement(data: 'https://mrkoi.io', align: KoiTextAlign.center, size: KoiQrSize.size5),
      KoiCutElement(),
    ]),
  ),
];

// ═══════════════════════════════════════════════════════════
// 编辑器兼容层 — Manifest → EditorElement 转换
// ═══════════════════════════════════════════════════════════

/// 将 Manifest 的 document.elements 转换为编辑器可用的 EditorElement 列表。
List<EditorElement> manifestToEditorElements(KoiTemplateManifest manifest) {
  final doc = manifest.document;
  if (doc is KoiTicketDocument) {
    return doc.elements.map((e) => EditorElement(id: _genId(), element: e)).toList();
  }
  return [];
}

/// 默认加载的模板 (寄件客户联)。
final KoiTemplateManifest defaultManifest = templateManifests.first;
final List<EditorElement> defaultTemplateElements = manifestToEditorElements(defaultManifest);
