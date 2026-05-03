# koi_printer_command

The low-level instruction set and rendering engine for the `koi_printer` ecosystem.

## Features

This package provides a pure Dart abstraction over various printer protocols. It is completely decoupled from any connection or physical transport layer, meaning it can be run on Flutter apps, CLI tools, or Dart backend servers.

Supported Protocols:
* **ESC/POS**: Standard receipt thermal printers (e.g., Xprinter, Gprinter).
* **TSPL**: Standard label printers (e.g., TSC, Xprinter Label).
* **CPCL**: Mobile label printers (e.g., Zebra, HPRT).

## Architecture

1. **`KoiPrintElement`**: Abstract UI building blocks (Text, Barcode, QrCode, Image).
2. **`KoiPrintDocument`**: A collection of elements defining a complete ticket or label.
3. **`KoiCommandRenderer`**: Translates a `KoiPrintDocument` into a raw `List<int>` byte stream tailored for a specific protocol.

## Usage

```dart
final document = KoiPrintDocument.ticket(elements: [
  KoiTextElement(text: 'Hello World', bold: true, size: KoiTextSize.size2),
  KoiCutElement(),
]);

final renderer = KoiEscPosRenderer();
final bytes = await renderer.render(document);
// Send bytes to printer adapter...
```
