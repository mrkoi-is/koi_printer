# koi_printer_connection

The connection layer for the `koi_printer` ecosystem.

## Features

This package acts as an abstraction layer for various printer hardware connections. It shields the upper business layers from the complexities of managing physical connections, MTU chunking, and auto-reconnection logic.

Supported Adapters:
* **`KoiBleAdapter`**: Bluetooth Low Energy (BLE) using `flutter_blue_plus`.
* **`KoiClassicBtAdapter`**: Classic Bluetooth (SPP) using `flutter_bluetooth_serial`.
* **`KoiNetworkAdapter`**: TCP/IP Network printing via raw Dart Sockets.

Supported Scanners:
* **`KoiKeyboardScanner`**: Global hardware keyboard interceptor for physical POS Barcode/QR scanners.
* **`KoiBleScanner` / `KoiClassicBtScanner` / `KoiNetworkScanner`**: Discover nearby printers.

## Usage

This package is intended to be used with `koi_printer`. You do not need to construct adapters manually unless you are building a custom implementation.

```dart
final adapter = KoiBleAdapter();
await adapter.connect(KoiConnectionConfig(deviceId: '00:11:22:33:44:55'));
await adapter.sendChunks([[0x1B, 0x40]]); // ESC @ (Initialize printer)
```
