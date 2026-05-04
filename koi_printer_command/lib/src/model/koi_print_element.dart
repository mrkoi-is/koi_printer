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
  /// 创建一个文本打印元素。
  /// [text] 必须提供，其余属性有默认样式。
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

  /// 要打印的具体文本内容。
  final String text;

  /// 等比缩放大小 (宽高相同)。如果 [widthSize] 或 [heightSize] 非 null,
  /// 则使用独立宽高; 否则使用此字段。
  final KoiTextSize size;

  /// 独立宽度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? widthSize;

  /// 独立高度缩放 (1-8)。null 时使用 [size]。
  final KoiTextSize? heightSize;

  /// 文本的对齐方式（左、中、右）。
  final KoiTextAlign align;

  /// 是否加粗。
  final bool bold;

  /// 是否反白打印（黑底白字）。
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
  /// 创建文本列，用于多列排版。
  const KoiTextColumn({
    required this.text,
    this.ratio = 1,
    this.align = KoiTextAlign.left,
    this.bold = false,
    this.containsChinese = true,
  });

  /// 要打印的具体文本内容。
  final String text;

  /// 列所占宽度的比例（权重）。
  final int ratio;

  /// 文本的对齐方式（左、中、右）。
  final KoiTextAlign align;

  /// 是否加粗。
  final bool bold;

  /// 标识此列是否包含中文字符，用于精确计算对齐空格。
  final bool containsChinese;
}

/// 多列文本行元素。
class KoiTextRowElement extends KoiTicketElement {
  /// 创建多列文本行元素。
  const KoiTextRowElement({required this.columns});

  /// 包含的具体列定义列表。
  final List<KoiTextColumn> columns;
}

/// QR 码元素 (流式, 带对齐)。
/// KoiQrCodeElement.
class KoiQrCodeElement extends KoiTicketElement {
  /// 创建一个二维码打印元素。
  const KoiQrCodeElement({
    required this.data,
    this.size = KoiQrSize.size6,
    this.strategy = KoiQrRenderStrategy.normal,
    this.correction = KoiQrCorrection.medium,
    this.align = KoiTextAlign.center,
  });

  /// 包含的字符串数据。
  final String data;

  /// 二维码的放大倍数（尺寸）。
  final KoiQrSize size;

  /// 指定二维码的渲染策略，处理硬件兼容性。
  final KoiQrRenderStrategy strategy;

  /// 二维码的纠错级别。
  final KoiQrCorrection correction;

  /// 文本的对齐方式（左、中、右）。
  final KoiTextAlign align;
}

/// 条码元素 (流式, 带对齐)。
class KoiBarcodeElement extends KoiTicketElement {
  /// 创建一条条形码元素。
  const KoiBarcodeElement({
    required this.data,
    this.type = KoiBarcodeType.code128,
    this.height = 60,
    this.width = 2,
    this.align = KoiTextAlign.center,
    this.textPosition = KoiBarcodeTextPosition.below,
    this.font = KoiFontType.fontA,
  });

  /// 包含的字符串数据。
  final String data;

  /// 条码类型（如 CODE128, UPC 等）。
  final KoiBarcodeType type;

  /// 高度 (点数)。
  final int height;

  /// 宽度 (点数)。
  final int width;

  /// 文本的对齐方式（左、中、右）。
  final KoiTextAlign align;

  /// 文本显示位置（条码下方、上方或隐藏）。
  final KoiBarcodeTextPosition textPosition;

  /// 条码附带文字的字体。
  final KoiFontType font;
}

/// 图片元素 (小票, 流式, 带对齐)。
class KoiTicketImageElement extends KoiTicketElement {
  /// 创建一张用于小票的图像打印元素。
  const KoiTicketImageElement({
    required this.imageBytes,
    this.width,
    this.align = KoiTextAlign.center,
    this.renderMode = KoiImageRenderMode.raster,
  });

  /// 图像的字节数据 (通常为 PNG/JPEG 等标准格式的二进制)。
  final Uint8List imageBytes;

