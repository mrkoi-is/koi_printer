import 'package:koi_printer/koi_printer.dart';

/// 这个文件用于演示在真实 TMS 业务中，如何使用 JSON 和动态模板引擎
/// 替代原有的硬编码 `.dart` 模板文件。
class KoiDynamicTemplateDemo implements KoiTicketTemplate<Map<String, dynamic>> {
  const KoiDynamicTemplateDemo();

  /// 模拟从后端接口下发的 JSON 排版配置。
  /// 注意看：这里的排版全部由 JSON 描述，并使用 {{变量名}} 作为占位符！
  static const String serverResponseJson = '''
{
  "documentType": "ticket",
  "paperSize": 80,
  "name": "TMS 寄件小票 (JSON动态渲染)",
  "elements": [
    { "type": "text", "text": "TMS 智慧物流", "size": "size2", "align": "center", "bold": true },
    { "type": "divider", "char": "=" },
    { "type": "text", "text": "发货: {{senderCity}} >>> 收货: {{receiverCity}}", "bold": true, "size": "size2" },
    { "type": "divider", "char": "=" },
    { "type": "textRow", "columns": [
      { "text": "运单号: {{waybillNo}}" },
      { "text": "操作员: {{driver}}" }
    ]},
    { "type": "text", "text": "收件人: {{receiverName}} [{{receiverInfo}}]" },
    { "type": "text", "text": "寄件人: {{senderName}}" },
    { "type": "text", "text": "收货地址: {{address}}" },
    { "type": "divider", "char": "-" },
    { "type": "text", "text": "商品清单: (共 {{totalPackages}} 件)" },
    { "type": "ticketForEach", "listKey": "items", "templates": [
      { "type": "textRow", "columns": [
        { "text": " * {{name}}", "ratio": 2 },
        { "text": "x{{count}}", "align": "center" },
        { "text": "{{weight}}kg", "align": "right" }
      ]}
    ]},
    { "type": "divider", "char": "-" },
    { "type": "textRow", "columns": [
      { "text": "合计金额:" },
      { "text": "¥{{amount}}", "align": "right", "bold": true }
    ]},
    { "type": "textRow", "columns": [
      { "text": "支付方式:" },
      { "text": "{{method}}", "align": "right" }
    ]},
    { "type": "spacer", "lines": 2 },
    { "type": "barcode", "data": "{{waybillNo}}", "align": "center", "height": 80 },
    { "type": "text", "text": "扫码或关注微信公众号查询物流轨迹", "align": "center" },
    { "type": "spacer", "lines": 3 },
    { "type": "cut", "mode": "partial" }
  ]
}
''';

  /// 模拟 TMS 实际调用打印的流程 (将复制到您的业务工程中)
  @override
  List<KoiTicketDocument> build(Map<String, dynamic>? data, KoiPrintConfig config) {
    if (data == null) return [];

    // 1. 将服务器下发的 JSON 字符串，反序列化为文档对象
    final KoiTicketDocument templateDoc = 
        koiPrintDocumentFromJsonString(serverResponseJson) as KoiTicketDocument;

    // 2. 实例化模板绑定引擎
    const engine = KoiTemplateEngine();

    // 3. 将真实业务数据喂给引擎，替换掉所有的 {{xxx}} 和 <ForEach>
    final KoiTicketDocument finalDoc = engine.expandTicket(templateDoc, data);

    return [finalDoc];
  }
}
