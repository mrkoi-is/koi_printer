import 'dart:async';
import 'package:flutter/material.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

/// Application entry point.
void main() {
  runApp(const MaterialApp(home: KoiConnectionExample()));
}

/// A simple connection example widget.
class KoiConnectionExample extends StatefulWidget {
  const KoiConnectionExample({super.key});

  @override
  State<KoiConnectionExample> createState() => _KoiConnectionExampleState();
}

class _KoiConnectionExampleState extends State<KoiConnectionExample> {
  final KoiBleScanner _scanner = KoiBleScanner();
  final List<KoiDiscoveredDevice> _devices = [];
  KoiPrinterAdapter? _connection;
  bool _isScanning = false;
  StreamSubscription<KoiDiscoveredDevice>? _scanSub;

  void _startScan() {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });

    _scanSub?.cancel();
    _scanSub = _scanner
        .scan(timeout: const Duration(seconds: 10))
        .listen(
          (device) {
            setState(() {
              if (!_devices.any((d) => d.deviceId == device.deviceId)) {
                _devices.add(device);
              }
            });
          },
          onDone: () {
            if (mounted) setState(() => _isScanning = false);
          },
        );
  }

  void _stopScan() {
    _scanSub?.cancel();
    _scanner.stopScan().ignore();
    setState(() => _isScanning = false);
  }

  Future<void> _connect(KoiDiscoveredDevice device) async {
    await _connection?.disconnect();
    _connection = KoiBleAdapter();
    final success = await _connection!.connect(
      KoiConnectionConfig(deviceId: device.deviceId, deviceName: device.name),
    );
    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connected to ${device.name}')));
    }
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _connection?.disconnect().ignore();
    super.dispose();
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
            subtitle: Text(device.deviceId),
            trailing: ElevatedButton(
              onPressed: () => _connect(device),
              child: const Text('Connect'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? _stopScan : _startScan,
        child: Icon(_isScanning ? Icons.stop : Icons.search),
      ),
    );
  }
}
