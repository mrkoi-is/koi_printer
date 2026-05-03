import 'package:koi_printer/koi_printer.dart';

/// 测试页模板。
class KoiTestTicketTemplate implements KoiTicketTemplate<void> {
  const KoiTestTicketTemplate();

  @override
  List<KoiTicketDocument> build(void data, KoiPrintConfig config) {
    final docs = <KoiTicketDocument>[];

    final elements = <KoiTicketElement>[
      if (config.headerEmptyLines > 0)
        KoiSpacerElement(lines: config.headerEmptyLines),

      const KoiTextElement(
        text: '十二光年 打印测试页',
        size: KoiTextSize.size2,
        align: KoiTextAlign.center,
        bold: true,
      ),
      const KoiSpacerElement(lines: 1),

      const KoiTextRowElement(
        columns: [
          KoiTextColumn(text: '左对齐', align: KoiTextAlign.left, ratio: 1),
          KoiTextColumn(text: '居中对齐', align: KoiTextAlign.center, ratio: 1),
          KoiTextColumn(text: '右对齐', align: KoiTextAlign.right, ratio: 1),
        ],
      ),
      const KoiDividerElement(char: '='),

      const KoiTextElement(text: '条码测试 (CODE128)'),
      const KoiBarcodeElement(data: '12345678X', height: 60),
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '二维码测试'),
      const KoiQrCodeElement(
        data: 'https://koi.example.com/',
        size: KoiQrSize.size6,
      ),
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '字体属性测试:'),
      const KoiTextElement(text: '>> 正常粗细 Normal'),
      const KoiTextElement(text: '>> 加粗文字 Bold', bold: true),
      const KoiTextElement(text: '>> 反白显示 Reverse', reverse: true),
      const KoiTextElement(text: '>> 带下划线 Underline', underline: true),
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '异形缩放测试:'),
      const KoiTextElement(
        text: '>> 宽度拉伸 (Width: x2)',
        widthSize: KoiTextSize.size2,
        heightSize: KoiTextSize.size1,
      ),
      const KoiTextElement(
        text: '>> 高度拉伸 (Height: x2)',
        widthSize: KoiTextSize.size1,
        heightSize: KoiTextSize.size2,
      ),
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '控制指令测试:'),
      const KoiTextElement(text: '>> 蜂鸣器 (Beep x2)'),
      const KoiBeepElement(count: 2, durationMs: 100),
      const KoiTextElement(text: '>> 弹钱箱 (Cash Drawer)'),
      const KoiCashDrawerElement(pin: KoiCashDrawerPin.pin2),
      const KoiTextElement(text: '>> 注入原始空指令 (Raw Bytes)'),
      const KoiRawBytesElement([0x00]), // NUL
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '左边距测试:'),
      const KoiLeftMarginElement(dots: 48), // 缩进一段距离
      const KoiTextElement(text: '>> 缩进了 48 Dots 的文本'),
      const KoiLeftMarginElement(dots: 0), // 恢复
      const KoiSpacerElement(lines: 1),

      const KoiTextElement(text: '切纸测试 (全切)'),
      const KoiCutElement(mode: KoiCutMode.full),
    ];

    docs.add(
      KoiTicketDocument(
        name: '打印测试页',
        paperSize: config.paperSize,
        elements: elements,
      ),
    );

    return docs;
  }
}
