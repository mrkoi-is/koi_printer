import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:koi_printer_connection/src/adapter/koi_printer_adapter.dart';
import 'package:koi_printer_connection/src/model/koi_connection_config.dart';
import 'package:koi_printer_connection/src/model/koi_connection_policy.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';

/// BLE 适配器 — 使用 flutter_blue_plus。
/// BLE adapter implementation using flutter_blue_plus.
///
/// 功能:
/// - 自动发现 Service / Characteristic
/// - MTU 感知分块发送 (旧 writeBytes 逻辑)
/// - 连接状态监听
///
/// 来源: 旧 XIIBluetoothPrinter (349 LOC) 的核心逻辑。
class KoiBleAdapter implements KoiPrinterAdapter {
  KoiBleAdapter();

  BluetoothDevice? _device;
  BluetoothCharacteristic? _characteristic;
  KoiConnectionConfig? _config;
  int _mtu = 512;

  final StreamController<KoiConnectionState> _stateController =
      StreamController<KoiConnectionState>.broadcast();

  KoiConnectionState _state = KoiConnectionState.disconnected;

  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<int>? _mtuSub;

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
  KoiConnectionPolicy get policy => KoiConnectionPolicy.aggressive;

  @override
  KoiConnectionType get connectionType => KoiConnectionType.ble;

  @override
  KoiConnectionConfig? get config => _config;

  @override
  bool get isReady => _state == KoiConnectionState.ready;

  @override
  Future<KoiPrinterHardwareState> queryHardwareState() async {
    // TODO(maxlee): 发送 DLE EOT 状态查询指令并解析响应。
    return KoiPrinterHardwareState.unknown;
  }

  @override
  Future<bool> connect(KoiConnectionConfig config) async {
    _config = config;
    _updateState(KoiConnectionState.connecting);

    try {
      _device = BluetoothDevice.fromId(config.deviceId);
      _mtu = config.mtu;

      // 监听连接状态变化
      _connectionSub = _device!.connectionState.listen((bleState) async {
        if (bleState == BluetoothConnectionState.connected) {
          if (_state != KoiConnectionState.ready) {
            await _discoverServices();
          }
        } else if (bleState == BluetoothConnectionState.disconnected) {
          _updateState(KoiConnectionState.disconnected);
          _characteristic = null;
        }
      });

      // 监听 MTU 变化
      _mtuSub = _device!.mtu.listen((mtu) {
        if (mtu > 0) {
          _mtu = mtu;
          debugPrint('KoiBleAdapter: MTU updated to $_mtu');
        }
      });

      try {
        // 先确保断开之前的僵尸连接，预防 Android GATT 133 错误
        await _device!.disconnect();
      } on Object catch (e, st) {
        debugPrint('KoiBleAdapter: Cleanup disconnect error: $e\n$st');
      }

      try {
        await _device!.connect(
          timeout: config.connectionTimeout,
          autoConnect: config.autoReconnect,
          mtu: config.mtu,
        );
      } on Object catch (e) {
        final err = e.toString();
        if (err.contains('133') || err.contains('ANDROID_SPECIFIC_ERROR')) {
          debugPrint('KoiBleAdapter: caught 133 error, retrying in 500ms...');
          await Future<void>.delayed(const Duration(milliseconds: 500));
          await _device!.connect(
            timeout: config.connectionTimeout,
            autoConnect: config.autoReconnect,
            mtu: config.mtu,
          );
        } else {
          rethrow;
        }
      }
      // 等待到底层连接成功且发现服务完成 (isReady)
      if (!isReady) {
        try {
          await stateStream
              .firstWhere(
                (s) =>
                    s == KoiConnectionState.ready ||
                    s == KoiConnectionState.disconnected ||
                    (s == KoiConnectionState.connected &&
                        _characteristic == null),
              )
              .timeout(const Duration(seconds: 15));
        } on Object catch (e, st) {
          // 超时或错误
          debugPrint('KoiBleAdapter: Wait for ready timeout/error: $e\n$st');
        }
      }

      return isReady;
    } on Object catch (e) {
      debugPrint('KoiBleAdapter: connect error: $e');
      _updateState(KoiConnectionState.disconnected);
      return false;
    }
  }

