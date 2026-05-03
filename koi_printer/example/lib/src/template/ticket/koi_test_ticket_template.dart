import 'dart:convert';
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

      const KoiTextElement(text: '图片打印测试 (Logo):'),
      KoiTicketImageElement(
        imageBytes: base64Decode(
            'iVBORw0KGgoAAAANSUhEUgAAAMgAAADIAQAAAACFI5MzAAAF0ElEQVR4nO1Xb2wUVRD/7e5de1ekd5Z/pdLeSa0iwaREgxAN3RCDICgkajQEpEY+AImkMQZLLHRLq5IYKEEwENTWoMbEf6fYHipyhxKwAQQxEgKWXi0CxpLuHdDucXs7Zvdut3vvtt+byHx4uzu/NzO/mTdv9y1HGEH4kQDcRnC7Bhh1NWiS7E80LBpQM/wEG6LWAAFHRCGShiHYkDgRRdHogFzXh6gZireRkfXBHXNg7dKHrjoHJKYPW50y9ejpjZs9UnUed4pjyHePOiBRANq8qANiiHjaAfEbw0hx1JB/JG9L5ZGQkGkD2/LoC6Cc3pdf0RvGuEfM9xbXu0ApXpWPfGKMlx1sthjPv/6Sh1CGVEl+DW7V6qPWNTzVlJims5ZhtghvTenTsjftrLfFRj5CSpUZhPyyrtJWCSyDW7Wleqq8P80ykIkkjigeUZZkFDCRn/W94COZ5FaG2xGAU+KAGM+Whzed7gZQGPUAvdFcRAvq49xkUDxpNg9lRPFleIAmsHHixh71NaWrxFybZEzIGq9cwthUpI1ISI4RbXtGF07OrI/8ZClbUZ/kAdL+y51sHCIVNZRsKzp/KqNxWTYQYpUYahvXfa4619sNIJAOFs8t62QyTcZqiBSQ8kdHNlPk5BMtjK+/mI0DszrGK0cD/8XaPBvot3LhhTBbAxi73td8oZJZH6ABSRG48+N32ExlioEj2not7GO8cQiAgvB2VTJrigSgoBfuql0Sg1zS2wD+xI75LAOP3gZA0cIqMEhUjxWDQLvYOP60CFQo16fOZ1kH0vsjpGLi991sDYJYfxaqr6l8G9MHBUh9dAkKhL5Fk3PjEITBNxCPXi8Ps/mIrtJZ4Ku9fevyKooAh0twl+9gWStwfwsXEs1rGButoBYX8RO87//N5KNSvJHobdq7LC8fFE8DSpDYuI2tm4xnQ7iFon2LWG6pkDBfaoGwIgwmzj9PE331ALUuO5/9avHmDKFZxlINBSt2BhlvYz5MhlACrnJtHuvBC93aJNoaXp3V8NkJabiLuPZn4K1YmMfaNRnBM3B/uoNFetu5u9rLkJj+GIuoIgrE8fDO2sIi9+0+gdozcO/O+5aMWc1FtTIkHg6yCBfkkhgP7wwzHZhd1UO/V7z3I+010yHbmk7/AGVIzDEVvAlwy/mZ4rvwTmURXuiRSmJPwG2mA+sdUiYJEHuQ0PdELjcvF6zGTnj9rI18x5w1x6IHwRtfFDvrKxFKrzrI0Rbr28JnJ8RKgdNBCnotEz579dxby/8gKX8lwHprpZtEBylaaHlD9tpG9ByppPrykMAQpVcqlnoY0Wq0lXQz6YQ0UoJogx3hMzw0YOxi1A8Ts1irHuAbKfdIQIbIgv727HPwhuABe+FtNlqd0Ep0xYEbKXcXnqJjTt5cp6YcgHkAyKmo4Hmq4aq1avaKEikzm4ePjzmnQbWet505c86JanWjEwMAXA4BcLZ/s7QwEjKqz+Q54tKHL888X9ktuI9P6F/SPf5Vte3P+3Ut6SVqhIxoAAFO5qJTIBtK3rBsh6S/FUlPO6Hfm3EmpkuP+wrqJy2rbuqctu6hk2MtxCvf4/IfFj0ti+UF/s1FfImFQJoHiIDKbzeaUrYQ2WTalNH4LcSvD4fE3hZpwANNQ53NGyA/4oGqz9l8RNyeg/h1rYQF2ASJiXMUgRaJC4GvYuOIgKrVAVqZjRukQwC3Gq6Un+H2b8kJ/dK/PIRO+QVkuMGoaAUafW8dQwVkLlpcQ0avugz4RX5TuwhwnAwUm5kTEaUaOygyMPByJJwOX4sQ9ehKbtT0m/b64MDZcyFEDpl/e1yWW3K2ePGVw28q5WphjNnBL3XVhytmUPXX7F+OBpfaAGh7jKOKIZTd2dUbrr7WXKj1l5ob3GXGm4dYw+dBrbTjKGOTGtx4YijyoNZvvRddZpz0/t+qiqEljf7MsUl1aEOfpbRr1vuAGzW1zhfeQXcbMYW37lj5/yD/Ac4HohDmQOYlAAAAAElFTkSuQmCC'),
        align: KoiTextAlign.center,
        width: 200,
      ),
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
