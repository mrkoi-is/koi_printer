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
  /// Documentation for this public member.
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

  /// Documentation for this public member.
  final String text;

  /// 等比缩放大小 (宽高相同)。如果 [widthSize] 或 [heightSize] 非 null,
  /// 则使用独立宽高; 否则使用此字段。
  final KoiTextSize size;

  /// 独立宽度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? widthSize;

  /// 独立高度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? heightSize;

  /// Documentation for this public member.
  final KoiTextAlign align;

  /// Documentation for this public member.
  final bool bold;

  /// Documentation for this public member.
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
  /// Documentation for this public member.
  const KoiTextColumn({
    required this.text,
    this.ratio = 1,
    this.align = KoiTextAlign.left,
    this.bold = false,
    this.containsChinese = true,
  });

  /// Documentation for this public member.
  final String text;

  /// Documentation for this public member.
  final int ratio;

  /// Documentation for this public member.
  final KoiTextAlign align;

  /// Documentation for this public member.
  final bool bold;

  /// Documentation for this public member.
  final bool containsChinese;
}

/// 多列文本行元素。
class KoiTextRowElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiTextRowElement({required this.columns});

  /// Documentation for this public member.
  final List<KoiTextColumn> columns;
}

/// QR 码元素 (流式, 带对齐)。
/// KoiQrCodeElement.
class KoiQrCodeElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiQrCodeElement({
    required this.data,
    this.size = KoiQrSize.size6,
    this.strategy = KoiQrRenderStrategy.normal,
    this.correction = KoiQrCorrection.medium,
    this.align = KoiTextAlign.center,
  });

  /// Documentation for this public member.
  final String data;

  /// Documentation for this public member.
  final KoiQrSize size;

  /// Documentation for this public member.
  final KoiQrRenderStrategy strategy;

  /// Documentation for this public member.
  final KoiQrCorrection correction;

  /// Documentation for this public member.
  final KoiTextAlign align;
}

/// 条码元素 (流式, 带对齐)。
class KoiBarcodeElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiBarcodeElement({
    required this.data,
    this.type = KoiBarcodeType.code128,
    this.height = 60,
    this.width = 2,
    this.align = KoiTextAlign.center,
    this.textPosition = KoiBarcodeTextPosition.below,
    this.font = KoiFontType.fontA,
  });

  /// Documentation for this public member.
  final String data;

  /// Documentation for this public member.
  final KoiBarcodeType type;

  /// Documentation for this public member.
  final int height;

  /// Documentation for this public member.
  final int width;

  /// Documentation for this public member.
  final KoiTextAlign align;

  /// Documentation for this public member.
  final KoiBarcodeTextPosition textPosition;

  /// Documentation for this public member.
  final KoiFontType font;
}

/// 图片元素 (小票, 流式, 带对齐)。
class KoiTicketImageElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiTicketImageElement({
    required this.imageBytes,
    this.width,
    this.align = KoiTextAlign.center,
    this.renderMode = KoiImageRenderMode.raster,
  });

  /// Documentation for this public member.
  final Uint8List imageBytes;

  /// Documentation for this public member.
  final int? width;

  /// Documentation for this public member.
  final KoiTextAlign align;

  /// Documentation for this public member.
  final KoiImageRenderMode renderMode;
}

/// 分隔线元素。
/// KoiDividerElement.
class KoiDividerElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiDividerElement({this.char = '-'});

  /// Documentation for this public member.
  final String char;
}

/// 空行元素。
class KoiSpacerElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiSpacerElement({this.lines = 1});

  /// Documentation for this public member.
  final int lines;
}

/// 切纸元素。
class KoiCutElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiCutElement({this.mode = KoiCutMode.full, this.feedLines = 6});

  /// Documentation for this public member.
  final KoiCutMode mode;

  /// 切纸前自动走纸行数。
  /// 打印头与切刀之间存在物理距离, 需要先走纸若干行, 确保内容完全越过切刀位置后再切。
  /// 设为 0 表示不自动走纸 (调用方需自行控制)。
  final int feedLines;
}

/// 蜂鸣器元素。
class KoiBeepElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiBeepElement({this.count = 3, this.durationMs = 100});

  /// Documentation for this public member.
  final int count;

  /// Documentation for this public member.
  final int durationMs;
}