  /// 发现服务和特征。
  Future<void> _discoverServices() async {
    _updateState(KoiConnectionState.discovering);

    try {
      final services = await _device!.discoverServices();

      final hasConfigUuid =
          _config?.serviceUuid != null || _config?.characteristicUuid != null;

      if (hasConfigUuid) {
        for (final service in services) {
          // 匹配指定 service UUID
          if (_config?.serviceUuid != null &&
              service.uuid.toString() != _config!.serviceUuid) {
            continue;
          }

          for (final c in service.characteristics) {
            // 查找可写特征
            if (c.properties.write || c.properties.writeWithoutResponse) {
              // 如果有指定 characteristic UUID, 需要匹配
              if (_config?.characteristicUuid != null &&
                  c.uuid.toString() != _config!.characteristicUuid) {
                continue;
              }
              _characteristic = c;
              _updateState(KoiConnectionState.ready);
              return;
            }
          }
        }
      }

      // 未找到匹配特征 — 尝试使用第一个可写特征 (跳过标准的系统服务)
      for (final service in services) {
        if (_isSystemUuid(service.uuid.toString())) {
          continue;
        }

        for (final c in service.characteristics) {
          if (_isSystemUuid(c.uuid.toString())) {
            continue;
          }

          if (c.properties.write || c.properties.writeWithoutResponse) {
            _characteristic = c;
            _updateState(KoiConnectionState.ready);
            return;
          }
        }
      }

      debugPrint('KoiBleAdapter: No writable characteristic found');
      _updateState(KoiConnectionState.connected);
    } on Object catch (e) {
      debugPrint('KoiBleAdapter: discoverServices error: $e');
      _updateState(KoiConnectionState.connected);
    }
  }

  /// 判断是否为标准的 BLE SIG 系统服务/特征 (如 GAP, GATT, Device Info)
  /// 避免将打印数据误发到 Device Name (2A00) 等特征上。
  bool _isSystemUuid(String uuid) {
    final lower = uuid.toLowerCase();
    // 检查是否基于标准蓝牙 BASE_UUID
    if (lower.endsWith('-0000-1000-8000-00805f9b34fb')) {
      // 18xx 对应系统 Service (如 1800 GAP, 180A Device Information)
      if (lower.startsWith('000018')) return true;
      // 2Axx 对应系统 Characteristic (如 2A00 Device Name)
      if (lower.startsWith('00002a')) return true;
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _device?.disconnect();
    } on Object catch (e) {
      debugPrint('KoiBleAdapter: disconnect error: $e');
    }
    _updateState(KoiConnectionState.disconnected);
  }

  @override
  Future<void> sendChunks(List<List<int>> chunks) async {
    if (_characteristic == null) {
      throw StateError(
        'BLE characteristic not discovered. Call connect first.',
      );
    }

    for (final chunk in chunks) {
      await _writeWithMtuChunking(chunk);
    }
  }

  /// 按 MTU 分块写入。
  /// 来源: 旧 XIIBluetoothPrinter.writeBytes() 的核心逻辑。
  Future<void> _writeWithMtuChunking(List<int> data) async {
    // BLE 实际可写大小 = MTU - 3 (ATT 头部)
    final chunkSize = _mtu - 3;
    if (chunkSize <= 0) return;

    for (var offset = 0; offset < data.length; offset += chunkSize) {
      final end =
          (offset + chunkSize > data.length) ? data.length : offset + chunkSize;
      final piece = data.sublist(offset, end);

      try {
        await _characteristic!.write(
          piece,
          withoutResponse: _characteristic!.properties.writeWithoutResponse,
        );
        // 增加流量控制: 如果是 withoutResponse，连续的高速突发写入极易导致打印机底层 BLE 芯片 UART 缓冲溢出而断开连接。
        if (_characteristic!.properties.writeWithoutResponse) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      } on Object catch (e) {
        debugPrint('KoiBleAdapter: write error at offset $offset: $e');
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
    await _connectionSub?.cancel();
    await _mtuSub?.cancel();
    await _stateController.close();
    try {
      await _device?.disconnect();
    } on Object catch (e, st) {
      // 忽略 dispose 时的断连错误。
      debugPrint('KoiBleAdapter: Dispose disconnect error: $e\n$st');
    }
  }
}
