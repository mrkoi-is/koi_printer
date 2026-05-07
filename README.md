# Koi Printer Ecosystem

Koi Printer Studio is a comprehensive printing solution for the Flutter/Dart ecosystem, featuring:
- Separation of template and commands
- Multi-protocol support (ESC/POS, TSPL, CPCL)
- Multi-connection support (BLE, Classic Bluetooth, Network/TCP)
- Type safety
- Visual Zero-Code Editor

## Packages
- `koi_printer_command`: Print document models, JSON serialization, and command renderers.
- `koi_printer_connection`: Printer connection adapters (BLE, BT, Network, USB).
- `koi_printer`: High-level Printer Manager, job queuing, and template engine.
- `koi_printer_editor`: Visual zero-code editor for designing tickets and labels.

## Development

### Automated Setup (Pre-commit Hook)
To ensure code quality, please configure the local git hooks path so that `dart format` and `flutter analyze` run automatically before every commit.

Run the following command in the project root:

```bash
git config core.hooksPath .githooks
```

## Roadmap
Please refer to [ROADMAP.md](./ROADMAP.md) for current project status, gap analysis, and upcoming milestones.
