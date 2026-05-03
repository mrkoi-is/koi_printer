import 'package:koi_printer_command/koi_printer_command.dart'
    show KoiCpclRenderer, KoiEscPosRenderer, KoiTsplRenderer;
import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';

/// 指令渲染器接口 — 将 KoiPrintDocument 转换为协议字节。
/// Command renderer interface — converts a KoiPrintDocument into
/// protocol-specific byte sequences.
///
/// 实现:
/// - [KoiEscPosRenderer] — ESC/POS 小票协议 (接受 KoiTicketDocument)
/// - [KoiTsplRenderer] — TSPL 标签协议 (接受 KoiLabelDocument)
/// - [KoiCpclRenderer] — CPCL 便携标签协议 (接受 KoiLabelDocument)
abstract interface class KoiCommandRenderer {
  /// 该渲染器对应的协议类型。
  KoiCommandProtocol get protocol;

  /// 将文档渲染为字节块列表。
  ///
  /// [document] 打印文档 (KoiTicketDocument 或 KoiLabelDocument)。
  /// [qrStrategy] — 来自 KoiPrinterProfile.bestQrStrategy 的覆盖策略
  /// (ESC/POS 专用, TSPL/CPCL 忽略)。
  /// [dotsPerLine] — 覆盖纸张 dots/line (能力感知)。
  ///
  /// 返回 `List<List<int>>` 而非 `List<int>`:
  /// - 某些 QR 策略 (如 legend) 需要分块发送
  /// - BLE MTU 分块在 connection 层处理,
  ///   这里的分块是协议层的逻辑分块
  List<List<int>> render(
    KoiPrintDocument document, {
    KoiQrRenderStrategy? qrStrategy,
    int? dotsPerLine,
  });
}
