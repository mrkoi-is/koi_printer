import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 简单标签 Demo 模板。
/// 展示 TSPL/CPCL 坐标定位布局的最简上手示例。
class KoiSimpleLabelTemplate extends KoiPrintTemplate {
  const KoiSimpleLabelTemplate();

  @override
  String get templateId => 'simple_label';

  @override
  String get displayName => '简单标签 (Demo)';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiLabelDocument(
      elements: [
        // 标签尺寸设置 (100mm x 60mm, 3mm 间距)
        const KoiLabelSetupElement(widthMm: 100, heightMm: 60, gapMm: 3),

        // 公司名 — 顶部居中
        const KoiPositionedTextElement(
          x: 50, y: 10,
          text: 'Mr.Koi Logistics',
          font: '3',
          xScale: 2, yScale: 2,
        ),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 55, width: 800, height: 2),

        // 收件人信息区
        const KoiPositionedTextElement(x: 10, y: 65, text: '收: {{receiver_name}}'),
        const KoiPositionedTextElement(x: 10, y: 90, text: '    {{receiver_phone}}'),
        const KoiPositionedTextElement(x: 10, y: 115, text: '    {{receiver_address}}'),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 155, width: 800, height: 2),

        // 寄件人信息区
        const KoiPositionedTextElement(x: 10, y: 165, text: '寄: {{sender_name}}  {{sender_phone}}'),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 185, width: 800, height: 2),

        // 条形码 + 单号
        const KoiPositionedBarcodeElement(
          x: 150, y: 200,
          data: '{{waybill_sn}}',
          height: 80,
        ),
        const KoiPositionedTextElement(
          x: 150, y: 290,
          text: '{{waybill_sn}}',
          font: '2',
          xScale: 2, yScale: 2,
        ),

        // 打印
        const KoiLabelPrintElement(),
      ],
    );
  }
}
