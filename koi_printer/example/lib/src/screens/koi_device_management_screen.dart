import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';

import '../template/koi_templates.dart';
import 'koi_scanner_screen.dart';

/// 设备管理主界面 — 合并旧 XIIDeviceMainScreen + XIIBoundDeviceScreen。
/// 显示已绑定的小票 / 标签打印机, 支持添加 / 删除 / 重连。
class KoiDeviceManagementScreen extends StatefulWidget {
  const KoiDeviceManagementScreen({super.key});

  @override
  State<KoiDeviceManagementScreen> createState() =>
      _KoiDeviceManagementScreenState();
}

// 全局共享状态，仅用于 Example 演示。生产环境应使用 Provider/Redux。
final List<KoiBoundDevice> globalTicketDevices = [];
final List<KoiBoundDevice> globalLabelDevices = [];

class _KoiDeviceManagementScreenState extends State<KoiDeviceManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('打印机管理')),
      body: ListView(
        children: [
          // ── 小票打印机区 ──
          _sectionHeader('小票打印机'),
          if (globalTicketDevices.isEmpty)
            const _EmptyDeviceTile(hint: '未绑定小票打印机'),
          for (final device in globalTicketDevices)
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
          if (globalLabelDevices.isEmpty)
            const _EmptyDeviceTile(hint: '未绑定标签打印机'),
          for (final device in globalLabelDevices)
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

    final bound = KoiBoundDevice(
      name: device.name,
      deviceId: device.deviceId,
      connectionType: type,
    );

    setState(() {
      if (isLabel) {
        globalLabelDevices.add(bound);
      } else {
        globalTicketDevices.add(bound);
      }
    });
  }

  void _removeDevice(KoiBoundDevice device, {required bool isLabel}) {
    setState(() {
      if (isLabel) {
        globalLabelDevices.remove(device);
      } else {
        globalTicketDevices.remove(device);
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
  final KoiBoundDevice device;
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
              final docs = const KoiTestTicketTemplate().build(
                null,
                const KoiPrintConfig(),
              );
              executePrintJob(context, device, docs);
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

class KoiBoundDevice {
  KoiBoundDevice({
    required this.name,
    required this.deviceId,
    required this.connectionType,
  });

  final String name;
  final String deviceId;
  final KoiConnectionType connectionType;
}

Future<void> executePrintJob(
  BuildContext context,
  KoiBoundDevice device,
  List<KoiPrintDocument> docs,
) async {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('正在连接 ${device.name} 并发送打印任务...')));

  try {
    final config = KoiConnectionConfig(
      deviceName: device.name,
      deviceId: device.deviceId,
    );

    final service = KoiPrinterService(
      protocol: KoiCommandProtocol.escPos,
      connectionType: device.connectionType,
    );

    final connected = await service.connect(config);
    if (!connected) {
      throw Exception('设备连接失败');
    }

    for (final doc in docs) {
      final result = await service.print(doc);
      if (result is KoiPrintFailure) {
        throw Exception(result.error);
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await service.disconnect();

    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('发送成功!')));
    }
  } on Object catch (e, st) {
    debugPrint('==== 打印失败详细日志 ====');
    debugPrint('Error: $e');
    debugPrint('StackTrace: $st');
    debugPrint('==========================');

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打印失败: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
