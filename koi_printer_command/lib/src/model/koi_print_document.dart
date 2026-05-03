import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';

/// 打印文档 (sealed) — 小票或标签。
/// Sealed print document — either a ticket (receipt) or a label.
sealed class KoiPrintDocument {
  const KoiPrintDocument({this.name});

  /// 文档名称 (用于日志和队列显示)。
  final String? name;
}

/// 小票文档 — 流式布局, 元素为 [KoiTicketElement]。
/// Ticket (receipt) document using flow layout.
class KoiTicketDocument extends KoiPrintDocument {
  const KoiTicketDocument({
    required this.elements,
    this.paperSize = KoiPaperSize.mm80,
    this.codePage = KoiCodePage.gbk,
    super.name,
  });

  /// 小票打印元素列表 (有序, 流式)。
  final List<KoiTicketElement> elements;

  /// 纸张尺寸。
  final KoiPaperSize paperSize;

  /// 字符代码页 (ESC t n)。默认 GBK (简体中文)。
  final KoiCodePage codePage;
}

/// 标签文档 — 坐标定位布局, 元素为 [KoiLabelElement]。
/// Label document using positioned (canvas) layout.
/// KoiLabelDocument.
class KoiLabelDocument extends KoiPrintDocument {
  const KoiLabelDocument({required this.elements, super.name});

  /// 标签打印元素列表 (有序, 坐标定位)。
  final List<KoiLabelElement> elements;
}
