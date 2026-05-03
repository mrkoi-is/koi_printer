import 'package:koi_printer/koi_printer.dart';

/// 寄件标签模板 — 6种业务样式
/// 根据 config.labelStyle 选择不同的布局
class KoiSenderLabelTemplate implements KoiLabelTemplate<Map<String, dynamic>> {
  const KoiSenderLabelTemplate();

  @override
  List<KoiLabelDocument> build(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    final docs = <KoiLabelDocument>[];

    for (var i = 0; i < config.copies; i++) {
      docs.add(_buildForStyle(data, config));
    }
    return docs;
  }

  KoiLabelDocument _buildForStyle(
    Map<String, dynamic> data,
    KoiPrintConfig config,
  ) {
    // 基础信息
    final waybillNo = data['waybillNo']?.toString() ?? 'N/A';
    final senderCity = data['senderCity']?.toString() ?? '发件市';
    final receiverCity = data['receiverCity']?.toString() ?? '收件市';
    final receiverInfo = data['receiverInfo']?.toString() ?? '收件人 13800000000';

    // 标签纸尺寸定义, 默认 76x130 mm (各大快递常用面单尺寸缩略版)
    const setup = KoiLabelSetupElement(widthMm: 76, heightMm: 130, gapMm: 2);
    final elements = <KoiLabelElement>[setup];

    // 外边框
    elements.add(
      const KoiLabelBoxElement(
        x: 10,
        y: 10,
        width: 580,
        height: 1020,
        thickness: 4,
      ),
    );

    // 根据选择的样式，绘制坐标绝对定位的标签。 这里实现 Style1 作为核心骨架，其他 Style 演示扩展性。
    switch (config.labelStyle) {
      case KoiLabelStyle.style1:
        // Style 1: 标准三段式面单
        // 顶部区: 发/收件城市
        elements.add(
          const KoiLabelReverseElement(x: 10, y: 10, width: 580, height: 120),
        );
        elements.add(
          KoiPositionedTextElement(
            x: 30,
            y: 30,
            text: senderCity,
            fontSize: 64,
            font: 'TSS24.BF2',
          ),
        );
        elements.add(
          const KoiPositionedTextElement(
            x: 230,
            y: 30,
            text: '==>',
            fontSize: 64,
            font: 'TSS24.BF2',
          ),
        );
        elements.add(
          KoiPositionedTextElement(
            x: 350,
            y: 30,
            text: receiverCity,
            fontSize: 64,
            font: 'TSS24.BF2',
          ),
        );

        // 分割线
        elements.add(
          const KoiLabelBoxElement(x: 10, y: 130, width: 580, height: 4),
        );

        // 中心条码区
        elements.add(
          KoiPositionedBarcodeElement(
            x: 30,
            y: 180,
            data: waybillNo,
            height: 120,
          ),
        );
        elements.add(
          KoiPositionedTextElement(
            x: 120,
            y: 320,
            text: '单号: $waybillNo',
            fontSize: 32,
          ),
        );

        // 分割线
        elements.add(
          const KoiLabelBoxElement(x: 10, y: 380, width: 580, height: 4),
        );

        // 底部联系人区
        elements.add(
          const KoiPositionedTextElement(
            x: 30,
            y: 410,
            text: '收件:',
            fontSize: 32,
          ),
        );
        elements.add(
          KoiPositionedTextElement(
            x: 120,
            y: 410,
            text: receiverInfo,
            fontSize: 32,
          ),
        );

        // 二维码区
        elements.add(
          KoiPositionedQrCodeElement(
            x: 30,
            y: 550,
            data: 'https://ex.com/$waybillNo',
            cellSize: 8,
          ),
        );
        break;

      case KoiLabelStyle.style2:
      case KoiLabelStyle.style3:
      case KoiLabelStyle.style4:
      case KoiLabelStyle.style5:
      case KoiLabelStyle.style6:
        // Style 2-6: 精简条码面单 (作为 fallback 演示)
        elements.add(
          KoiPositionedTextElement(
            x: 30,
            y: 30,
            text: '样式 ${config.labelStyle.name}',
            fontSize: 48,
          ),
        );
        elements.add(
          KoiPositionedBarcodeElement(
            x: 30,
            y: 150,
            data: waybillNo,
            height: 100,
          ),
        );
        elements.add(
          KoiPositionedTextElement(
            x: 30,
            y: 300,
            text: receiverInfo,
            fontSize: 32,
          ),
        );
        break;
    }

    elements.add(const KoiLabelPrintElement(copies: 1));

    return KoiLabelDocument(name: '标签面单-$waybillNo', elements: elements);
  }
}
