import 'dart:typed_data';

import 'package:koi_printer_command/src/model/koi_types.dart';

// ═══════════════════════════════════════════════════════════
// 小票元素 (ESC/POS 流式布局) — Ticket Elements
// ═══════════════════════════════════════════════════════════

/// 小票打印元素基类 (sealed)。
/// Base class for ticket (receipt) print elements using flow layout.
sealed class KoiTicketElement {
  const KoiTicketElement();
}

/// 文本元素。
/// Single-line text with styling.
class KoiTextElement extends KoiTicketElement {
  const KoiTextElement({
    required this.text,
    this.size = KoiTextSize.size1,
    this.widthSize,
    this.heightSize,
    this.align = KoiTextAlign.left,
    this.bold = false,
    this.reverse = false,
    this.underline = false,
    this.underlineStyle = KoiUnderlineStyle.none,
    this.font = KoiFontType.fontA,
  });

  final String text;

  /// 等比缩放大小 (宽高相同)。如果 [widthSize] 或 [heightSize] 非 null,
  /// 则使用独立宽高; 否则使用此字段。
  final KoiTextSize size;

  /// 独立宽度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? widthSize;

  /// 独立高度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? heightSize;

  final KoiTextAlign align;
  final bool bold;
  final bool reverse;

  /// 是否下划线。优先使用 [underlineStyle]。
  final bool underline;

  /// 下划线样式 (细/粗)。优先级高于 [underline]。
  final KoiUnderlineStyle underlineStyle;

  /// 字体类型 (Font A/B)。
  final KoiFontType font;
}

/// 文本列定义。
class KoiTextColumn {
  const KoiTextColumn({
    required this.text,
    this.ratio = 1,
    this.align = KoiTextAlign.left,
    this.bold = false,
    this.containsChinese = true,
  });

  final String text;
  final int ratio;
  final KoiTextAlign align;
  final bool bold;
  final bool containsChinese;
}

/// 多列文本行元素。
class KoiTextRowElement extends KoiTicketElement {
  const KoiTextRowElement({required this.columns});

  final List<KoiTextColumn> columns;
}

/// QR 码元素 (流式, 带对齐)。
class KoiQrCodeElement extends KoiTicketElement {
  const KoiQrCodeElement({
    required this.data,
    this.size = KoiQrSize.size6,
    this.strategy = KoiQrRenderStrategy.normal,
    this.correction = KoiQrCorrection.medium,
    this.align = KoiTextAlign.center,
  });

  final String data;
  final KoiQrSize size;
  final KoiQrRenderStrategy strategy;
  final KoiQrCorrection correction;
  final KoiTextAlign align;
}

/// 条码元素 (流式, 带对齐)。
class KoiBarcodeElement extends KoiTicketElement {
  const KoiBarcodeElement({
    required this.data,
    this.type = KoiBarcodeType.code128,
    this.height = 60,
    this.width = 2,
    this.align = KoiTextAlign.center,
    this.textPosition = KoiBarcodeTextPosition.below,
    this.font = KoiFontType.fontA,
  });

  final String data;
  final KoiBarcodeType type;
  final int height;
  final int width;
  final KoiTextAlign align;
  final KoiBarcodeTextPosition textPosition;
  final KoiFontType font;
}

/// 图片元素 (小票, 流式, 带对齐)。
class KoiTicketImageElement extends KoiTicketElement {
  const KoiTicketImageElement({
    required this.imageBytes,
    this.width,
    this.align = KoiTextAlign.center,
    this.renderMode = KoiImageRenderMode.raster,
  });

  final Uint8List imageBytes;
  final int? width;
  final KoiTextAlign align;
  final KoiImageRenderMode renderMode;
}

/// 分隔线元素。
class KoiDividerElement extends KoiTicketElement {
  const KoiDividerElement({this.char = '-'});

  final String char;
}

/// 空行元素。
class KoiSpacerElement extends KoiTicketElement {
  const KoiSpacerElement({this.lines = 1});

  final int lines;
}

/// 切纸元素。
class KoiCutElement extends KoiTicketElement {
  const KoiCutElement({this.mode = KoiCutMode.full});

  final KoiCutMode mode;
}

/// 蜂鸣器元素。
class KoiBeepElement extends KoiTicketElement {
  const KoiBeepElement({this.count = 3, this.durationMs = 100});

  final int count;
  final int durationMs;
}

/// 钱箱元素。
class KoiCashDrawerElement extends KoiTicketElement {
  const KoiCashDrawerElement({this.pin = KoiCashDrawerPin.pin2});

  final KoiCashDrawerPin pin;
}

