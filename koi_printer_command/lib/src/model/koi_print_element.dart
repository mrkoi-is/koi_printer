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
  /// Documented.
  /// Constant constructor.
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
 /// Documented.

  /// Field.
  final String text;

  /// 等比缩放大小 (宽高相同)。如果 [widthSize] 或 [heightSize] 非 null,
  /// 则使用独立宽高; 否则使用此字段。
  final KoiTextSize size;

  /// 独立宽度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? widthSize;

  /// 独立高度缩放 (1-8)。null 时使用 [size]。
  /// Field.
  final KoiTextSize? heightSize;
 /// Documented.

  /// Documented.
  /// Field.
  final KoiTextAlign align;
  /// Field.
  final bool bold;
  /// Field.
  final bool reverse;

  /// 是否下划线。优先使用 [underlineStyle]。
  final bool underline;

  /// 下划线样式 (细/粗)。优先级高于 [underline]。
  final KoiUnderlineStyle underlineStyle;

  /// 字体类型 (Font A/B)。
  /// Field.
  final KoiFontType font;
}

/// 文本列定义。
class KoiTextColumn {
  /// Constant constructor.
  const KoiTextColumn({
    required this.text,
    /// Documented.
    this.ratio = 1,
    /// Documented.
    this.align = KoiTextAlign.left,
    /// Documented.
    this.bold = false,
    /// Documented.
    this.containsChinese = true,
  /// Documented.
  });

  /// Field.
  final String text;
  /// Field.
  /// Field.
  final int ratio;
  /// Field.
  /// Field.
  final KoiTextAlign align;
  /// Field.
  final bool bold;
  /// Field.
  final bool containsChinese;
/// Documented.
}

/// 多列文本行元素。
class KoiTextRowElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiTextRowElement({required this.columns});

  /// Field.
  /// Field.
  final List<KoiTextColumn> columns;
/// Documented.
}
 /// Documented.

/// Method.
/// QR 码元素 (流式, 带对齐)。
/// KoiQrCodeElement.
class KoiQrCodeElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiQrCodeElement({
    required this.data,
    this.size = KoiQrSize.size6,
    /// Documented.
    this.strategy = KoiQrRenderStrategy.normal,
    this.correction = KoiQrCorrection.medium,
    this.align = KoiTextAlign.center,
  });

  /// Field.
  final String data;
  /// Field.
  final KoiQrSize size;
  /// Field.
  /// Field.
  final KoiQrRenderStrategy strategy;
  /// Documented.
  /// Field.
  /// Field.
  final KoiQrCorrection correction;
  /// Documented.
  /// Field.
  /// Field.
  final KoiTextAlign align;
/// Documented.
}
 /// Documented.

/// 条码元素 (流式, 带对齐)。
class KoiBarcodeElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiBarcodeElement({
    /// Documented.
    required this.data,
    this.type = KoiBarcodeType.code128,
    this.height = 60,
    this.width = 2,
    this.align = KoiTextAlign.center,
    this.textPosition = KoiBarcodeTextPosition.below,
    this.font = KoiFontType.fontA,
  /// Documented.
  });
 /// Documented.

  /// Documented.
  /// Field.
  /// Field.
  final String data;
  /// Field.
  final KoiBarcodeType type;
  /// Field.
  final int height;
  /// Documented.
  /// Field.
  final int width;
  /// Documented.
  /// Field.
  final KoiTextAlign align;
  /// Field.
  final KoiBarcodeTextPosition textPosition;
  /// Field.
  /// Field.
  final KoiFontType font;
}
 /// Documented.

/// 图片元素 (小票, 流式, 带对齐)。
class KoiTicketImageElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiTicketImageElement({
    /// Documented.
    required this.imageBytes,
    this.width,
    /// Documented.
    this.align = KoiTextAlign.center,
    this.renderMode = KoiImageRenderMode.raster,
  });

  /// Field.
  /// Field.
  final Uint8List imageBytes;
  /// Field.
  /// Field.
  final int? width;
  /// Documented.
  /// Field.
  final KoiTextAlign align;
  /// Field.
  final KoiImageRenderMode renderMode;
}
 /// Documented.

