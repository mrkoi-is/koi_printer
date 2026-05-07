import 'package:meta/meta.dart';

/// 打印指令协议类型。
/// Print command protocol types.
enum KoiCommandProtocol {
  /// ESC/POS 协议 (小票打印机)
  escPos,

  /// TSPL 协议 (标签打印机)
  tspl,

  /// CPCL 协议 (便携标签打印机)
  cpcl,
}

/// 纸张尺寸。
/// Paper size for ticket printers.
/// 纸张尺寸。
/// Paper size — standard presets or custom dimensions.
@immutable
class KoiPaperSize {
  /// 根据点数和毫米数创建纸张尺寸。
  const KoiPaperSize({required this.widthDots, required this.widthMm});

  /// 自定义尺寸 (架构文档 §7.1)。
  /// [widthMm] 宽度 (mm), [dpi] 分辨率 (默认 203)。
  factory KoiPaperSize.custom(int widthMm, {int dpi = 203}) {
    final widthDots = (widthMm * dpi / 25.4).round();
    return KoiPaperSize(widthDots: widthDots, widthMm: widthMm);
  }

  /// 80mm 宽 (576 dots, 台式)
  static const mm80 = KoiPaperSize(widthDots: 576, widthMm: 80);

  /// 58mm 宽 (384 dots, 便携)
  static const mm58 = KoiPaperSize(widthDots: 384, widthMm: 58);

  /// 以 dots 为单位的纸张宽度。
  final int widthDots;

  /// 以 mm 为单位的纸张宽度。
  final int widthMm;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KoiPaperSize &&
          widthDots == other.widthDots &&
          widthMm == other.widthMm;

  @override
  int get hashCode => Object.hash(widthDots, widthMm);

  @override
  String toString() => 'KoiPaperSize(${widthMm}mm, ${widthDots}dots)';
}

/// 文本对齐方式。
/// Text alignment for flow-layout elements.
/// KoiTextAlign.
/// KoiTextAlign.
/// 文本对齐方式定义。
enum KoiTextAlign {
  /// 左对齐
  left,

  /// 居中对齐
  center,

  /// 右对齐
  right,
}

/// 文本大小 (1-8 倍)。
/// Text size multiplier, maps to ESC/POS GS ! command.
/// KoiTextSize.
enum KoiTextSize {
  /// 大小 1
  size1(value: 1),

  /// 大小 2
  size2(value: 2),

  /// 大小 3
  size3(value: 3),

  /// 大小 4
  size4(value: 4),

  /// 大小 5
  size5(value: 5),

  /// 大小 6
  size6(value: 6),

  /// 大小 7
  size7(value: 7),

  /// 大小 8
  size8(value: 8);

  const KoiTextSize({required this.value});

  /// 具体的数值
  final int value;
}

/// 切纸模式。
/// Paper cut mode.
enum KoiCutMode {
  /// 全切
  full,

  /// 半切
  partial,
}

/// QR 码渲染策略 (6种兼容方案)。
/// QR rendering strategy — 6 hardware-specific approaches accumulated
/// over 4 years of real-world testing.
///
/// 来源: 旧 XIIEscPosPaper.addQRAllInOne() 的 6 条分支。
enum KoiQrRenderStrategy {
  /// 标准 ESC/POS QR 指令 (GS ( k)
  normal,

  /// 老台式机 V1 指令 — 用 partition 分块发送
  legend,

  /// 老便携 (2019 前) V2 指令
  original,

  /// 芝科 XT-423 专用指令 (GBK 编码)
  zk,

  /// 降级为图片打印 (zxing → image → raster)
  img,

  /// 降级为条形码
  barcode,
}

/// QR 码大小 (1-8)。
/// QR code module size.
enum KoiQrSize {
  /// 大小 1
  size1(value: 1),

  /// 大小 2
  size2(value: 2),

  /// 大小 3
  size3(value: 3),

  /// 大小 4
  size4(value: 4),

  /// 大小 5
  size5(value: 5),

  /// 大小 6
  size6(value: 6),

  /// 大小 7
  size7(value: 7),

  /// 大小 8
  size8(value: 8);

  const KoiQrSize({required this.value});

  /// 具体的数值
  final int value;
}

/// QR 纠错等级。
/// QR error correction level.
enum KoiQrCorrection {
  /// Recovery Capacity 7%
  low(value: 48),

  /// Recovery Capacity 15%
  medium(value: 49),

  /// Recovery Capacity 25%
  quartile(value: 50),

  /// Recovery Capacity 30%
  high(value: 51);

  const KoiQrCorrection({required this.value});

  /// 具体的数值
  final int value;
}

/// 条码类型。
/// Barcode symbology types.
enum KoiBarcodeType {
  /// upcA 条码
  upcA,

  /// upcE 条码
  upcE,

  /// jan13 条码
  jan13,

  /// jan8 条码
  jan8,

  /// code39 条码
  code39,

  /// itf 条码
  itf,

  /// codabar 条码
  codabar,

  /// code93 条码
  code93,

  /// code128 条码
  code128,
}

/// 设备角色。
/// Device role — determines paper type and form factor.
enum KoiDeviceRole {
  /// 小票台式打印机
  ticketDesktop,

  /// 小票便携打印机
  ticketPortable,

