import 'dart:async';

import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';

/// 统一设备扫描界面 — 合并旧 4 个 Discover Screen。
/// Unified scanner screen that supports BLE, Classic BT, Network, and USB.
///
/// 迁移自: xii_bluetooth_discover_screen (BLE) +
///         xii_bluetooth_serial_discover_screen (SPP) +
///         xii_network_discover_screen (TCP)
class KoiScannerScreen extends StatefulWidget {
  const KoiScannerScreen({super.key, required this.connectionType});

  /// 扫描类型 (BLE / 经典蓝牙 / 网络 / USB)。
  final KoiConnectionType connectionType;

  @override
  State<KoiScannerScreen> createState() => _KoiScannerScreenState();
}

class _KoiScannerScreenState extends State<KoiScannerScreen> {
  final List<KoiDiscoveredDevice> _devices = [];
  StreamSubscription<KoiDiscoveredDevice>? _scanSub;
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _scanning = true;
      _devices.clear();
    });

    Stream<KoiDiscoveredDevice> stream;

    switch (widget.connectionType) {
      case KoiConnectionType.ble:
        stream = KoiBleScanner().scan();
      case KoiConnectionType.classicBluetooth:
        stream = KoiClassicBtScanner().scan();
      case KoiConnectionType.network:
        stream = KoiNetworkScanner().scan(subnet: '192.168.1');
    }

    _scanSub = stream.listen(
      (device) {
        // 去重
        if (!_devices.any((d) => d.deviceId == device.deviceId)) {
          setState(() => _devices.add(device));
        }
      },
      onDone: () => setState(() => _scanning = false),
      onError: (_) => setState(() => _scanning = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.connectionType) {
      KoiConnectionType.ble => '扫描 BLE 设备',
      KoiConnectionType.classicBluetooth => '扫描经典蓝牙',
      KoiConnectionType.network => '扫描网络打印机',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_scanning)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _startScan),
        ],
      ),
      body: _devices.isEmpty
          ? Center(
              child: _scanning ? const Text('正在扫描...') : const Text('未发现设备'),
            )
          : ListView.separated(
              itemCount: _devices.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final device = _devices[index];
                return ListTile(
                  leading: Icon(_iconForType(widget.connectionType)),
                  title: Text(device.name),
                  subtitle: Text(device.deviceId),
                  trailing: Text(
                    '${device.rssi ?? 0} dBm',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  onTap: () => Navigator.of(context).pop(device),
                );
              },
            ),
    );
  }

  IconData _iconForType(KoiConnectionType type) {
    return switch (type) {
      KoiConnectionType.ble => Icons.bluetooth,
      KoiConnectionType.classicBluetooth => Icons.bluetooth_audio,
      KoiConnectionType.network => Icons.wifi,
    };
  }
}