  /// 打印到纸上的具体宽度。为空则按纸宽缩放。
  final int? width;

  /// 文本的对齐方式（左、中、右）。
  final KoiTextAlign align;

  /// 打印渲染模式（如光栅模式等）。
  final KoiImageRenderMode renderMode;
}

/// 分隔线元素。
/// KoiDividerElement.
class KoiDividerElement extends KoiTicketElement {
  /// 创建一条分割线。
  const KoiDividerElement({this.char = '-'});

  /// 用于填充分割线的单个字符（默认是 '-'）。
  final String char;
}

/// 空行元素。
class KoiSpacerElement extends KoiTicketElement {
  /// 创建一个用来输出空白行的元素。
  const KoiSpacerElement({this.lines = 1});

  /// 具体的空白行数。
  final int lines;
}

/// 切纸元素。
class KoiCutElement extends KoiTicketElement {
  /// 创建切纸指令元素。
  const KoiCutElement({this.mode = KoiCutMode.full, this.feedLines = 6});

  /// 切纸模式 (全切或半切)。
  final KoiCutMode mode;

  /// 切纸前自动走纸行数。
  /// 打印头与切刀之间存在物理距离, 需要先走纸若干行, 确保内容完全越过切刀位置后再切。
  /// 设为 0 表示不自动走纸 (调用方需自行控制)。
  final int feedLines;
}

/// 蜂鸣器元素。
class KoiBeepElement extends KoiTicketElement {
  /// 创建蜂鸣器提示音元素。
  const KoiBeepElement({this.count = 3, this.durationMs = 100});

  /// 响铃次数。
  final int count;

  /// 每次响铃的持续时间（毫秒）。
  final int durationMs;
}

/// 钱箱元素。
class KoiCashDrawerElement extends KoiTicketElement {
  /// 创建开钱箱指令元素。
  const KoiCashDrawerElement({this.pin = KoiCashDrawerPin.pin2});

  /// 触发开箱的针脚定义。
  final KoiCashDrawerPin pin;
}

/// 左边距元素 — 设置打印区域左边距 (GS L)。
/// Left margin element — sets the left margin of the print area.
class KoiLeftMarginElement extends KoiTicketElement {
  /// 创建一个左边距指令。
  const KoiLeftMarginElement({this.dots = 0});

  /// 左边距 (点数)。0 = 重置为无边距。
  final int dots;
}

/// 原始字节元素 — 直接注入 ESC/POS 字节流。
/// Raw bytes element — injects raw bytes directly into the ESC/POS stream.
/// KoiRawBytesElement.
class KoiRawBytesElement extends KoiTicketElement {
  /// 创建原始字节元素。
  const KoiRawBytesElement(this.bytes);

  /// 原始字节序列, 原封不动注入打印数据流。
  final List<int> bytes;
}

/// 小票模板循环元素。
class KoiTicketForEachElement extends KoiTicketElement {
  /// 创建小票模板循环元素。
  const KoiTicketForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// 绑定到模板数据的列表字段名（如 "items"）。
  final String listKey;

  /// 循环体内需要渲染的子元素模板。
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
  /// 创建标签初始化元素。
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

  /// 标签纸宽度（毫米）。
  final int widthMm;

  /// 标签纸高度（毫米）。
  final int heightMm;

  /// 标签纸间距（毫米）。
  final int gapMm;

  /// 打印机分辨率 (默认203)。
  final int dpi;

  /// 打印浓度 (0-15)。
  final int? density;

  /// 打印速度 (英寸/秒)。
  final double? speed;

  /// X 轴起始坐标偏移量。
  final int referenceX;

  /// Y 轴起始坐标偏移量。
  final int referenceY;

  /// 字符集代码页。
  final String? codepage;
}

/// 坐标定位文本元素。
/// KoiPositionedTextElement.
class KoiPositionedTextElement extends KoiLabelElement {
  /// 创建坐标定位文本元素。
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

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 要打印的具体文本内容。
  final String text;

