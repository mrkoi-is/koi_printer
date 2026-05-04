import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';

import '../template/koi_templates.dart';
import 'koi_scanner_screen.dart';
import 'package:provider/provider.dart';

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final storage = context.read<KoiPrinterStorage>();
      final ticket = storage.getTicketPrinter();
      final label = storage.getLabelPrinter();
      
      setState(() {
        if (ticket != null && globalTicketDevices.isEmpty) {
          globalTicketDevices.add(KoiBoundDevice(
            name: ticket.name,
            deviceId: ticket.address,
            connectionType: ticket.connectionType,
          ));
        }
        if (label != null && globalLabelDevices.isEmpty) {
          globalLabelDevices.add(KoiBoundDevice(
            name: label.name,
            deviceId: label.address,
            connectionType: label.connectionType,
          ));
        }
      });
    });
  }

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
              isLabel: false,
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
              isLabel: true,
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
      final info = KoiDeviceInfo(
        name: bound.name,
        address: bound.deviceId,
        connectionType: bound.connectionType,
      );
      if (isLabel) {
        globalLabelDevices.clear(); // Only allow 1 label printer in example
        globalLabelDevices.add(bound);
        context.read<KoiPrinterStorage>().saveLabelPrinter(info);
      } else {
        globalTicketDevices.clear(); // Only allow 1 ticket printer in example
        globalTicketDevices.add(bound);
        context.read<KoiPrinterStorage>().saveTicketPrinter(info);
      }
    });
  }

  void _removeDevice(KoiBoundDevice device, {required bool isLabel}) {
    setState(() {
      if (isLabel) {
        globalLabelDevices.remove(device);
        context.read<KoiPrinterStorage>().saveLabelPrinter(null);
      } else {
        globalTicketDevices.remove(device);
        context.read<KoiPrinterStorage>().saveTicketPrinter(null);
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
  const _DeviceTile({required this.device, required this.onDelete, required this.isLabel});
  final KoiBoundDevice device;
  final VoidCallback onDelete;
  final bool isLabel;

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<KoiPrinterManager>();
    final adapter = isLabel ? manager.labelAdapter : manager.ticketAdapter;
    
    return StreamBuilder<KoiConnectionState>(
      stream: adapter?.stateStream ?? Stream.value(KoiConnectionState.disconnected),
      initialData: adapter?.state ?? KoiConnectionState.disconnected,
      builder: (context, snapshot) {
        final state = snapshot.data ?? KoiConnectionState.disconnected;
        final isConnected = state == KoiConnectionState.ready;
        final statusText = isConnected ? '🟢 已连接' : (state == KoiConnectionState.connecting ? '🟡 连接中...' : '🔴 未连接');

        return ListTile(
          leading: Icon(_iconForType(device.connectionType), color: isConnected ? Colors.blue : Colors.grey),
          title: Text(device.name),
          subtitle: Text('${device.deviceId} - $statusText'),
          trailing: PopupMenuButton<String>(
            onSelected: (action) {
              switch (action) {
                case 'delete':
                  onDelete();
                case 'test':
                  final testConfig = const KoiPrintConfig();
                  final docs = isLabel
                      ? const KoiSenderLabelTemplate().build({}, testConfig)
                      : const KoiTestTicketTemplate().build(null, testConfig);
                  executePrintJob(context, device, docs, isLabel, config: testConfig);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'test', child: Text('测试打印')),
              PopupMenuItem(value: 'delete', child: Text('删除')),
            ],
          ),
        );
      }
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
  bool isLabel, {
  KoiPrintConfig config = const KoiPrintConfig(),
}) async {
  final manager = context.read<KoiPrinterManager>();
  
  final state = isLabel ? manager.labelState : manager.ticketState;
  
  if (state != KoiConnectionState.ready) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('打印机未连接，已加入后台队列，一旦上线将自动打出...')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已发送打印任务')),
    );
  }

  try {
    for (int copyIndex = 1; copyIndex <= config.copies; copyIndex++) {
      for (final doc in docs) {
        KoiPrintDocument modifiedDoc = doc;

        if (config.copies > 1) {
          final pageText = '=== 批量测试: 第 $copyIndex / ${config.copies} 份 ===';

          if (doc is KoiTicketDocument) {
            final elements = List<KoiTicketElement>.from(doc.elements);
            final last = elements.isNotEmpty ? elements.last : null;
            final injection = [
              const KoiTextElement(text: '\n'),
              KoiTextElement(text: pageText, align: KoiAlign.center, bold: true),
              const KoiTextElement(text: '\n'),
            ];

            if (last is KoiCutElement) {
              elements.insertAll(elements.length - 1, injection);
            } else {
              elements.addAll(injection);
            }

            modifiedDoc = KoiTicketDocument(
              name: doc.name,
              paperSize: doc.paperSize,
              codePage: doc.codePage,
              elements: elements,
            );
          } else if (doc is KoiLabelDocument) {
            modifiedDoc = KoiLabelDocument(
              name: doc.name,
              elements: [
                ...doc.elements,
                KoiLabelTextElement(
                  text: pageText,
                  x: 10,
                  y: 10,
                ),
              ],
            );
          }
        }

        final singleCopyConfig = config.copyWith(copies: 1);

        if (isLabel) {
          await manager.printLabelDocument(modifiedDoc as KoiLabelDocument, config: singleCopyConfig);
        } else {
          await manager.printTicketDocument(modifiedDoc as KoiTicketDocument, config: singleCopyConfig);
        }
      }
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
