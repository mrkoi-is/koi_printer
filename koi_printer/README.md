# koi_printer 生态系统 (Ecosystem)

全新架构的 V4 打印机聚合防腐层门面包。彻底替代旧版 `xii_bluetooth`。

## 架构组成

- **`koi_printer_command`** (纯 Dart): 打印指令集、数据模型 (`KoiPrintElement` / `KoiPrintDocument`)、以及各协议渲染器 (`ESC/POS`, `TSPL`, `CPCL`) 和 JSON 序列化功能。
- **`koi_printer_connection`** (Plugin): 硬件通信聚合层，支持蓝牙 (`KoiBleAdapter`, `KoiClassicBtAdapter`)、局域网 (`KoiNetworkAdapter`) 以及 USB (`KoiUsbAdapter`)，自带自动分发大包延迟与心跳重连。
- **`koi_printer`** (当前包): 面向业务开发的终极门面。

## 核心能力 (Phase 1-6)

- [x] **双机独立管理**: 无论您连接多少台设备，体系内支持 `ticket` (小票) 与 `label` (面单) 两个通道独立执行与管理。
- [x] **模板驱动 (`KoiPrintTemplate`)**: 支持直接构建复杂的响应式联单(如客户联/存根联)和 1D/2D 面单，全部采用 `sealed class` 隔离。
- [x] **设备能力库 `PrinterProfile`**: 内置市面主流设备 (芯烨/芝科/佳博/通用等) 能力模型，自动适配最佳打印指令和速率 `DelayProfile` 曲线。
- [x] **所见即所得的预览 `KoiPreviewRenderer`**: 流式结构 (`ESC`) 和绝对坐标空间结构 (`TSPL/CPCL`) 可以在屏幕上以 Flutter Widget 1:1 展示。
- [x] **100% 测试覆盖**: 逾 60 项核心边缘覆盖单元测试，保障金融与仓储等级稳定性。

## 如何使用 (Quick Start)

参考 `example/` 工程。示例应用内直接封装了 TMS 系统的以下 9 个业务实体模板及预览编辑器：
- `KoiSenderTicketTemplate` (多联)
- `KoiReceiverTicketTemplate`
- `KoiDeliveryNoteTemplate` / `KoiDepositTemplate` / `KoiFinanceTicketTemplate`
- `KoiSenderLabelTemplate` (支持 6 种布局样式)
- ...等

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

### 打印业务单据

```dart
final data = { "waybillNo": "YT1234", "items": [{"name":"衣服","count":1}] };

// 业务模板和独立配置
final template = KoiSenderTicketTemplate();
final config = KoiPrintConfig(copies: 2, cutBehavior: KoiCutBehavior.cutPerCopy);

// 丢入管理器，安全执行 (自动处理重试与拥塞)
await manager.printUsingTemplate<Map<String, dynamic>>(
  data, 
  template,
  config: config,
);
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
