import 'dart:typed_data';

/// ESC/POS 实时状态查询工具类。
/// Utility for ESC/POS DLE EOT real-time status query and response parsing.
///
/// 行业标准: DLE EOT n (0x10 0x04 n)
/// - n=1: 打印机在线状态
/// - n=2: 离线原因 (开盖/按键/缺纸等)
/// - n=3: 错误状态 (切刀/过热等)
/// - n=4: 纸张状态 (有纸/将尽/无纸)
class KoiEscPosStatusQuery {
  const KoiEscPosStatusQuery._();

  /// DLE EOT 指令前缀: 0x10 0x04
  static const _dleEotPrefix = [0x10, 0x04];

  /// 生成打印机状态查询指令 (DLE EOT n=1)。
  static Uint8List queryPrinterStatus() =>
      Uint8List.fromList([..._dleEotPrefix, 1]);

  /// 生成离线原因查询指令 (DLE EOT n=2)。
  static Uint8List queryOfflineCause() =>
      Uint8List.fromList([..._dleEotPrefix, 2]);

  /// 生成错误状态查询指令 (DLE EOT n=3)。
  static Uint8List queryErrorStatus() =>
      Uint8List.fromList([..._dleEotPrefix, 3]);

  /// 生成纸张状态查询指令 (DLE EOT n=4)。
  static Uint8List queryPaperStatus() =>
      Uint8List.fromList([..._dleEotPrefix, 4]);

  /// 解析 DLE EOT n=2 的响应字节。
  /// 返回 [KoiEscPosOfflineStatus]。
  static KoiEscPosOfflineStatus parseOfflineCause(int responseByte) {
    return KoiEscPosOfflineStatus(
      coverOpen: (responseByte & 0x04) != 0,
      feedButtonPressed: (responseByte & 0x08) != 0,
      paperEnd: (responseByte & 0x20) != 0,
      errorOccurred: (responseByte & 0x40) != 0,
    );
  }

  /// 解析 DLE EOT n=3 的响应字节。
  /// 返回 [KoiEscPosErrorStatus]。
  static KoiEscPosErrorStatus parseErrorStatus(int responseByte) {
    return KoiEscPosErrorStatus(
      cutterError: (responseByte & 0x08) != 0,
      unrecoverableError: (responseByte & 0x20) != 0,
      autoRecoverableError: (responseByte & 0x40) != 0,
    );
  }

  /// 解析 DLE EOT n=4 的响应字节。
  /// 返回 [KoiEscPosPaperStatus]。
  static KoiEscPosPaperStatus parsePaperStatus(int responseByte) {
    final paperNearEnd = (responseByte & 0x0C) == 0x0C;
    final paperOut = (responseByte & 0x60) == 0x60;
    return KoiEscPosPaperStatus(
      paperNearEnd: paperNearEnd,
      paperOut: paperOut,
    );
  }
}

/// ESC/POS 离线原因状态。
class KoiEscPosOfflineStatus {
  /// 创建离线原因状态实例。
  const KoiEscPosOfflineStatus({
    required this.coverOpen,
    required this.feedButtonPressed,
    required this.paperEnd,
    required this.errorOccurred,
  });

  /// 纸仓开盖。
  final bool coverOpen;

  /// 进纸按钮被按下。
  final bool feedButtonPressed;

  /// 纸张用尽。
  final bool paperEnd;

  /// 发生错误。
  final bool errorOccurred;

  @override
  String toString() =>
      'OfflineStatus(coverOpen=$coverOpen, feedButton=$feedButtonPressed, '
      'paperEnd=$paperEnd, error=$errorOccurred)';
}

/// ESC/POS 错误状态。
class KoiEscPosErrorStatus {
  /// 创建错误状态实例。
  const KoiEscPosErrorStatus({
    required this.cutterError,
    required this.unrecoverableError,
    required this.autoRecoverableError,
  });

  /// 切刀故障。
  final bool cutterError;

  /// 不可恢复错误。
  final bool unrecoverableError;

  /// 自动恢复错误。
  final bool autoRecoverableError;

  @override
  String toString() =>
      'ErrorStatus(cutter=$cutterError, unrecoverable=$unrecoverableError, '
      'autoRecoverable=$autoRecoverableError)';
}

/// ESC/POS 纸张状态。
class KoiEscPosPaperStatus {
  /// 创建纸张状态实例。
  const KoiEscPosPaperStatus({
    required this.paperNearEnd,
    required this.paperOut,
  });

  /// 纸张将尽 (Near-end sensor 触发)。
  final bool paperNearEnd;

  /// 纸张已用尽。
  final bool paperOut;

  @override
  String toString() => 'PaperStatus(nearEnd=$paperNearEnd, out=$paperOut)';
}
