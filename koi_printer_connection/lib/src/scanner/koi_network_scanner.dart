import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:koi_printer_connection/src/model/koi_connection_types.dart';
import 'package:koi_printer_connection/src/model/koi_discovered_device.dart';

/// 网络打印机扫描器 — 基于 TCP 端口探测。
/// 扫描局域网内常用打印机端口 (9100) 来发现网络打印机。
class KoiNetworkScanner {
  /// 扫描局域网内的打印机。
  ///
  /// [subnet] 子网前缀, 如 '192.168.1'。
  /// [port] 扫描端口, 默认 9100 (RAW 打印端口)。
  /// [timeout] 每台主机的连接超时。
  Stream<KoiDiscoveredDevice> scan({
    required String subnet,
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 500),
    int startIp = 1,
    int endIp = 254,
  }) {
    final controller = StreamController<KoiDiscoveredDevice>();

    Future<void> scanAll() async {
      final futures = <Future<void>>[];
      for (var i = startIp; i <= endIp; i++) {
        final host = '$subnet.$i';
        futures.add(_probe(host, port, timeout, controller));
      }
      await Future.wait(futures);
      if (!controller.isClosed) controller.close();
    }

    controller.onListen = () => scanAll();

    return controller.stream;
  }

  Future<void> _probe(
    String host,
    int port,
    Duration timeout,
    StreamController<KoiDiscoveredDevice> controller,
  ) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      await socket.close();

      if (!controller.isClosed) {
        controller.add(
          KoiDiscoveredDevice(
            name: 'Network Printer ($host)',
            deviceId: '$host:$port',
            connectionType: KoiConnectionType.network,
          ),
        );
      }
    } catch (_) {
      // 连接超时或拒绝 → 该 IP 无打印机
    }
  }

  /// 停止扫描 (网络扫描无法主动取消, 等待超时)。
  Future<void> stopScan() async {
    debugPrint(
      'KoiNetworkScanner: scan will complete after all probes finish.',
    );
  }
}
