/// 连接策略 — 提炼自旧 240 次 retry + 3 秒定时器 + 2 秒自动断连。
/// 来源: 架构文档 §7.3
class KoiConnectionPolicy {
  /// 创建连接策略实例。
  /// [autoReconnectInterval] 重连时间间隔，[maxRetries] 最大重试次数。
  const KoiConnectionPolicy({
    this.autoReconnectInterval = const Duration(seconds: 3),
    this.maxRetries = 10,
    this.retryDelay = const Duration(milliseconds: 20),
    this.retryStrategy = KoiRetryStrategy.linear,
    this.autoDisconnectAfter,
  });

  /// 自动重连间隔 (来自旧 _autoConnectDuration)。
  final Duration autoReconnectInterval;

  /// 最大重试次数 (替代旧硬编码 240)。
  final int maxRetries;

  /// 每次重试间隔 (来自旧 connectDelayDuration)。
  final Duration retryDelay;

  /// 重试策略。
  final KoiRetryStrategy retryStrategy;

  /// 自动断连超时 (网络/经典蓝牙用, 来自旧 2 秒超时)。
  final Duration? autoDisconnectAfter;

  /// 根据重试次数计算延迟。
  Duration delayForRetry(int attempt) {
    return switch (retryStrategy) {
      KoiRetryStrategy.linear => retryDelay,
      KoiRetryStrategy.exponential => retryDelay * (1 << attempt.clamp(0, 10)),
    };
  }

  /// 默认策略 (适用大多数打印机)。
  static const defaultPolicy = KoiConnectionPolicy();

  /// 激进策略 (快速重连, 适用 BLE 设备)。
  static const aggressive = KoiConnectionPolicy(
    autoReconnectInterval: Duration(seconds: 1),
    maxRetries: 20,
    retryDelay: Duration(milliseconds: 10),
  );

  /// 保守策略 (网络打印机, 带指数退避)。
  static const conservative = KoiConnectionPolicy(
    autoReconnectInterval: Duration(seconds: 5),
    maxRetries: 5,
    retryDelay: Duration(milliseconds: 200),
    retryStrategy: KoiRetryStrategy.exponential,
    autoDisconnectAfter: Duration(seconds: 30),
  );
}

/// 重试策略。
enum KoiRetryStrategy {
  /// 固定间隔重试。
  linear,

  /// 指数退避重试。
  exponential,
}
