import 'package:flutter/material.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

void main() {
  runApp(const MaterialApp(home: KoiConnectionExample()));
}

class KoiConnectionExample extends StatefulWidget {
  const KoiConnectionExample({super.key});

  @override
  State<KoiConnectionExample> createState() => _KoiConnectionExampleState();
}

class _KoiConnectionExampleState extends State<KoiConnectionExample> {
  final KoiBleScanner _scanner = KoiBleScanner();
  List<KoiDiscoveredDevice> _devices = [];
  KoiPrinterAdapter? _connection;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _scanner.devices.listen((devices) {
      if (mounted) setState(() => _devices = devices);
    });
    _scanner.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  Future<void> _connect(KoiDiscoveredDevice device) async {
    await _connection?.disconnect();
    _connection = KoiBleAdapter(deviceId: device.id);
    final success = await _connection!.connect();
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koi Printer Connection Demo')),
      body: ListView.builder(
        itemCount: _devices.length,
        itemBuilder: (context, index) {
          final device = _devices[index];
          return ListTile(
            title: Text(device.name),
            subtitle: Text(device.id),
            trailing: ElevatedButton(
              onPressed: () => _connect(device),
              child: const Text('Connect'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _scanner.stopScan : () => _scanner.startScan(),
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
