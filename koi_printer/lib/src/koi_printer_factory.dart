import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_connection/koi_printer_connection.dart';

/// 打印机工厂 — 根据协议和连接类型自动选择 renderer + adapter。
/// Factory that creates the correct renderer and adapter
/// based on protocol and connection type.
class KoiPrinterFactory {
  const KoiPrinterFactory._(); // coverage:ignore-line

  /// 根据协议创建对应的渲染器。
  static KoiCommandRenderer createRenderer(
    KoiCommandProtocol protocol, {
    KoiQrRenderStrategy qrStrategy = KoiQrRenderStrategy.normal,
  }) {
    return switch (protocol) {
      KoiCommandProtocol.escPos => KoiEscPosRenderer(
        defaultStrategy: qrStrategy,
      ),
      KoiCommandProtocol.tspl => const KoiTsplRenderer(),
      KoiCommandProtocol.cpcl => const KoiCpclRenderer(),
    };
  }

  /// 根据连接类型创建对应的适配器。
  static KoiPrinterAdapter createAdapter(KoiConnectionType type) {
    return switch (type) {
      KoiConnectionType.ble => KoiBleAdapter(),
      KoiConnectionType.classicBluetooth => KoiClassicBtAdapter(),
      KoiConnectionType.network => KoiNetworkAdapter(),
    };
  }
}