  /// 标签台式打印机
  labelDesktop,

  /// 标签便携打印机
  labelPortable,
}

/// 延迟配置 (不同打印机型号的换装纸时间不同)。
/// Delay profile for different printer models. Determines pause
/// duration between multi-copy print jobs.
///
/// 来源: 旧 XIIPrinterDelayConfig
enum KoiDelayProfile {
  /// 标准型号 / 2019年款
  normal,

  /// 2021年自检页面 AT1.36.01
  table2021,

  /// 2018-2016 款老台式 / 老便携
  table2018,
}

/// 打印样式 (正常/加大)。
/// Print style — normal or enlarged text.
///
/// 来源: 旧 XIISenderPrintStyle
/// KoiPrintStyle.
/// KoiPrintStyle.
/// 打印样式定义。
enum KoiPrintStyle {
  /// 正常模式
  normal,

  /// 加大模式
  large,
}

/// 标签样式 (6种公司样式)。
/// Label style — 6 company-specific label layouts.
/// KoiLabelStyle.
/// KoiLabelStyle.
/// 标签样式定义。
enum KoiLabelStyle {
  /// 样式 1
  style1,

  /// 样式 2
  style2,

  /// 样式 3
  style3,

  /// 样式 4
  style4,

  /// 样式 5
  style5,

  /// 样式 6
  style6,
}

/// 切纸行为配置。
/// Cut behavior configuration.
enum KoiCutBehavior {
  /// 不切纸
  noCut,

  /// 每联切纸
  cutPerCopy,

  /// 仅最后一联切纸
  cutAtEnd,
}

/// 存根联类型。
/// Stub type for multi-copy printing.
enum KoiStubType {
  /// 不打印存根联
  none,

  /// 打印存根联
  withStub,
}

/// 字体类型。
/// Font type selection for ESC/POS printers.
enum KoiFontType {
  /// Font A (标准, 12×24 dots)
  fontA,

  /// Font B (紧凑, 9×17 dots)
  fontB,
}

/// 下划线样式。
/// Underline style for text elements.
enum KoiUnderlineStyle {
  /// 无下划线
  none,

  /// 细下划线 (1-dot)
  thin,

  /// 粗下划线 (2-dot)
  thick,
}

/// 图片渲染模式。
/// Image rendering mode for ESC/POS printers.
enum KoiImageRenderMode {
  /// ESC * — 传统列格式位图 (兼容性最好，针对老式打印机)
  bitImage,

  /// GS v 0 — 光栅位图格式 (广泛兼容, 但已标记 obsolete)
  raster,

  /// GS ( L — 新标准图形模式 (推荐, 高质量)
  graphics,
}

/// 标签纸张类型 (TSPL 行业标准)。
/// Label paper type — industry standard per TSC TSPL specification.
enum KoiLabelPaperType {
  /// 间隙标签纸 (TSPL: GAP m,n) — 标签之间有透明间距
  gap,

  /// 黑标纸 (TSPL: BLINE m,n) — 标签背面有黑色标记线
  blackMark,

  /// 连续纸 (无间距/黑标, 需手动设置长度)
  continuous,
}

/// 标签打印方向 (TSPL 行业标准)。
/// Label print direction — TSPL standard DIRECTION command.
enum KoiLabelDirection {
  /// 方向 0: 正向出纸
  forward(0),

  /// 方向 1: 反向出纸 (常用于桌面出纸口朝向用户)
  backward(1);

  const KoiLabelDirection(this.value);

  /// TSPL DIRECTION 指令参数值。
  final int value;
}

/// 图像二值化模式。
/// Image dithering mode for thermal printing.
/// Floyd-Steinberg is the industry standard for photo-quality output.
enum KoiImageDitherMode {
  /// 简单阈值 (适合文字、条码、Logo)
  threshold,

  /// Floyd-Steinberg 误差扩散 (适合照片、渐变图像)
  floydSteinberg,
}

/// 钱箱引脚。
/// Cash drawer pin selection.
enum KoiCashDrawerPin {
  /// 引脚 2
  pin2,

  /// 引脚 5
  pin5,
}

/// 条码下方文字位置。
/// HRI (Human Readable Interpretation) text position for barcodes.
enum KoiBarcodeTextPosition {
  /// 不显示 HRI 文字
  none,

  /// 条码上方
  above,

  /// 条码下方 (默认)
  below,

  /// 上方和下方
  both,
}

/// 打印机字符代码页 (ESC t n)。
/// Printer character code page selection.
enum KoiCodePage {
  /// PC437 — 美国/标准欧洲 (Epson 默认)
  pc437(0),

  /// PC850 — 多语言拉丁
  pc850(2),

  /// PC860 — 葡萄牙语
  pc860(3),

  /// PC863 — 法语 (加拿大)
  pc863(4),

  /// PC865 — 北欧
  pc865(5),

  /// WPC1252 — Windows Latin-1
  wpc1252(16),

  /// PC866 — 西里尔文 #2
  pc866(17),

  /// PC852 — 拉丁文 2
  pc852(18),

  /// Thai42 — 泰语
  thai42(20),

  /// 简体中文 GBK
  gbk(255);

  const KoiCodePage(this.value);

  /// ESC t 指令参数值。
  final int value;
}
