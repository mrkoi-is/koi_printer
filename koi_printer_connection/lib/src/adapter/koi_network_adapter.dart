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
    return KoiPrinterHardwareState.unknown;
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
    } catch (e) {
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
    } catch (e) {
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

    for (final chunk in chunks) {
      _socket!.add(chunk);
    }
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
