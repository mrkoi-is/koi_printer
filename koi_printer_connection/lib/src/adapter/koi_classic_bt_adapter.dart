import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer_connection/src/adapter/koi_printer_adapter.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// 经典蓝牙 (SPP) 适配器。
/// Classic Bluetooth (Serial Port Profile) adapter.
///
/// 使用 MethodChannel 调用原生经典蓝牙 API。
/// 来源: 旧 XIIBluetoothSerialPrinter (87 LOC)
class KoiClassicBtAdapter implements KoiPrinterAdapter {
  /// Method.
  KoiClassicBtAdapter();

  static const _channel = MethodChannel('koi_printer_connection/classic_bt');

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
      final connected = await _channel.invokeMethod<bool>('connect', {
        'deviceId': config.deviceId,
      });
      if (connected ?? false) {
        _updateState(KoiConnectionState.ready);
        return true;
      } else {
        _updateState(KoiConnectionState.disconnected);
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('KoiClassicBtAdapter: connect error: $e');
      _updateState(KoiConnectionState.disconnected);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<void>('disconnect');
    } on PlatformException catch (e) {
      debugPrint('KoiClassicBtAdapter: disconnect error: $e');
    }
    _updateState(KoiConnectionState.disconnected);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    for (final chunk in chunks) {
      // 经典蓝牙按 20 字节分块发送 (兼容老设备)
      const chunkSize = 20;
      for (var offset = 0; offset < chunk.length; offset += chunkSize) {
        final end = (offset + chunkSize > chunk.length)
            ? chunk.length
            : offset + chunkSize;
        final piece = chunk.sublist(offset, end);

        try {
          await _channel.invokeMethod<void>('sendData', {
            'data': Uint8List.fromList(piece),
          });

          // 老设备兼容延迟
          await Future<void>.delayed(const Duration(milliseconds: 20));
        } on PlatformException catch (e) {
          debugPrint('KoiClassicBtAdapter: send error: $e');
          rethrow;
        }
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
  }
}
