import 'package:koi_printer/koi_printer.dart';

/// TMS 货物标签模板 — 80mm x 50mm
/// 常用于物流中转站的货物分拣标签。
class KoiSenderLabelTemplate implements KoiLabelTemplate<Map<String, dynamic>> {
  const KoiSenderLabelTemplate();

  @override
  List<KoiLabelDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    return [for (var i = 0; i < config.copies; i++) _buildLabel(data, config)];
  }

  KoiLabelDocument _buildLabel(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final waybillNo = data['waybillNo']?.toString() ?? 'N/A';
    final receiverCity = data['receiverCity']?.toString() ?? '收件市';
    final address = data['address']?.toString() ?? '';
    final routeNo = data['routeNo']?.toString() ?? '';
    final location = data['location']?.toString() ?? '';
    final totalPackages = data['totalPackages']?.toString() ?? '1';

    // TMS 标签纸尺寸: 80mm x 50mm
    // 203dpi: 宽 ≈ 640 dots, 高 ≈ 400 dots
    const setup = KoiLabelSetupElement(widthMm: 80, heightMm: 50, gapMm: 2);

    return KoiLabelDocument(
      name: 'TMS货物标签-$waybillNo',
      elements: [
        setup,

        // ── 外边框 ──
        const KoiLabelBoxElement(
          x: 10,
          y: 10,
          width: 620,
          height: 380,
          thickness: 4,
        ),

        // ── 顶部区域: 目的地 + 路由信息 ──
        const KoiLabelBoxElement(
          x: 10,
          y: 10,
          width: 620,
          height: 90,
          thickness: 4,
        ),
        const KoiPositionedTextElement(x: 20, y: 25, text: '到站:', fontSize: 48),
        KoiPositionedTextElement(
          x: 160,
          y: 15,
          text: receiverCity,
          fontSize: 64,
          bold: true,
        ),
        KoiPositionedTextElement(
          x: 420,
          y: 25,
          text: routeNo,
          fontSize: 32,
          bold: true,
        ),
        KoiPositionedTextElement(
          x: 420,
          y: 60,
          text: '区位: $location',
          fontSize: 24,
        ),

        // ── 中间区域: 条码 ──
        KoiPositionedBarcodeElement(x: 60, y: 120, data: waybillNo, height: 80),
        KoiPositionedTextElement(
          x: 180,
          y: 210,
          text: waybillNo,
          fontSize: 32,
          bold: true,
        ),

        // ── 分割线 ──
        const KoiLabelBoxElement(x: 10, y: 260, width: 620, height: 4),

        // ── 底部区域: 地址 + 件数 ──
        const KoiPositionedTextElement(
          x: 20,
          y: 280,
          text: '收件:',
          fontSize: 32,
        ),
        KoiLabelBlockTextElement(
          x: 110,
          y: 280,
          width: 350,
          height: 90,
          text: address,
        ),
        // 竖向分割线
        const KoiLabelLineElement(x: 480, y: 260, width: 4, height: 130),
        const KoiPositionedTextElement(
          x: 500,
          y: 280,
          text: '件数',
          fontSize: 24,
        ),
        KoiPositionedTextElement(
          x: 500,
          y: 310,
          text: totalPackages,
          fontSize: 48,
          bold: true,
        ),

        // ── 出纸 ──
        const KoiLabelPrintElement(copies: 1),
      ],
    );
  }
}