/// 分隔线元素。
/// KoiDividerElement.
class KoiDividerElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiDividerElement({this.char = '-'});

  /// Field.
  final String char;
/// Documented.
}

/// 空行元素。
class KoiSpacerElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiSpacerElement({this.lines = 1});

  /// Field.
  final int lines;
/// Documented.
}

/// 切纸元素。
class KoiCutElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiCutElement({this.mode = KoiCutMode.full});

  /// Field.
  /// Field.
  final KoiCutMode mode;
}

/// 蜂鸣器元素。
class KoiBeepElement extends KoiTicketElement {
  /// Documented.
  /// Constant constructor.
  /// Constant constructor.
  const KoiBeepElement({this.count = 3, this.durationMs = 100});

  /// Field.
  final int count;
  /// Field.
  final int durationMs;
}

/// 钱箱元素。
class KoiCashDrawerElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiCashDrawerElement({this.pin = KoiCashDrawerPin.pin2});

  /// Field.
  final KoiCashDrawerPin pin;
/// Documented.
}

/// 左边距元素 — 设置打印区域左边距 (GS L)。
/// Left margin element — sets the left margin of the print area.
class KoiLeftMarginElement extends KoiTicketElement {
  /// Constant constructor.
  const KoiLeftMarginElement({this.dots = 0});

  /// 左边距 (点数)。0 = 重置为无边距。
  final int dots;
}

/// Documented.
/// 原始字节元素 — 直接注入 ESC/POS 字节流。
/// Documented.
/// Raw bytes element — injects raw bytes directly into the ESC/POS stream.
/// KoiRawBytesElement.
class KoiRawBytesElement extends KoiTicketElement {
  /// Documented.
  /// Constant constructor.
  /// Constant constructor.
  const KoiRawBytesElement(this.bytes);
 /// Documented.

  /// Documented.
  /// 原始字节序列, 原封不动注入打印数据流。
  /// Field.
  final List<int> bytes;
/// Documented.
}

/// 小票模板循环元素。
class KoiTicketForEachElement extends KoiTicketElement {
  /// Constant constructor.
  /// Constant constructor.
  const KoiTicketForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// Field.
  final String listKey;
  /// Field.
  final List<KoiTicketElement> templates;
}

// ═══════════════════════════════════════════════════════════
/// Method.
// 标签元素 (TSPL/CPCL 坐标定位布局) — Label Elements
/// Documented.
// ═══════════════════════════════════════════════════════════
 /// Documented.

/// Method.
/// 标签打印元素基类 (sealed)。
/// Method.
/// Base class for label print elements using positioned (canvas) layout.
/// Documented.
sealed class KoiLabelElement {
  /// Constant constructor.
  const KoiLabelElement();
/// Documented.
}
 /// Documented.

/// 标签初始化元素 — 设置标签尺寸和间距。
class KoiLabelSetupElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelSetupElement({
    /// Documented.
    required this.widthMm,
    required this.heightMm,
    this.gapMm = 2,
    this.dpi = 203,
    this.density,
    this.speed,
    this.referenceX = 0,
    this.referenceY = 0,
    /// Documented.
    this.codepage,
  /// Documented.
  });
 /// Documented.

  /// Documented.
  /// Field.
  /// Field.
  final int widthMm;
  /// Field.
  final int heightMm;
  /// Field.
  final int gapMm;
  /// Documented.
  /// Field.
  final int dpi;
  /// Field.
  final int? density;
  /// Field.
  final double? speed;
  /// Field.
  /// Field.
  final int referenceX;
  /// Documented.
  /// Field.
  /// Field.
  final int referenceY;
  /// Documented.
  /// Field.
  final String? codepage;
}

