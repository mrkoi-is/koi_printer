/// 打印结果 — sealed class 表示成功或各种失败。
/// Print result — sealed class representing success or categorized failure.
///
/// 使用模式匹配处理:
/// ```dart
/// switch (result) {
///   case KoiPrintSuccess():
///     print('打印成功: ${result.documentName}');
///   case KoiPrintFailure():
///     print('打印失败: ${result.error}');
/// }
/// ```
sealed class KoiPrintResult {
  const KoiPrintResult();
}

/// 打印成功。
class KoiPrintSuccess extends KoiPrintResult {
  /// Documentation for this public member.
  const KoiPrintSuccess({this.documentName, this.bytesSent = 0});

  /// 打印的文档名称。
  final String? documentName;

  /// 已发送的字节数。
  final int bytesSent;
}

/// 打印失败。
/// KoiPrintFailure.
class KoiPrintFailure extends KoiPrintResult {
  /// Documentation for this public member.
  const KoiPrintFailure({
    required this.error,
    this.errorCode,
    this.documentName,
    this.isRetryable = true,
  });

  /// 错误描述。
  final String error;

  /// 错误代码 (可选)。
  final String? errorCode;

  /// 尝试打印的文档名称。
  final String? documentName;

  /// 是否可重试。
  final bool isRetryable;
}
