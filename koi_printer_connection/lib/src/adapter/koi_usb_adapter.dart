import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer_connection/src/adapter/koi_printer_adapter.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// USB 适配器。
/// USB adapter using platform channels (Android only currently).
///
/// 来源: 旧 XIIUSBPrinter (175 LOC)
class KoiUsbAdapter implements KoiPrinterAdapter {
  KoiUsbAdapter();

  static const _channel = MethodChannel('koi_printer_connection/usb');

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
  KoiConnectionType get connectionType => KoiConnectionType.usb;

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

    // USB 仅支持 Android
    if (!Platform.isAndroid) {
      debugPrint('KoiUsbAdapter: USB printing only supported on Android');
      return false;
    }

    _updateState(KoiConnectionState.connecting);

    try {
      final connected = await _channel.invokeMethod<bool>('connect', {
        'vendorId': int.tryParse(config.deviceId.split(':').first) ?? 0,
        'productId': int.tryParse(config.deviceId.split(':').last) ?? 0,
      });
      if (connected ?? false) {
        _updateState(KoiConnectionState.ready);
        return true;
      } else {
        _updateState(KoiConnectionState.disconnected);
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint('KoiUsbAdapter: connect error: $e');
      _updateState(KoiConnectionState.disconnected);
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    try {
      await _channel.invokeMethod<void>('close');
    } on PlatformException catch (e) {
      debugPrint('KoiUsbAdapter: disconnect error: $e');
    }
    _updateState(KoiConnectionState.disconnected);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    for (final chunk in chunks) {
      try {
        await _channel.invokeMethod<void>('write', {
          'data': Uint8List.fromList(chunk),
        });
      } on PlatformException catch (e) {
        debugPrint('KoiUsbAdapter: write error: $e');
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
  }
}
