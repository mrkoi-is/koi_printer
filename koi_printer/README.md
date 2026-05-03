# koi_printer 生态系统 (Ecosystem)

全新架构的 V4 打印机聚合防腐层门面包。彻底替代旧版 `xii_bluetooth`。

## 架构组成

- **`koi_printer_command`** (纯 Dart): 打印指令集、数据模型 (`KoiPrintElement` / `KoiPrintDocument`)、以及各协议渲染器 (`ESC/POS`, `TSPL`, `CPCL`) 和 JSON 序列化功能。
- **`koi_printer_connection`** (Plugin): 硬件通信聚合层，支持蓝牙 (`KoiBleAdapter`, `KoiClassicBtAdapter`)、局域网 (`KoiNetworkAdapter`) 以及全局扫码枪键盘监听 (`KoiKeyboardScanner`)，自带自动分发大包延迟与心跳重连。
- **`koi_printer`** (当前包): 面向业务开发的终极门面。

## 核心能力 (Phase 1-6)

- [x] **双机独立管理**: 无论您连接多少台设备，体系内支持 `ticket` (小票) 与 `label` (面单) 两个通道独立执行与管理。
- [x] **模板驱动 (`KoiPrintTemplate`)**: 支持直接构建复杂的响应式联单(如客户联/存根联)和 1D/2D 面单，全部采用 `sealed class` 隔离。
- [x] **设备能力库 `PrinterProfile`**: 内置市面主流设备 (芯烨/芝科/佳博/通用等) 能力模型，自动适配最佳打印指令和速率 `DelayProfile` 曲线。
- [x] **所见即所得的预览 `KoiPreviewRenderer`**: 流式结构 (`ESC`) 和绝对坐标空间结构 (`TSPL/CPCL`) 可以在屏幕上以 Flutter Widget 1:1 展示。
- [x] **100% 测试覆盖**: 逾 60 项核心边缘覆盖单元测试，保障金融与仓储等级稳定性。

## 如何使用 (Quick Start)

通过全新的 JSON 动态解析方案，您无需编写任何 Flutter UI 代码即可下发和更新小票排版。

### 1. 动态模板解析与打印

这是最强大的用法：后台直接下发 JSON，App 仅做渲染壳。

```dart
// 1. 获取服务器下发的 JSON 模板 (可以实现在线 OTA 更新排版)
final String jsonStr = await fetchTemplateFromJson('SENDER_TICKET');
final KoiTicketDocument templateDoc = koiPrintDocumentFromJsonString(jsonStr) as KoiTicketDocument;

// 2. 将真实业务数据喂给模板引擎，替换 {{waybillNo}} 等占位符
final engine = KoiTemplateEngine();
final KoiTicketDocument finalDoc = engine.expandTicket(templateDoc, {
  "waybillNo": "YT123456",
  "items": [{"name": "商品A", "count": 2}]
});

// 3. 安全打印并进队列
await manager.printDocument(finalDoc);
```

### 扫描并连接

```dart
// 1. 初始化存储 (用于记录绑定过的硬件设备)
final storage = KoiPrinterStorage();
await storage.init();

// 2. 注入建立管理器
final manager = KoiPrinterManager(
  storage: storage,
  ticketAdapter: KoiBleAdapter(), 
  labelAdapter: KoiBleAdapter(),
);
await manager.init();

// 3. 扫描并自动连接 (会自动根据 PrinterProfile 连接到对应通道)
// 提供设备地址和类型进行绑定:
await manager.connectTicketPrinter('XX:XX:XX:XX:XX', KoiConnectionType.ble);
```

### 3. 所见即所得的预览

开发和调试时，可以直接把文档渲染到屏幕上：

```dart
// 在 Widget 的 build 方法中直接预览
@override
Widget build(BuildContext context) {
  return KoiPreviewRenderer.build(finalDoc, paperWidthPx: 380);
}
```

## TMS 系统升级指南 (Migration from xii_bluetooth)

1. **依赖替换**: 在 `pubspec.yaml` 中移除 `xii_bluetooth`，引入 `koi_printer` 及其对应生态包。
2. **初始化方式替换**:
    旧: `XIIPrinterService.init()` (单例)
    新: 实例化 `KoiPrinterStorage` 和 `KoiPrinterManager` 放入生命周期（例如 Riverpod `Provider`）。
3. **设置项升级**:
    旧: `XIIPrintSettings()`
    新: `KoiUserPreferences()` 并在打印时传入 `KoiPrintConfig` (包含全局参数配置)。
4. **小票创建方式颠覆**:
    旧: 拼接使用 `List<int> bytes = []`、`generator.text()`。
    新: 使用声明式对象 `KoiPrintDocument.ticket(elements: [ KoiTextElement(text: 'ABC') ])`。通过 `KoiPreviewRenderer.build()` 可直接上屏看效果。