/// 坐标定位文本元素。
/// KoiPositionedTextElement.
class KoiPositionedTextElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiPositionedTextElement({
    required this.x,
    required this.y,
    required this.text,
    this.fontSize = 24,
    this.font = 'TSS24.BF2',
    /// Documented.
    this.rotation = 0,
    /// Documented.
    this.xScale = 1,
    /// Documented.
    this.yScale = 1,
    /// Documented.
    this.bold = false,
  /// Documented.
  });

  /// Field.
  final int x;
  /// Field.
  /// Field.
  final int y;
  /// Field.
  final String text;
  /// Field.
  final int fontSize;
  /// Field.
  final String font;
  /// Documented.
  /// Field.
  /// Field.
  final int rotation;
  /// Documented.
  /// Field.
  /// Field.
  final int xScale;
  /// Field.
  final int yScale;
  /// Field.
  final bool bold;
/// Documented.
}

/// 坐标定位条码元素。
class KoiPositionedBarcodeElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiPositionedBarcodeElement({
    required this.x,
    /// Documented.
    required this.y,
    /// Documented.
    required this.data,
    /// Documented.
    this.height = 60,
    /// Documented.
    this.type = '128',
  });

  /// Field.
  final int x;
  /// Documented.
  /// Field.
  final int y;
  /// Field.
  final String data;
  /// Field.
  final int height;
  /// Field.
  /// Field.
  final String type;
/// Documented.
}
 /// Documented.

/// Documented.
/// 坐标定位 QR 码元素。
class KoiPositionedQrCodeElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiPositionedQrCodeElement({
    required this.x,
    /// Documented.
    required this.y,
    required this.data,
    /// Documented.
    this.cellSize = 6,
  /// Documented.
  });

  /// Field.
  final int x;
  /// Field.
  /// Field.
  final int y;
  /// Field.
  final String data;
  /// Field.
  final int cellSize;
/// Documented.
}
 /// Documented.

/// 标签矩形框元素。
class KoiLabelBoxElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelBoxElement({
    required this.x,
    /// Documented.
    required this.y,
    required this.width,
    required this.height,
    this.thickness = 2,
  });

  /// Field.
  final int x;
  /// Field.
  final int y;
  /// Field.
  final int width;
  /// Field.
  final int height;
  /// Field.
  final int thickness;
}

/// 标签反白区域元素。
class KoiLabelReverseElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelReverseElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Field.
  final int x;
  /// Field.
  final int y;
  /// Field.
  final int width;
  /// Field.
  final int height;
}

/// 标签直线元素 (TSPL BAR / CPCL LINE)。
class KoiLabelLineElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelLineElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Field.
  final int x;
  /// Field.
  final int y;
  /// Field.
  final int width;
  /// Field.
  final int height;
}

/// 标签图片元素 (带 x, y 坐标)。
class KoiLabelImageElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelImageElement({
    required this.x,
    required this.y,
    required this.imageBytes,
    this.width,
  });

  /// Field.
  final int x;
  /// Field.
  final int y;
  /// Field.
  final Uint8List imageBytes;
  /// Field.
  final int? width;
}

/// 标签打印元素 — 触发打印。
class KoiLabelPrintElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelPrintElement({this.copies = 1, this.sets = 1});

  /// Field.
  final int copies;
  /// Field.
  final int sets;
}

/// 标签模板循环元素。
class KoiLabelForEachElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiLabelForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// Field.
  final String listKey;
  /// Field.
  final List<KoiLabelElement> templates;
}

/// 原始指令元素 — 直接注入 TSPL/CPCL 文本指令。
/// Raw command element — injects raw text commands (auto GBK + \r\n).
class KoiRawCommandElement extends KoiLabelElement {
  /// Constant constructor.
  const KoiRawCommandElement(this.command);

  /// 明文指令行, Renderer 自动 GBK 编码并追加 \r\n。
  final String command;
}