/// 左边距元素 — 设置打印区域左边距 (GS L)。
/// Left margin element — sets the left margin of the print area.
class KoiLeftMarginElement extends KoiTicketElement {
  const KoiLeftMarginElement({this.dots = 0});

  /// 左边距 (点数)。0 = 重置为无边距。
  final int dots;
}

/// 原始字节元素 — 直接注入 ESC/POS 字节流。
/// Raw bytes element — injects raw bytes directly into the ESC/POS stream.
class KoiRawBytesElement extends KoiTicketElement {
  const KoiRawBytesElement(this.bytes);

  /// 原始字节序列, 原封不动注入打印数据流。
  final List<int> bytes;
}

/// 小票模板循环元素。
class KoiTicketForEachElement extends KoiTicketElement {
  const KoiTicketForEachElement({
    required this.listKey,
    required this.templates,
  });

  final String listKey;
  final List<KoiTicketElement> templates;
}

// ═══════════════════════════════════════════════════════════
// 标签元素 (TSPL/CPCL 坐标定位布局) — Label Elements
// ═══════════════════════════════════════════════════════════

/// 标签打印元素基类 (sealed)。
/// Base class for label print elements using positioned (canvas) layout.
sealed class KoiLabelElement {
  const KoiLabelElement();
}

/// 标签初始化元素 — 设置标签尺寸和间距。
class KoiLabelSetupElement extends KoiLabelElement {
  const KoiLabelSetupElement({
    required this.widthMm,
    required this.heightMm,
    this.gapMm = 2,
    this.dpi = 203,
    this.density,
    this.speed,
    this.referenceX = 0,
    this.referenceY = 0,
    this.codepage,
  });

  final int widthMm;
  final int heightMm;
  final int gapMm;
  final int dpi;
  final int? density;
  final double? speed;
  final int referenceX;
  final int referenceY;
  final String? codepage;
}

/// 坐标定位文本元素。
class KoiPositionedTextElement extends KoiLabelElement {
  const KoiPositionedTextElement({
    required this.x,
    required this.y,
    required this.text,
    this.fontSize = 24,
    this.font = 'TSS24.BF2',
    this.rotation = 0,
    this.xScale = 1,
    this.yScale = 1,
    this.bold = false,
  });

  final int x;
  final int y;
  final String text;
  final int fontSize;
  final String font;
  final int rotation;
  final int xScale;
  final int yScale;
  final bool bold;
}

/// 坐标定位条码元素。
class KoiPositionedBarcodeElement extends KoiLabelElement {
  const KoiPositionedBarcodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.height = 60,
    this.type = '128',
  });

  final int x;
  final int y;
  final String data;
  final int height;
  final String type;
}

/// 坐标定位 QR 码元素。
class KoiPositionedQrCodeElement extends KoiLabelElement {
  const KoiPositionedQrCodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.cellSize = 6,
  });

  final int x;
  final int y;
  final String data;
  final int cellSize;
}

/// 标签矩形框元素。
class KoiLabelBoxElement extends KoiLabelElement {
  const KoiLabelBoxElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thickness = 2,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final int thickness;
}

/// 标签反白区域元素。
class KoiLabelReverseElement extends KoiLabelElement {
  const KoiLabelReverseElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

/// 标签直线元素 (TSPL BAR / CPCL LINE)。
class KoiLabelLineElement extends KoiLabelElement {
  const KoiLabelLineElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;
}

/// 标签图片元素 (带 x, y 坐标)。
class KoiLabelImageElement extends KoiLabelElement {
  const KoiLabelImageElement({
    required this.x,
    required this.y,
    required this.imageBytes,
    this.width,
  });

  final int x;
  final int y;
  final Uint8List imageBytes;
  final int? width;
}

/// 标签打印元素 — 触发打印。
class KoiLabelPrintElement extends KoiLabelElement {
  const KoiLabelPrintElement({this.copies = 1, this.sets = 1});

  final int copies;
  final int sets;
}

/// 标签模板循环元素。
class KoiLabelForEachElement extends KoiLabelElement {
  const KoiLabelForEachElement({
    required this.listKey,
    required this.templates,
  });

  final String listKey;
  final List<KoiLabelElement> templates;
}

/// 原始指令元素 — 直接注入 TSPL/CPCL 文本指令。
/// Raw command element — injects raw text commands (auto GBK + \r\n).
class KoiRawCommandElement extends KoiLabelElement {
  const KoiRawCommandElement(this.command);

  /// 明文指令行, Renderer 自动 GBK 编码并追加 \r\n。
  final String command;
}
