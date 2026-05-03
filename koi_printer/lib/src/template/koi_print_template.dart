import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer/src/config/koi_print_config.dart';

/// 小票打印模板抽象接口。
/// Abstract template interface for building ticket documents.
///
/// [T] 是业务数据类型。
/// 返回 `List<KoiTicketDocument>` 支持多联打印 (客户联 + 存根联)。
///
/// 使用示例 (在宿主 App 中实现):
/// ```dart
/// class SenderTicketTemplate implements KoiTicketTemplate<TicketInfo> {
///   @override
///   List<KoiTicketDocument> build(TicketInfo data, KoiPrintConfig config) {
///     return [
///       _buildClientCopy(data, config),
///       if (config.stubType != KoiStubType.clientOnly)
///         _buildStubCopy(data, config),
///     ];
///   }
/// }
/// ```
// ignore: one_member_abstracts
abstract class KoiTicketTemplate<T> {
  /// 构建小票文档列表 (支持多联)。
  List<KoiTicketDocument> build(T data, KoiPrintConfig config);
}

/// 标签打印模板抽象接口。
/// Abstract template interface for building label documents.
///
/// [T] 是业务数据类型。
///
/// 使用示例:
/// ```dart
/// class ProductLabelTemplate implements KoiLabelTemplate<ProductInfo> {
///   @override
///   List<KoiLabelDocument> build(ProductInfo data, KoiPrintConfig config) {
///     return [_buildLabel(data, config)];
///   }
/// }
/// ```
// ignore: one_member_abstracts
abstract class KoiLabelTemplate<T> {
  /// 构建标签文档列表。
  List<KoiLabelDocument> build(T data, KoiPrintConfig config);
}
