import 'dart:async';

import 'package:koi_printer_connection/koi_printer_connection.dart';

/// 测试用 Mock 打印机适配器。
class MockPrinterAdapter implements KoiPrinterAdapter {
  MockPrinterAdapter({
    this.shouldConnect = true,
    this.shouldThrowOnSend = false,
    this.shouldThrowOnConnect = false,
    KoiConnectionState initialState = KoiConnectionState.disconnected,
  }) : _state = initialState;

  final bool shouldConnect;
  final bool shouldThrowOnSend;
  final bool shouldThrowOnConnect;

  KoiConnectionState _state;
  KoiConnectionConfig? _config;
  int sendCallCount = 0;
  int totalBytesSent = 0;

  final _stateCtrl = StreamController<KoiConnectionState>.broadcast();
  final _hwCtrl = StreamController<KoiPrinterHardwareState>.broadcast();

  @override
  KoiConnectionState get state => _state;

  @override
  Stream<KoiConnectionState> get stateStream => _stateCtrl.stream;

  @override
  Stream<KoiPrinterHardwareState> get hardwareStateStream => _hwCtrl.stream;

  @override
  KoiConnectionType get connectionType => KoiConnectionType.ble;

  @override
  KoiConnectionConfig? get config => _config;

  @override
  KoiConnectionPolicy get policy => KoiConnectionPolicy.defaultPolicy;

  @override
  bool get isReady => _state == KoiConnectionState.ready;

  @override
  Future<bool> connect(KoiConnectionConfig config) async {
    if (shouldThrowOnConnect) {
      throw Exception('模拟连接失败');
    }
    _config = config;
    if (shouldConnect) {
      _state = KoiConnectionState.ready;
      _stateCtrl.add(_state);
      return true;
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    _state = KoiConnectionState.disconnected;
    _stateCtrl.add(_state);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    if (shouldThrowOnSend) {
      throw Exception('模拟发送失败');
    }
    sendCallCount++;
    for (final chunk in chunks) {
      totalBytesSent += chunk.length;
    }
  }

  @override
  Future<KoiPrinterHardwareState> queryHardwareState() async {
    return KoiPrinterHardwareState.ready;
  }

  @override
  Future<void> dispose() async {
    await _stateCtrl.close();
    await _hwCtrl.close();
  }
}
