import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:koi_printer_connection/src/adapter/koi_printer_adapter.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// 网络适配器 — TCP/IP 连接。
/// Network adapter using TCP/IP sockets (standard port 9100).
///
/// 来源: 旧 XIINetworkPrinter (94 LOC)
class KoiNetworkAdapter implements KoiPrinterAdapter {
  /// 创建网络打印机适配器实例。
  KoiNetworkAdapter();

  Socket? _socket;
  KoiConnectionConfig? _config;

  final StreamController<KoiConnectionState> _stateController =
      StreamController<KoiConnectionState>.broadcast();

  KoiConnectionState _state = KoiConnectionState.disconnected;

  @override
  KoiConnectionState get state => _state;

  @override
  Stream<KoiConnectionState> get stateStream => _stateController.stream;

  final StreamController<KoiPrinterHardwareState> _hwStateController =
      StreamController<KoiPrinterHardwareState>.broadcast();

  @override
  Stream<KoiPrinterHardwareState> get hardwareStateStream =>
      _hwStateController.stream;

  @override
  KoiConnectionPolicy get policy => KoiConnectionPolicy.conservative;

  @override
  KoiConnectionType get connectionType => KoiConnectionType.network;

  @override
  KoiConnectionConfig? get config => _config;

  @override
  bool get isReady => _state == KoiConnectionState.ready;

  @override
  Future<KoiPrinterHardwareState> queryHardwareState() async {
    if (_socket == null) {
      return KoiPrinterHardwareState.unknown;
    }

    try {
      // 发送 DLE EOT n=2 (离线原因查询: 开盖/缺纸)
      _socket!.add([0x10, 0x04, 0x02]);
      await _socket!.flush();

      // 等待响应 (最多 2 秒)
      final response = await _socket!.first.timeout(
        const Duration(seconds: 2),
      );

      if (response.isEmpty) return KoiPrinterHardwareState.unknown;

      final status = response.first;
      // bit 2: 开盖
      if ((status & 0x04) != 0) return KoiPrinterHardwareState.coverOpen;
      // bit 5: 缺纸
      if ((status & 0x20) != 0) return KoiPrinterHardwareState.outOfPaper;

      return KoiPrinterHardwareState.ready;
    } on TimeoutException {
      debugPrint('KoiNetworkAdapter: status query timeout');
      return KoiPrinterHardwareState.unknown;
    } on Object catch (e) {
      debugPrint('KoiNetworkAdapter: status query error: $e');
      return KoiPrinterHardwareState.unknown;
    }
  }

  @override
  Future<bool> connect(KoiConnectionConfig config) async {
    _config = config;
    _updateState(KoiConnectionState.connecting);

    final host = config.host ?? config.deviceId;
    final port = config.port;

    try {
      _socket = await Socket.connect(
        host,
        port,
        timeout: config.connectionTimeout,
      );
      _updateState(KoiConnectionState.ready);
      return true;
    } on Object catch (e) {
      debugPrint('KoiNetworkAdapter: connect error: $e');
      _updateState(KoiConnectionState.disconnected);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _socket?.flush();
      await _socket?.close();
    } on Object catch (e) {
      debugPrint('KoiNetworkAdapter: disconnect error: $e');
    }
    _socket = null;
    _updateState(KoiConnectionState.disconnected);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    if (_socket == null) {
      throw StateError('Not connected. Call connect first.');
    }

    chunks.forEach(_socket!.add);
    await _socket!.flush();
  }

  void _updateState(KoiConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
  }
}