  /// 字体大小（TSPL通常为字高，CPCL根据字体变化）。
  final int fontSize;

  /// 字体族名称 (例如 "TSS24.BF2")。
  final String font;

  /// 文本旋转角度（0, 90, 180, 270）。
  final int rotation;

  /// X轴缩放比例 (1-10)。
  final int xScale;

  /// Y轴缩放比例 (1-10)。
  final int yScale;

  /// 是否加粗。
  final bool bold;
}

/// 坐标定位条码元素。
class KoiPositionedBarcodeElement extends KoiLabelElement {
  /// 创建坐标定位条码元素。
  const KoiPositionedBarcodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.height = 60,
    this.type = '128',
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 包含的字符串数据。
  final String data;

  /// 高度 (点数)。
  final int height;

  /// 条码类型（如 128）。
  final String type;
}

/// 坐标定位 QR 码元素。
class KoiPositionedQrCodeElement extends KoiLabelElement {
  /// 创建坐标定位二维码元素。
  const KoiPositionedQrCodeElement({
    required this.x,
    required this.y,
    required this.data,
    this.cellSize = 6,
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 包含的字符串数据。
  final String data;

  /// 单元格大小（模块宽度）。
  final int cellSize;
}

/// 标签矩形框元素。
class KoiLabelBoxElement extends KoiLabelElement {
  /// 创建标签矩形框元素。
  const KoiLabelBoxElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.thickness = 2,
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 宽度 (点数)。
  final int width;

  /// 高度 (点数)。
  final int height;

  /// 线条粗细（点数）。
  final int thickness;
}

/// 标签反白区域元素。
class KoiLabelReverseElement extends KoiLabelElement {
  /// 创建标签反白区域元素。
  const KoiLabelReverseElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 宽度 (点数)。
  final int width;

  /// 高度 (点数)。
  final int height;
}

/// 标签直线元素 (TSPL BAR / CPCL LINE)。
class KoiLabelLineElement extends KoiLabelElement {
  /// 创建标签直线元素。
  const KoiLabelLineElement({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 宽度 (点数)。
  final int width;

  /// 高度 (点数)。
  final int height;
}

/// 标签图片元素 (带 x, y 坐标)。
class KoiLabelImageElement extends KoiLabelElement {
  /// 创建标签图片元素。
  const KoiLabelImageElement({
    required this.x,
    required this.y,
    required this.imageBytes,
    this.width,
  });

  /// 起始 X 坐标。
  final int x;

  /// 起始 Y 坐标。
  final int y;

  /// 图像的字节数据 (通常为 PNG/JPEG 等标准格式的二进制)。
  final Uint8List imageBytes;

  /// 打印到纸上的具体宽度。为空则按纸宽缩放。
  final int? width;
}

/// 标签打印元素 — 触发打印。
class KoiLabelPrintElement extends KoiLabelElement {
  /// 创建标签触发打印元素。
  const KoiLabelPrintElement({this.copies = 1, this.sets = 1});

  /// 打印份数。
  final int copies;

  /// 打印的套数。
  final int sets;
}

/// 标签模板循环元素。
class KoiLabelForEachElement extends KoiLabelElement {
  /// 创建标签模板循环元素。
  const KoiLabelForEachElement({
    required this.listKey,
    required this.templates,
  });

  /// 绑定到模板数据的列表字段名（如 "items"）。
  final String listKey;

  /// 循环体内需要渲染的标签子元素模板。
  final List<KoiLabelElement> templates;
}

/// 原始指令元素 — 直接注入 TSPL/CPCL 文本指令。
/// Raw command element — injects raw text commands (auto GBK + \r\n).
class KoiRawCommandElement extends KoiLabelElement {
  /// 创建原始指令元素。
  const KoiRawCommandElement(this.command);

  /// 明文指令行, Renderer 自动 GBK 编码并追加 \r\n。
  final String command;
}
