import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';

import 'koi_scanner_screen.dart';

/// 设备管理主界面 — 合并旧 XIIDeviceMainScreen + XIIBoundDeviceScreen。
/// 显示已绑定的小票 / 标签打印机, 支持添加 / 删除 / 重连。
class KoiDeviceManagementScreen extends StatefulWidget {
  const KoiDeviceManagementScreen({super.key});

  @override
  State<KoiDeviceManagementScreen> createState() =>
      _KoiDeviceManagementScreenState();
}

class _KoiDeviceManagementScreenState extends State<KoiDeviceManagementScreen> {
  // 模拟已绑定设备列表 (生产环境从 KoiPrinterStorage 读取)
  final List<_BoundDevice> _ticketDevices = [];
  final List<_BoundDevice> _labelDevices = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打印机管理')),
      body: ListView(
        children: [
          // ── 小票打印机区 ──
          _sectionHeader('小票打印机'),
          if (_ticketDevices.isEmpty) const _EmptyDeviceTile(hint: '未绑定小票打印机'),
          for (final device in _ticketDevices)
            _DeviceTile(
              device: device,
              onDelete: () => _removeDevice(device, isLabel: false),
            ),
          _AddDeviceButton(
            onSelected: (type) => _addDevice(type, isLabel: false),
          ),

          const Divider(height: 32),

          // ── 标签打印机区 ──
          _sectionHeader('标签打印机'),
          if (_labelDevices.isEmpty) const _EmptyDeviceTile(hint: '未绑定标签打印机'),
          for (final device in _labelDevices)
            _DeviceTile(
              device: device,
              onDelete: () => _removeDevice(device, isLabel: true),
            ),
          _AddDeviceButton(
            onSelected: (type) => _addDevice(type, isLabel: true),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _addDevice(
    KoiConnectionType type, {
    required bool isLabel,
  }) async {
    final device = await Navigator.of(context).push<KoiDiscoveredDevice>(
      MaterialPageRoute(builder: (_) => KoiScannerScreen(connectionType: type)),
    );

    if (device == null || !mounted) return;

    final bound = _BoundDevice(
      name: device.name,
      deviceId: device.deviceId,
      connectionType: type,
    );

    setState(() {
      if (isLabel) {
        _labelDevices.add(bound);
      } else {
        _ticketDevices.add(bound);
      }
    });
  }

  void _removeDevice(_BoundDevice device, {required bool isLabel}) {
    setState(() {
      if (isLabel) {
        _labelDevices.remove(device);
      } else {
        _ticketDevices.remove(device);
      }
    });
  }
}

// ── 辅助 Widget ──

class _EmptyDeviceTile extends StatelessWidget {
  const _EmptyDeviceTile({required this.hint});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.print_disabled, color: Colors.grey),
      title: Text(hint, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onDelete});
  final _BoundDevice device;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_iconForType(device.connectionType)),
      title: Text(device.name),
      subtitle: Text(device.deviceId),
      trailing: PopupMenuButton<String>(
        onSelected: (action) {
          switch (action) {
            case 'delete':
              onDelete();
            case 'test':
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('发送测试页...')));
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'test', child: Text('测试打印')),
          PopupMenuItem(value: 'delete', child: Text('删除')),
        ],
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

class _AddDeviceButton extends StatelessWidget {
  const _AddDeviceButton({required this.onSelected});
  final ValueChanged<KoiConnectionType> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
      title: const Text('添加打印机'),
      onTap: () => _showTypeSheet(context),
    );
  }

  void _showTypeSheet(BuildContext ctx) {
    showModalBottomSheet<void>(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bluetooth),
              title: const Text('蓝牙 (BLE)'),
              onTap: () {
                Navigator.pop(ctx);
                onSelected(KoiConnectionType.ble);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bluetooth_audio),
              title: const Text('经典蓝牙 (SPP)'),
              onTap: () {
                Navigator.pop(ctx);
                onSelected(KoiConnectionType.classicBluetooth);
              },
            ),
            ListTile(
              leading: const Icon(Icons.wifi),
              title: const Text('网络 (TCP/IP)'),
              onTap: () {
                Navigator.pop(ctx);
                onSelected(KoiConnectionType.network);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── 数据模型 ──

class _BoundDevice {
  _BoundDevice({
    required this.name,
    required this.deviceId,
    required this.connectionType,
  });

  final String name;
  final String deviceId;
  final KoiConnectionType connectionType;
}
