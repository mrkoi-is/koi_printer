import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:koi_printer/src/koi_printer_factory.dart';
import 'package:koi_printer/src/koi_template_engine.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

/// 打印服务 — 组合 command + connection 的完整打印流程。
/// High-level printer service combining rendering, connection, and template
/// expansion into a single API.
///
/// 使用方式:
/// ```dart
/// final service = KoiPrinterService(
///   protocol: KoiCommandProtocol.escPos,
///   connectionType: KoiConnectionType.ble,
/// );
///
/// await service.connect(config);
///
/// final result = await service.print(document);
/// switch (result) {
///   case KoiPrintSuccess(:final bytesSent):
///     print('Sent $bytesSent bytes');
///   case KoiPrintFailure(:final error):
///     print('Error: $error');
/// }
/// ```
class KoiPrinterService {
  /// 创建打印服务。
  ///
  /// [protocol] 指令协议。
  /// [connectionType] 连接类型。
  /// [qrStrategy] QR 码渲染策略 (仅 ESC/POS)。
  /// [renderer] 可选, 自定义渲染器 (覆盖 protocol 默认值)。
  /// [adapter] 可选, 自定义适配器 (覆盖 connectionType 默认值)。
  KoiPrinterService({
    required KoiCommandProtocol protocol,
    required KoiConnectionType connectionType,
    KoiQrRenderStrategy qrStrategy = KoiQrRenderStrategy.normal,
    KoiCommandRenderer? renderer,
    KoiPrinterAdapter? adapter,
  }) : _renderer =
           renderer ??
           KoiPrinterFactory.createRenderer(protocol, qrStrategy: qrStrategy),
       _adapter = adapter ?? KoiPrinterFactory.createAdapter(connectionType),
       _templateEngine = const KoiTemplateEngine();

  final KoiCommandRenderer _renderer;
  final KoiPrinterAdapter _adapter;
  final KoiTemplateEngine _templateEngine;

  /// 当前连接状态。
  KoiConnectionState get connectionState => _adapter.state;

  /// 连接状态流 — 用于 UI 响应式更新。
  Stream<KoiConnectionState> get connectionStateStream => _adapter.stateStream;

  /// 是否已就绪。
  bool get isReady => _adapter.isReady;

  /// 连接到打印机。
  Future<bool> connect(KoiConnectionConfig config) async {
    return _adapter.connect(config);
  }

  /// 断开连接。
  Future<void> disconnect() async {
    await _adapter.disconnect();
  }

  /// 打印文档。
  ///
  /// [document] 打印文档 (KoiTicketDocument 或 KoiLabelDocument)。
  /// [data] ForEach 模板数据 (可选)。
  /// [copies] 打印份数。
  Future<KoiPrintResult> print(
    KoiPrintDocument document, {
    Map<String, List<Map<String, String>>>? data,
    int copies = 1,
  }) async {
    if (!_adapter.isReady) {
      return const KoiPrintFailure(error: '打印机未连接');
    }

    try {
      // 1. 展开模板 (如有)
      final expandedDoc = _expandIfNeeded(document, data);

      // 2. 渲染为字节
      final chunks = _renderer.render(expandedDoc);

      // 3. 发送 (按份数)
      var totalBytes = 0;
      for (var i = 0; i < copies; i++) {
        await _adapter.sendChunks(chunks);
        totalBytes += chunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      }

      return KoiPrintSuccess(
        documentName: document.name,
        bytesSent: totalBytes,
      );
    } catch (e) {
      debugPrint('KoiPrinterService: print error: $e');
      return KoiPrintFailure(
        documentName: document.name,
        error: e.toString(),
      );
    }
  }

  KoiPrintDocument _expandIfNeeded(
    KoiPrintDocument document,
    Map<String, List<Map<String, dynamic>>>? data,
  ) {
    if (data == null) return document;
    return switch (document) {
      KoiTicketDocument() => _templateEngine.expandTicket(document, data),
      KoiLabelDocument() => _templateEngine.expandLabel(document, data),
    };
  }

  /// 释放资源。
  Future<void> dispose() async {
    await _adapter.dispose();
  }
}
