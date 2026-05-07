import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:koi_printer/src/config/koi_print_config.dart';
import 'package:koi_printer/src/koi_printer_factory.dart';
import 'package:koi_printer/src/koi_template_engine.dart';
import 'package:koi_printer/src/service/koi_print_job_queue.dart';
import 'package:koi_printer/src/storage/koi_printer_storage.dart';
import 'package:koi_printer/src/template/koi_print_template.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

/// 打印机管理器 — 同时管理小票机 + 标签机。
/// Dual-printer manager supporting ticket + label printers simultaneously.
///
/// 来源: 旧 XIIPrinterService (292 LOC, Singleton)
/// 改进: 构造函数注入, 独立队列, 无 Singleton。
///
/// 使用方式:
/// ```dart
/// final manager = KoiPrinterManager(storage: storage);
/// await manager.connectAll();
///
/// final result = await manager.printTicket(
///   template: SenderTicketTemplate(),
///   data: ticketInfo,
///   config: config,
/// );
/// ```
class KoiPrinterManager extends ChangeNotifier {
  /// 初始化打印机管理器。
  KoiPrinterManager({
    required this.storage,
    KoiPrinterAdapter? ticketAdapter,
    KoiPrinterAdapter? labelAdapter,
  }) : _ticketAdapter = ticketAdapter,
       _labelAdapter = labelAdapter {
    _ticketQueue = KoiPrintJobQueue(adapter: _ticketAdapter);
    _labelQueue = KoiPrintJobQueue(adapter: _labelAdapter);
  }

  /// 设备存储。
  final KoiPrinterStorage storage;

  KoiPrinterAdapter? _ticketAdapter;
  KoiPrinterAdapter? _labelAdapter;
  late final KoiPrintJobQueue _ticketQueue;
  late final KoiPrintJobQueue _labelQueue;

  Timer? _autoConnectTimer;

  final _templateEngine = const KoiTemplateEngine();

  // ── 适配器访问 ──

  /// 小票打印机适配器。
  KoiPrinterAdapter? get ticketAdapter => _ticketAdapter;

  /// 标签打印机适配器。
  KoiPrinterAdapter? get labelAdapter => _labelAdapter;

  /// 小票打印机连接状态。
  KoiConnectionState get ticketState =>
      _ticketAdapter?.state ?? KoiConnectionState.disconnected;

  /// 标签打印机连接状态。
  KoiConnectionState get labelState =>
      _labelAdapter?.state ?? KoiConnectionState.disconnected;

  // ── 连接管理 ──

  /// 连接所有已绑定的打印机。
  Future<void> connectAll() async {
    await Future.wait([_connectTicket(), _connectLabel()]);
  }

  /// 断开所有打印机。
  Future<void> disconnectAll() async {
    stopAutoConnect();
    await Future.wait([
      if (_ticketAdapter != null) _ticketAdapter!.disconnect(),
      if (_labelAdapter != null) _labelAdapter!.disconnect(),
    ]);
  }

  /// 连接小票打印机。
  Future<bool> connectTicketPrinter(KoiConnectionConfig config) async {
    if (_ticketAdapter == null) return false;
    final success = await _ticketAdapter!.connect(config);
    _ticketQueue.adapter = _ticketAdapter;
    return success;
  }

  /// 连接标签打印机。
  Future<bool> connectLabelPrinter(KoiConnectionConfig config) async {
    if (_labelAdapter == null) return false;
    final success = await _labelAdapter!.connect(config);
    _labelQueue.adapter = _labelAdapter;
    return success;
  }

  /// 绑定小票打印机适配器。
  void setTicketAdapter(KoiPrinterAdapter adapter) {
    _ticketAdapter = adapter;
    _ticketQueue.adapter = adapter;
    notifyListeners();
  }

  /// 绑定标签打印机适配器。
  void setLabelAdapter(KoiPrinterAdapter adapter) {
    _labelAdapter = adapter;
    _labelQueue.adapter = adapter;
    notifyListeners();
  }

  // ── 自动连接 ──

