import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:koi_printer_connection/src/adapter/koi_printer_adapter.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// 经典蓝牙 (SPP) 适配器。
/// Classic Bluetooth (Serial Port Profile) adapter.
class KoiClassicBtAdapter implements KoiPrinterAdapter {
  /// 创建经典蓝牙适配器实例。
  KoiClassicBtAdapter({this.connectionFactory});

  /// Factory function for testing.
  final Future<BluetoothConnection> Function(String address)? connectionFactory;

  BluetoothConnection? _connection;
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
  KoiConnectionPolicy get policy => KoiConnectionPolicy.defaultPolicy;

  @override
  KoiConnectionType get connectionType => KoiConnectionType.classicBluetooth;

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

    try {
      _connection =
          connectionFactory != null
              ? await connectionFactory!(config.deviceId)
              : await BluetoothConnection.toAddress(config.deviceId);

      _connection?.input?.listen(
        (data) {
          // 这里可以处理接收到的硬件状态
        },
        onDone: () {
          _updateState(KoiConnectionState.disconnected);
          _connection = null;
        },
      );

      _updateState(KoiConnectionState.ready);
      return true;
    } on Object catch (e) {
      debugPrint('KoiClassicBtAdapter: connect error: $e');
      _updateState(KoiConnectionState.disconnected);
      _connection = null;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection = null;
    } on Object catch (e) {
      debugPrint('KoiClassicBtAdapter: disconnect error: $e');
    }
    _updateState(KoiConnectionState.disconnected);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    if (_connection == null || !_connection!.isConnected) {
      throw Exception('KoiClassicBtAdapter: not connected');
    }

    for (final chunk in chunks) {
      try {
        _connection!.output.add(Uint8List.fromList(chunk));
        await _connection!.output.allSent;
      } on Object catch (e) {
        debugPrint('KoiClassicBtAdapter: send error: $e');
        rethrow;
      }
    }
  }

  void _updateState(KoiConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _hwStateController.close();
  }
}
