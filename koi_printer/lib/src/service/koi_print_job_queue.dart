import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';
import 'package:koi_printer/src/config/koi_print_config.dart';
import 'package:koi_printer/src/koi_printer_factory.dart';

/// 打印任务。
class KoiPrintJob {
  /// Method.
  KoiPrintJob({
    required this.documents,
    required this.config,
    this.copies = 1,
    this.onComplete,
  });

  /// 待打印的文档列表 (支持多联)。
  final List<KoiPrintDocument> documents;

  /// 打印配置。
  final KoiPrintConfig config;

  /// 打印份数。
  final int copies;

  /// 完成回调。
  final void Function(KoiPrintResult result)? onComplete;
}

/// 打印任务队列 — 替代旧 Queue + Future.delayed 模式。
/// 来源: 旧 PrinterService 中的 cmds 队列 + delay 逻辑。
class KoiPrintJobQueue {
  /// Method.
  KoiPrintJobQueue({this.adapter});

  /// 关联的适配器。
  KoiPrinterAdapter? adapter;

  final Queue<KoiPrintJob> _queue = Queue<KoiPrintJob>();
  bool _isProcessing = false;

  /// 当前队列长度。
  int get length => _queue.length;

  /// 是否正在处理。
  bool get isProcessing => _isProcessing;

  /// 入队一个打印任务。
  Future<KoiPrintResult> enqueue(KoiPrintJob job) async {
    final completer = Completer<KoiPrintResult>();

    _queue.add(
      KoiPrintJob(
        documents: job.documents,
        config: job.config,
        copies: job.copies,
        onComplete: (result) {
          job.onComplete?.call(result);
          completer.complete(result);
        },
      ),
    );

    if (!_isProcessing) {
      unawaited(_processQueue());
    }

    return completer.future;
  }

  /// 处理队列中的任务。
  Future<void> _processQueue() async {
    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final job = _queue.removeFirst();
      final result = await _executeJob(job);
      job.onComplete?.call(result);

      // 按延迟配置等待
      final delay = _delayForProfile(job.config.delayProfile);
      if (delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
    }

    _isProcessing = false;
  }

  /// 执行单个打印任务。
  Future<KoiPrintResult> _executeJob(KoiPrintJob job) async {
    if (adapter == null || !adapter!.isReady) {
      return const KoiPrintFailure(error: '打印机未连接', isRetryable: true);
    }

    try {
      final renderer = KoiPrinterFactory.createRenderer(
        job.config.renderer.protocol,
        qrStrategy: job.config.renderer.qrStrategy,
      );

      var totalBytes = 0;

      for (var copy = 0; copy < job.copies; copy++) {
        for (final doc in job.documents) {
          final chunks = renderer.render(doc);
          await adapter!.sendChunks(chunks);
          totalBytes += chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
        }
      }

      return KoiPrintSuccess(bytesSent: totalBytes);
    } catch (e) {
      debugPrint('KoiPrintJobQueue: job error: $e');
      return KoiPrintFailure(error: e.toString(), isRetryable: true);
    }
  }

  /// 根据延迟配置计算任务间延迟。
  /// 来源: 旧 XIIPrinterDelayConfig 的 delayed() 方法。
  Duration _delayForProfile(KoiDelayProfile profile) {
    return switch (profile) {
      KoiDelayProfile.normal => const Duration(milliseconds: 20),
      KoiDelayProfile.table2021 => const Duration(milliseconds: 200),
      KoiDelayProfile.table2018 => const Duration(milliseconds: 500),
    };
  }

  /// 清空队列。
  void clear() {
    _queue.clear();
  }
}