  /// 启动自动连接定时器。
  /// 来源: 旧 startAutoConnectTimer (3s 间隔)
  void startAutoConnect({Duration interval = const Duration(seconds: 3)}) {
    stopAutoConnect();
    _autoConnectTimer = Timer.periodic(interval, (_) => connectAll());
  }

  /// 停止自动连接。
  void stopAutoConnect() {
    _autoConnectTimer?.cancel();
    _autoConnectTimer = null;
  }

  // ── 打印 ──

  /// 打印小票 (模板模式)。
  Future<KoiPrintResult> printTicket<T>({
    required KoiTicketTemplate<T> template,
    required T data,
    required KoiPrintConfig config,
  }) async {
    final documents = template.build(data, config);
    return _enqueueTicket(documents, config);
  }

  /// 打印小票 (文档模式 — 支持 ForEach 模板变量)。
  Future<KoiPrintResult> printTicketDocument(
    KoiTicketDocument document, {
    required KoiPrintConfig config,
    Map<String, List<Map<String, String>>>? templateData,
  }) async {
    final expanded =
        templateData != null
            ? _templateEngine.expandTicket(document, templateData)
            : document;
    return _enqueueTicket([expanded], config);
  }

  /// 打印标签 (模板模式)。
  Future<KoiPrintResult> printLabel<T>({
    required KoiLabelTemplate<T> template,
    required T data,
    required KoiPrintConfig config,
  }) async {
    final documents = template.build(data, config);
    return _enqueueLabel(documents, config);
  }

  /// 打印标签 (文档模式)。
  Future<KoiPrintResult> printLabelDocument(
    KoiLabelDocument document, {
    required KoiPrintConfig config,
  }) async {
    return _enqueueLabel([document], config);
  }

  // ── 内部方法 ──

  Future<KoiPrintResult> _enqueueTicket(
    List<KoiTicketDocument> docs,
    KoiPrintConfig config,
  ) async {
    return _ticketQueue.enqueue(
      KoiPrintJob(documents: docs, config: config, copies: config.copies),
    );
  }

  Future<KoiPrintResult> _enqueueLabel(
    List<KoiLabelDocument> docs,
    KoiPrintConfig config,
  ) async {
    return _labelQueue.enqueue(
      KoiPrintJob(documents: docs, config: config, copies: config.copies),
    );
  }

  Future<void> _connectTicket() async {
    final device = storage.getTicketPrinter();
    if (device == null) return;

    if (_ticketAdapter == null) {
      _ticketAdapter = KoiPrinterFactory.createAdapter(device.connectionType);
      _ticketQueue.adapter = _ticketAdapter;
      notifyListeners();
    }

    if (_ticketAdapter!.isReady ||
        _ticketAdapter!.state == KoiConnectionState.connecting ||
        _ticketAdapter!.state == KoiConnectionState.discovering) {
      return;
    }

    try {
      await _ticketAdapter!.connect(
        KoiConnectionConfig(deviceName: device.name, deviceId: device.address),
      );
    } on Object catch (e) {
      debugPrint('KoiPrinterManager: ticket connect error: $e');
    }
  }

  Future<void> _connectLabel() async {
    final device = storage.getLabelPrinter();
    if (device == null) return;

    if (_labelAdapter == null) {
      _labelAdapter = KoiPrinterFactory.createAdapter(device.connectionType);
      _labelQueue.adapter = _labelAdapter;
      notifyListeners();
    }

    if (_labelAdapter!.isReady ||
        _labelAdapter!.state == KoiConnectionState.connecting ||
        _labelAdapter!.state == KoiConnectionState.discovering) {
      return;
    }

    try {
      await _labelAdapter!.connect(
        KoiConnectionConfig(deviceName: device.name, deviceId: device.address),
      );
    } on Object catch (e) {
      debugPrint('KoiPrinterManager: label connect error: $e');
    }
  }

  /// 释放资源。
  @override
  void dispose() {
    stopAutoConnect();
    _ticketQueue.clear();
    _labelQueue.clear();
    _ticketAdapter?.dispose().ignore();
    _labelAdapter?.dispose().ignore();
    super.dispose();
  }
}
