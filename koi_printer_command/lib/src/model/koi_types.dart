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
  /// Documented.
  /// Constant constructor.
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
/// Documented.
/// Text alignment for flow-layout elements.
/// KoiTextAlign.
/// Documented.
/// KoiTextAlign.
enum KoiTextAlign { left, center, right }

/// 文本大小 (1-8 倍)。
/// Documented.
/// Text size multiplier, maps to ESC/POS GS ! command.
/// KoiTextSize.
enum KoiTextSize {
  /// Documented.
  /// Method.
  /// Method.
  size1(value: 1),
  /// Documented.
  /// Method.
  /// Method.
  size2(value: 2),
  /// Documented.
  /// Method.
  /// Method.
  size3(value: 3),
  /// Method.
  size4(value: 4),
  /// Method.
  /// Method.
  size5(value: 5),
  /// Method.
  size6(value: 6),
  /// Method.
  size7(value: 7),
  /// Method.
  size8(value: 8);

  const KoiTextSize({required this.value});

  /// Field.
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
 /// Documented.

  /// Method.
  /// 降级为图片打印 (zxing → image → raster)
  /// Documented.
  img,
 /// Documented.

  /// Documented.
  /// 降级为条形码
  /// Documented.
  barcode,
/// Documented.
}
 /// Documented.

/// QR 码大小 (1-8)。
/// QR code module size.
enum KoiQrSize {
  /// Documented.
  /// Method.
  size1(value: 1),
  /// Method.
  size2(value: 2),
  /// Method.
  size3(value: 3),
  /// Method.
  size4(value: 4),
  /// Method.
  size5(value: 5),
  /// Method.
  size6(value: 6),
  /// Method.
  size7(value: 7),
  /// Method.
  size8(value: 8);

  const KoiQrSize({required this.value});

  /// Field.
  /// Field.
  final int value;
}

/// QR 纠错等级。
/// QR error correction level.
enum KoiQrCorrection {
  /// Documented.
  /// Recovery Capacity 7%
  /// Method.
  low(value: 48),
 /// Documented.

  /// Documented.
  /// Recovery Capacity 15%
  /// Method.
  medium(value: 49),
 /// Documented.

  /// Documented.
  /// Recovery Capacity 25%
  /// Method.
  quartile(value: 50),
 /// Documented.

  /// Recovery Capacity 30%
  high(value: 51);

  const KoiQrCorrection({required this.value});

  /// Field.
  final int value;
}

/// 条码类型。
/// Barcode symbology types.
enum KoiBarcodeType {
  /// Documented.
  upcA,
  /// Documented.
  upcE,
  /// Documented.
  jan13,
  /// Documented.
  jan8,
  /// Documented.
  code39,
  /// Documented.
  itf,
  /// Documented.
  codabar,
  /// Documented.
  code93,
  /// Documented.
  code128,
}

/// 设备角色。
/// Device role — determines paper type and form factor.
enum KoiDeviceRole {
  /// 小票台式打印机
  ticketDesktop,

  /// Documented.
  /// 小票便携打印机
  ticketPortable,

  /// 标签台式打印机
  /// Documented.
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
/// Documented.
/// KoiPrintStyle.
/// KoiPrintStyle.
enum KoiPrintStyle { normal, large }

/// 标签样式 (6种公司样式)。
/// Documented.
/// Label style — 6 company-specific label layouts.
/// KoiLabelStyle.
/// KoiLabelStyle.
enum KoiLabelStyle { style1, style2, style3, style4, style5, style6 }

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
  /// GS v 0 — 光栅位图格式 (广泛兼容, 但已标记 obsolete)
  raster,

  /// GS ( L — 新标准图形模式 (推荐, 高质量)
  graphics,
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
