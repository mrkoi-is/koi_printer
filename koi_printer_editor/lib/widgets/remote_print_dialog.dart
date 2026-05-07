import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class RemotePrintDialog extends StatefulWidget {
  const RemotePrintDialog({super.key});

  @override
  State<RemotePrintDialog> createState() => _RemotePrintDialogState();
}

class _RemotePrintDialogState extends State<RemotePrintDialog> {
  final TextEditingController _ipController = TextEditingController();
  bool _isConnecting = false;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString('koi_last_remote_ip') ?? '';
    if (savedIp.isNotEmpty && mounted) {
      _ipController.text = savedIp;
    }
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('koi_last_remote_ip', ip);
  }

  void _connectAndPrint() async {
    final ipText = _ipController.text.trim();
    if (ipText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入手机端显示的 WebSocket IP 地址')),
      );
      return;
    }

    // Check if starts with ws:// or wss://, if not, add it
    final wsUrl = ipText.startsWith('ws') ? ipText : 'ws://$ipText';

    setState(() {
      _isConnecting = true;
    });

    try {
      await _saveIp(ipText);
      if (!mounted) return;
      final state = context.read<EditorState>();

      final manifest = KoiTemplateManifest(
        id: state.currentManifestId.isNotEmpty
            ? state.currentManifestId
            : 'remote_${DateTime.now().millisecondsSinceEpoch}',
        name: state.currentManifestName.isNotEmpty
            ? state.currentManifestName
            : 'Remote Print',
        category: state.currentManifestCategory,
        description: state.currentManifestDescription,
        document: state.document,
        schema: state.schema,
        mockData: state.mockData,
      );

      final payload = jsonEncode({
        'type': 'PRINT_PREVIEW',
        'manifest': manifest.toJson(),
      });

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Wait for connection to establish and send payload
      await _channel!.ready;
      _channel!.sink.add(payload);

      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('发送成功！请在手机端查看打印结果。')));
      _channel!.sink.close();
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('连接失败，请检查 IP 和手机端是否在同一个局域网。错误详情: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('真机远程打样 (局域网)'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '请在手机端 App 中打开“接收打样”功能，并将屏幕上显示的 WebSocket 局域网地址填入下方：',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: '手机端局域网地址',
                hintText: '例如: ws://192.168.1.50:8080',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              enabled: !_isConnecting,
            ),
            if (_isConnecting) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '正在连接并发送打样数据...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton.icon(
          onPressed: _isConnecting ? null : () => _connectAndPrint(),
          icon: const Icon(Icons.send_to_mobile, size: 18),
          label: const Text('发送打样'),
        ),
      ],
    );
  }
}
