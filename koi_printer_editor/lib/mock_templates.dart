import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

final Map<String, List<EditorElement>> templateGallery = {
  '简单收据 (Demo)': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: 'Mr.Koi Store', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: 'www.mrkoi.com', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '商品', ratio: 6),
      KoiTextColumn(text: '数量', ratio: 2, align: KoiTextAlign.center),
      KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: KoiTicketForEachElement(listKey: 'items', templates: [
      KoiTextRowElement(columns: const [
        KoiTextColumn(text: '{{name}}', ratio: 6),
        KoiTextColumn(text: '{{qty}}', ratio: 2, align: KoiTextAlign.center),
        KoiTextColumn(text: '{{price}}', ratio: 4, align: KoiTextAlign.right),
      ]),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '合计', ratio: 8, bold: true),
      KoiTextColumn(text: '¥{{fee.total}}', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiSpacerElement(lines: 1)),
    EditorElement(id: _genId(), element: const KoiQrCodeElement(data: 'https://mrkoi.io', align: KoiTextAlign.center, size: KoiQrSize.size5)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '寄件客户联 (TMS)': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: '{{companyName}}', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '{{companyAdv}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '发货: {{fromNodeInfo}}')),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '收货: {{toNodeInfo}}')),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiBarcodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '运单号: {{ticketSn}}', ratio: 1),
      KoiTextColumn(text: '流水号: {{sequnceId}}', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '操作员: {{operatorName}}', ratio: 1),
      KoiTextColumn(text: '{{startDate}}', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '收货人: {{recieverName}} [{{pickMethod}}] {{recieverPhone}}', bold: true)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '发货人: {{senderInfo}} {{senderPhone}}')),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '货物: {{weight}}吨 {{volume}}方 {{cargoInfo}} 合计:{{cargoCount}}')),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '应收运费: {{freightFee}}', ratio: 1),
      KoiTextColumn(text: '现付运费: {{preFreightFee}}', ratio: 1),
      KoiTextColumn(text: '结算: {{settlementMethod}}', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '接货费: {{pickFee}}', ratio: 1),
      KoiTextColumn(text: '派送费: {{psFee}}', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '总计总额: {{totalFee}}', bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '备注: {{remark}}')),
    EditorElement(id: _genId(), element: const KoiQrCodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '收件查货单 (TMS)': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: 'TMS 查货凭证', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiBarcodeElement(data: '{{ticketSn}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '运单号: {{ticketSn}}', bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '收货人: {{recieverName}} {{recieverPhone}}', bold: true)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '代收货款: {{behalfFee}}', bold: true)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '交款单 (Finance)': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: '交款单', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '网点: {{nodeInfo}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '业务员: {{bizerName}}', ratio: 1),
      KoiTextColumn(text: '交款人: {{handUser}}', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '交款时间: {{handDate}}')),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '项目', ratio: 6),
      KoiTextColumn(text: '票数', ratio: 2, align: KoiTextAlign.center),
      KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: KoiTicketForEachElement(listKey: 'items', templates: [
      KoiTextRowElement(columns: const [
        KoiTextColumn(text: '{{name}}', ratio: 6),
        KoiTextColumn(text: '{{count}}', ratio: 2, align: KoiTextAlign.center),
        KoiTextColumn(text: '{{amount}}', ratio: 4, align: KoiTextAlign.right),
      ]),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '总计交款: {{totalAmount}}', bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '请款单 (Payment)': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: '请款单', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '请款人: {{requestUser}}')),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '请款金额: {{requestAmount}}', bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '请款事由: {{reason}}')),
    EditorElement(id: _genId(), element: const KoiSpacerElement(lines: 2)),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '审批人签字:', ratio: 1),
      KoiTextColumn(text: '财务签字:', ratio: 1),
    ])),
    EditorElement(id: _genId(), element: const KoiSpacerElement(lines: 3)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '空白模板': [],
};

final List<EditorElement> defaultTemplateElements = templateGallery['寄件客户联 (TMS)']!;
