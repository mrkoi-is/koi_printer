import 'package:koi_printer_command/koi_printer_command.dart';

/// 渲染器配置 — 从旧 XIIPrinterConfig 中拆出的渲染层字段。
class KoiRendererConfig {
  /// Constant constructor.
  const KoiRendererConfig({
    this.protocol = KoiCommandProtocol.escPos,
    this.qrStrategy = KoiQrRenderStrategy.normal,
  });

  /// 指令协议。
  final KoiCommandProtocol protocol;

  /// QR 码渲染策略。
  final KoiQrRenderStrategy qrStrategy;

  /// Method.
  KoiRendererConfig copyWith({
    KoiCommandProtocol? protocol,
    KoiQrRenderStrategy? qrStrategy,
  }) {
    return KoiRendererConfig(
      protocol: protocol ?? this.protocol,
      qrStrategy: qrStrategy ?? this.qrStrategy,
    );
  }
}

/// 打印配置 — 从旧 XIIPrinterConfig + XIIPrintSettings 拆出的业务层字段。
/// 来源: 旧 XIIPrinterConfig + XIIPrintSettings
class KoiPrintConfig {
  /// Constant constructor.
  const KoiPrintConfig({
    this.deviceRole = KoiDeviceRole.ticketDesktop,
    this.paperSize = KoiPaperSize.mm80,
    this.renderer = const KoiRendererConfig(),
    this.cutBehavior = KoiCutBehavior.cutPerCopy,
    this.printStyle = KoiPrintStyle.normal,
    this.labelStyle = KoiLabelStyle.style1,
    this.delayProfile = KoiDelayProfile.normal,
    this.stubType = KoiStubType.withStub,
    this.headerEmptyLines = 0,
    this.copies = 1,
  });

  /// 设备角色 (小票台式/便携, 标签台式/便携)。
  final KoiDeviceRole deviceRole;

  /// 纸张大小。
  final KoiPaperSize paperSize;

  /// 渲染器配置 (协议 + QR 策略)。
  final KoiRendererConfig renderer;

  /// 切纸行为。
  final KoiCutBehavior cutBehavior;

  /// 打印样式 (标准/大字)。
  final KoiPrintStyle printStyle;

  /// 标签样式 (6 种企业样式)。
  final KoiLabelStyle labelStyle;

  /// 延迟配置 (控制不同打印机的发送间隔)。
  final KoiDelayProfile delayProfile;

  /// 存根类型 (客户联 + 存根联 / 仅客户联 / 仅存根联)。
  final KoiStubType stubType;

  /// 收货联顶部空行数。
  final int headerEmptyLines;

  /// 打印份数。
  final int copies;

  /// Method.
  KoiPrintConfig copyWith({
    KoiDeviceRole? deviceRole,
    KoiPaperSize? paperSize,
    KoiRendererConfig? renderer,
    KoiCutBehavior? cutBehavior,
    KoiPrintStyle? printStyle,
    KoiLabelStyle? labelStyle,
    KoiDelayProfile? delayProfile,
    KoiStubType? stubType,
    int? headerEmptyLines,
    int? copies,
  }) {
    return KoiPrintConfig(
      deviceRole: deviceRole ?? this.deviceRole,
      paperSize: paperSize ?? this.paperSize,
      renderer: renderer ?? this.renderer,
      cutBehavior: cutBehavior ?? this.cutBehavior,
      printStyle: printStyle ?? this.printStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      delayProfile: delayProfile ?? this.delayProfile,
      stubType: stubType ?? this.stubType,
      headerEmptyLines: headerEmptyLines ?? this.headerEmptyLines,
      copies: copies ?? this.copies,
    );
  }
}