/// 钱箱元素。
class KoiCashDrawerElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiCashDrawerElement({this.pin = KoiCashDrawerPin.pin2});

  /// Documentation for this public member.
  final KoiCashDrawerPin pin;
}

/// 左边距元素 — 设置打印区域左边距 (GS L)。
/// Left margin element — sets the left margin of the print area.
class KoiLeftMarginElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiLeftMarginElement({this.dots = 0});

  /// 左边距 (点数)。0 = 重置为无边距。
  final int dots;
}

/// 原始字节元素 — 直接注入 ESC/POS 字节流。
/// Raw bytes element — injects raw bytes directly into the ESC/POS stream.
/// KoiRawBytesElement.
class KoiRawBytesElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiRawBytesElement(this.bytes);

  /// 原始字节序列, 原封不动注入打印数据流。
  final List<int> bytes;
}

/// 小票模板循环元素。
class KoiTicketForEachElement extends KoiTicketElement {
  /// Documentation for this public member.
  const KoiTicketForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// Documentation for this public member.
  final String listKey;

  /// Documentation for this public member.
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
  /// Documentation for this public member.
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

  /// Documentation for this public member.
  final int widthMm;

  /// Documentation for this public member.
  final int heightMm;

  /// Documentation for this public member.
  final int gapMm;

  /// Documentation for this public member.
  final int dpi;

  /// Documentation for this public member.
  final int? density;

  /// Documentation for this public member.
  final double? speed;

  /// Documentation for this public member.
  final int referenceX;

  /// Documentation for this public member.
  final int referenceY;

  /// Documentation for this public member.
  final String? codepage;
}

/// 坐标定位文本元素。
/// KoiPositionedTextElement.
class KoiPositionedTextElement extends KoiLabelElement {
  /// Documentation for this public member.
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

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final String text;

  /// Documentation for this public member.
  final int fontSize;

  /// Documentation for this public member.
  final String font;

  /// Documentation for this public member.
  final int rotation;

  /// Documentation for this public member.
  final int xScale;

  /// Documentation for this public member.
  final int yScale;

  /// Documentation for this public member.
  final bool bold;
}

/// 坐标定位条码元素。
class KoiPositionedBarcodeElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiPositionedBarcodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.height = 60,
    this.type = '128',
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final String data;

  /// Documentation for this public member.
  final int height;

  /// Documentation for this public member.
  final String type;
}

/// 坐标定位 QR 码元素。
class KoiPositionedQrCodeElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiPositionedQrCodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.cellSize = 6,
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final String data;

  /// Documentation for this public member.
  final int cellSize;
}

/// 标签矩形框元素。
class KoiLabelBoxElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelBoxElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thickness = 2,
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final int width;

  /// Documentation for this public member.
  final int height;

  /// Documentation for this public member.
  final int thickness;
}

/// 标签反白区域元素。
class KoiLabelReverseElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelReverseElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final int width;

  /// Documentation for this public member.
  final int height;
}

/// 标签直线元素 (TSPL BAR / CPCL LINE)。
class KoiLabelLineElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelLineElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final int width;

  /// Documentation for this public member.
  final int height;
}

/// 标签图片元素 (带 x, y 坐标)。
class KoiLabelImageElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelImageElement({
    required this.x,
    required this.y,
    required this.imageBytes,
    this.width,
  });

  /// Documentation for this public member.
  final int x;

  /// Documentation for this public member.
  final int y;

  /// Documentation for this public member.
  final Uint8List imageBytes;

  /// Documentation for this public member.
  final int? width;
}

/// 标签打印元素 — 触发打印。
class KoiLabelPrintElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelPrintElement({this.copies = 1, this.sets = 1});

  /// Documentation for this public member.
  final int copies;

  /// Documentation for this public member.
  final int sets;
}

/// 标签模板循环元素。
class KoiLabelForEachElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiLabelForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// Documentation for this public member.
  final String listKey;

  /// Documentation for this public member.
  final List<KoiLabelElement> templates;
}

/// 原始指令元素 — 直接注入 TSPL/CPCL 文本指令。
/// Raw command element — injects raw text commands (auto GBK + \r\n).
class KoiRawCommandElement extends KoiLabelElement {
  /// Documentation for this public member.
  const KoiRawCommandElement(this.command);

  /// 明文指令行, Renderer 自动 GBK 编码并追加 \r\n。
  final String command;
}
