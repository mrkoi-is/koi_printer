# Sprint 2 执行计划 — Phase 6 完成
# Execution Plan for Gemini

> **项目路径**: `/Users/max/Workspace/SourceCode/mrkoi/koit_printer`
> **目标**: 补齐缺失模板 + 配置 CI/CD + 完善文档
> **验收人**: Antigravity (Claude)
> **完成后**: `git commit` + `git push origin main`

---

## 背景 / Context

这是一个 Flutter 打印机 SDK monorepo，包含 3 个包：

```
koit_printer/
├── koi_printer_command/     # 纯 Dart — 打印文档模型 + ESC/POS, TSPL, CPCL 渲染器
├── koi_printer_connection/  # Flutter — BLE, 经典蓝牙, TCP/IP, USB 连接适配器
└── koi_printer/             # Flutter — 门面包 (管理器, 模板引擎, 预览, 配置)
    └── example/             # 示例应用 (4个屏幕 + 业务模板)
```

**当前状态 (Sprint 1 已完成)**:
- 314 单元测试全绿 ✅
- lint: 71 → 26 issues ✅
- GitHub: https://github.com/mrkoi-is/koi_printer ✅

---

## Task 1: GitHub Actions CI/CD

### 目标
创建 `.github/workflows/ci.yml`，实现每次 push/PR 自动运行三包分析和测试。

### 文件路径
```
/Users/max/Workspace/SourceCode/mrkoi/koit_printer/.github/workflows/ci.yml
```

### 完整文件内容

```yaml
name: CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  analyze_and_test:
    name: Analyze & Test
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.29.x'
          channel: 'stable'
          cache: true

      # ── koi_printer_command (纯 Dart) ──────────────────────────
      - name: pub get — koi_printer_command
        run: dart pub get
        working-directory: koi_printer_command

      - name: analyze — koi_printer_command
        run: dart analyze --fatal-infos
        working-directory: koi_printer_command

      - name: test — koi_printer_command
        run: dart test
        working-directory: koi_printer_command

      # ── koi_printer_connection ─────────────────────────────────
      - name: pub get — koi_printer_connection
        run: flutter pub get
        working-directory: koi_printer_connection

      - name: analyze — koi_printer_connection
        run: flutter analyze
        working-directory: koi_printer_connection

      - name: test — koi_printer_connection
        run: flutter test
        working-directory: koi_printer_connection

      # ── koi_printer ────────────────────────────────────────────
      - name: pub get — koi_printer
        run: flutter pub get
        working-directory: koi_printer

      - name: analyze — koi_printer
        run: flutter analyze
        working-directory: koi_printer

      - name: test — koi_printer
        run: flutter test
        working-directory: koi_printer
```

> [!IMPORTANT]
> `koi_printer_command` 使用 `dart analyze --fatal-infos` (会因 info 失败)。
> 如果 26 个 info 导致 CI 失败，改为 `dart analyze` (不加 `--fatal-infos`)。

### 验收标准
- [ ] 文件存在于 `.github/workflows/ci.yml`
- [ ] push 到 GitHub 后 Actions tab 显示绿色 ✅

---

## Task 2: 补齐 4 个缺失模板

### 背景
example 应用中现有 6 个业务模板。需补齐：
1. `KoiRefundTicketTemplate` — 退票 (小票)
2. `KoiPaymentRequestTemplate` — 交款申请 (小票)
3. `SimpleReceiptTemplate` — 简单收据 Demo (新用户快速上手)
4. `SimpleLabelTemplate` — 简单标签 Demo

### 参考: 现有模板结构

查看现有模板了解接口规范:
```
koi_printer/example/lib/src/template/ticket/koi_sender_ticket_template.dart
koi_printer/example/lib/src/template/label/koi_sender_label_template.dart
```

**所有模板必须**:
- 继承 `KoiPrintTemplate` (导入自 `package:koi_printer/koi_printer.dart`)
- 实现 `KoiPrintDocument build(Map<String, dynamic> data)` 方法
- 返回 `KoiTicketDocument` (小票) 或 `KoiLabelDocument` (标签)
- 使用 `{{variable}}` 占位符配合模板引擎

### 2.1 退票模板

**文件路径**: `koi_printer/example/lib/src/template/ticket/koi_refund_ticket_template.dart`

```dart
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 退票模板。
/// 打印退款/退货小票，含退款金额和原单号。
class KoiRefundTicketTemplate extends KoiPrintTemplate {
  const KoiRefundTicketTemplate();

  @override
  String get templateId => 'refund_ticket';

  @override
  String get displayName => '退票';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiTicketDocument(
      elements: [
        // 标题
        const KoiTextElement(
          text: '退  款  凭  证',
          align: KoiTextAlign.center,
          bold: true,
          size: KoiTextSize.size2,
        ),
        const KoiSpacerElement(lines: 1),
        const KoiDividerElement(),

        // 公司信息
        KoiTextElement(
          text: '{{company_name}}',
          align: KoiTextAlign.center,
        ),
        KoiTextElement(
          text: '{{company_address}}',
          align: KoiTextAlign.center,
        ),
        const KoiDividerElement(),

        // 退款信息
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '原单号', ratio: 4),
          KoiTextColumn(text: '{{original_sn}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款单号', ratio: 4),
          KoiTextColumn(text: '{{refund_sn}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款原因', ratio: 4),
          KoiTextColumn(text: '{{reason}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款时间', ratio: 4),
          KoiTextColumn(text: '{{refund_time}}', ratio: 8),
        ]),
        const KoiDividerElement(),

        // 金额
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '原金额', ratio: 6),
          KoiTextColumn(
            text: '¥{{original_amount}}',
            ratio: 6,
            align: KoiTextAlign.right,
          ),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '退款金额', ratio: 6, bold: true),
          KoiTextColumn(
            text: '¥{{refund_amount}}',
            ratio: 6,
            align: KoiTextAlign.right,
          ),
        ]),
        const KoiDividerElement(),

        // 操作员
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '经手人', ratio: 4),
          KoiTextColumn(text: '{{operator}}', ratio: 8),
        ]),
        const KoiSpacerElement(lines: 1),

        // 声明
        const KoiTextElement(
          text: '此票据作为退款凭证，请妥善保管',
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 2),
        const KoiCutElement(),
      ],
    );
  }
}
```

### 2.2 交款申请模板

**文件路径**: `koi_printer/example/lib/src/template/ticket/koi_payment_request_template.dart`

```dart
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 交款申请模板。
/// 用于 TMS 场景下司机向财务交款的凭证打印。
class KoiPaymentRequestTemplate extends KoiPrintTemplate {
  const KoiPaymentRequestTemplate();

  @override
  String get templateId => 'payment_request';

  @override
  String get displayName => '交款申请';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiTicketDocument(
      elements: [
        // 标题
        const KoiTextElement(
          text: '交  款  申  请  单',
          align: KoiTextAlign.center,
          bold: true,
          size: KoiTextSize.size2,
        ),
        const KoiSpacerElement(lines: 1),
        const KoiDividerElement(),

        // 基本信息
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '申请单号', ratio: 4),
          KoiTextColumn(text: '{{request_sn}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '申请日期', ratio: 4),
          KoiTextColumn(text: '{{request_date}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '司机姓名', ratio: 4),
          KoiTextColumn(text: '{{driver_name}}', ratio: 8),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '车牌号码', ratio: 4),
          KoiTextColumn(text: '{{plate_number}}', ratio: 8),
        ]),
        const KoiDividerElement(),

        // 货物明细标题
        const KoiTextElement(text: '运费明细', bold: true),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '单号', ratio: 5),
          const KoiTextColumn(text: '金额', ratio: 3, align: KoiTextAlign.right),
          const KoiTextColumn(text: '备注', ratio: 4),
        ]),
        const KoiDividerElement(char: '-'),

        // 动态列表 (由模板引擎展开)
        KoiTicketForEachElement(
          listKey: 'items',
          templates: [
            KoiTextRowElement(columns: [
              const KoiTextColumn(text: '{{item.sn}}', ratio: 5),
              KoiTextColumn(
                text: '{{item.amount}}',
                ratio: 3,
                align: KoiTextAlign.right,
              ),
              const KoiTextColumn(text: '{{item.note}}', ratio: 4),
            ]),
          ],
        ),
        const KoiDividerElement(),

        // 合计
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '合计金额', ratio: 6, bold: true),
          KoiTextColumn(
            text: '¥{{total_amount}}',
            ratio: 6,
            align: KoiTextAlign.right,
          ),
        ]),
        const KoiSpacerElement(lines: 1),

        // 签名区
        const KoiTextElement(text: '财务签字: _______________'),
        const KoiSpacerElement(lines: 1),
        const KoiTextElement(text: '司机签字: _______________'),
        const KoiSpacerElement(lines: 2),
        const KoiCutElement(),
      ],
    );
  }
}
```

### 2.3 简单收据 Demo

**文件路径**: `koi_printer/example/lib/src/template/demo/koi_simple_receipt_template.dart`

```dart
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 简单收据 Demo 模板。
/// 面向新开发者的最简单上手示例，展示核心元素用法。
class KoiSimpleReceiptTemplate extends KoiPrintTemplate {
  const KoiSimpleReceiptTemplate();

  @override
  String get templateId => 'simple_receipt';

  @override
  String get displayName => '简单收据 (Demo)';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiTicketDocument(
      elements: [
        // 店铺名称 — 居中大字
        const KoiTextElement(
          text: 'Mr.Koi Store',
          align: KoiTextAlign.center,
          bold: true,
          size: KoiTextSize.size2,
        ),
        const KoiTextElement(
          text: 'www.mrkoi.com',
          align: KoiTextAlign.center,
        ),
        const KoiDividerElement(),

        // 商品列表
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '商品', ratio: 6),
          const KoiTextColumn(text: '数量', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right),
        ]),
        const KoiDividerElement(char: '-'),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: 'Koi Premium', ratio: 6),
          const KoiTextColumn(text: '1', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '¥99.00', ratio: 4, align: KoiTextAlign.right),
        ]),
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: 'Koi Basic', ratio: 6),
          const KoiTextColumn(text: '2', ratio: 2, align: KoiTextAlign.center),
          const KoiTextColumn(text: '¥39.00', ratio: 4, align: KoiTextAlign.right),
        ]),
        const KoiDividerElement(),

        // 合计
        KoiTextRowElement(columns: [
          const KoiTextColumn(text: '合计', ratio: 8, bold: true),
          const KoiTextColumn(
            text: '¥177.00',
            ratio: 4,
            align: KoiTextAlign.right,
          ),
        ]),
        const KoiSpacerElement(lines: 1),

        // QR 码
        const KoiQrCodeElement(
          data: 'https://github.com/mrkoi-is/koi_printer',
          align: KoiTextAlign.center,
          size: KoiQrSize.size5,
        ),
        const KoiTextElement(
          text: '扫码了解 koi_printer SDK',
          align: KoiTextAlign.center,
        ),
        const KoiSpacerElement(lines: 2),
        const KoiCutElement(),
      ],
    );
  }
}
```

### 2.4 简单标签 Demo

**文件路径**: `koi_printer/example/lib/src/template/demo/koi_simple_label_template.dart`

```dart
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 简单标签 Demo 模板。
/// 展示 TSPL/CPCL 坐标定位布局的最简上手示例。
class KoiSimpleLabelTemplate extends KoiPrintTemplate {
  const KoiSimpleLabelTemplate();

  @override
  String get templateId => 'simple_label';

  @override
  String get displayName => '简单标签 (Demo)';

  @override
  KoiPrintDocument build(Map<String, dynamic> data) {
    return KoiLabelDocument(
      elements: [
        // 标签尺寸设置 (100mm x 60mm, 3mm 间距)
        const KoiLabelSetupElement(widthMm: 100, heightMm: 60, gapMm: 3),

        // 公司名 — 顶部居中
        const KoiPositionedTextElement(
          x: 50, y: 10,
          text: 'Mr.Koi Logistics',
          font: '3',
          xScale: 2, yScale: 2,
        ),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 55, width: 800, height: 2),

        // 收件人信息区
        const KoiPositionedTextElement(x: 10, y: 65, text: '收: {{receiver_name}}'),
        const KoiPositionedTextElement(x: 10, y: 90, text: '    {{receiver_phone}}'),
        const KoiPositionedTextElement(x: 10, y: 115, text: '    {{receiver_address}}'),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 155, width: 800, height: 2),

        // 寄件人信息区
        const KoiPositionedTextElement(x: 10, y: 165, text: '寄: {{sender_name}}  {{sender_phone}}'),

        // 分割线
        const KoiLabelLineElement(x: 0, y: 185, width: 800, height: 2),

        // 条形码 + 单号
        const KoiPositionedBarcodeElement(
          x: 150, y: 200,
          data: '{{waybill_sn}}',
          height: 80,
        ),
        const KoiPositionedTextElement(
          x: 150, y: 290,
          text: '{{waybill_sn}}',
          font: '2',
          xScale: 2, yScale: 2,
        ),

        // 打印
        const KoiLabelPrintElement(),
      ],
    );
  }
}
```

### 2.5 更新模板注册表

**文件路径**: `koi_printer/example/lib/src/template/koi_templates.dart`

查看当前文件内容，在现有导出列表中**追加**以下内容：

```dart
// 在文件顶部追加导入:
export 'ticket/koi_refund_ticket_template.dart';
export 'ticket/koi_payment_request_template.dart';
export 'demo/koi_simple_receipt_template.dart';
export 'demo/koi_simple_label_template.dart';
```

> [!NOTE]
> 需先创建 `demo/` 子目录。两个 demo 文件放在 `demo/` 子目录下。

### 验收标准
- [ ] 4 个模板文件存在且可编译 (`flutter analyze` 无 error)
- [ ] `koi_templates.dart` 已更新导出
- [ ] 模板中使用正确的类型: `KoiTicketDocument` / `KoiLabelDocument`
- [ ] `ForEach` 元素在交款单模板中正确使用

---

## Task 3: 完善 pubspec 元数据

### 目标
在 3 个包的 `pubspec.yaml` 中添加 `repository`、`homepage`、`issue_tracker` 字段。

### 修改文件

**`koi_printer_command/pubspec.yaml`** — 在 `description` 后添加:
```yaml
repository: https://github.com/mrkoi-is/koi_printer/tree/main/koi_printer_command
homepage: https://github.com/mrkoi-is/koi_printer
issue_tracker: https://github.com/mrkoi-is/koi_printer/issues
```

**`koi_printer_connection/pubspec.yaml`** — 同上，路径改为 `koi_printer_connection`

**`koi_printer/pubspec.yaml`** — 同上，路径改为 `koi_printer`

### 验收标准
- [ ] 3 个 pubspec.yaml 均含 `repository` 字段

---

## Task 4: 完善 CHANGELOG.md

### 目标
在 3 个包的 `CHANGELOG.md` 中填写 v0.1.0 变更记录 (当前为空占位)。

### 格式模板 (3 个包都用此格式，内容各自调整)

**`koi_printer_command/CHANGELOG.md`**:
```markdown
## 0.1.0

* 初始发布 (Initial release)
* 打印文档模型: `KoiTicketDocument`, `KoiLabelDocument`
* 封装 sealed class 元素树: 37 个打印元素类型
* ESC/POS 渲染器: 支持 6 种 QR 策略, 中英文混排, 图片光栅化
* TSPL 渲染器: 坐标定位文本/条码/图片/几何图形
* CPCL 渲染器: 旋转文本, 扩展图形指令
* JSON 序列化: 完整的 `KoiJsonSerialization` 支持
* 142 单元测试, 覆盖核心渲染逻辑
```

**`koi_printer_connection/CHANGELOG.md`**:
```markdown
## 0.1.0

* 初始发布 (Initial release)
* `KoiPrinterAdapter` 统一连接接口
* BLE 适配器: 基于 `flutter_blue_plus`, 支持 MTU 分块
* 经典蓝牙适配器: 基于 `flutter_bluetooth_serial`
* TCP/IP 网络适配器: Socket 长连接
* USB 适配器: `libusb` 通信
* `KoiConnectionPolicy` 重连策略: 线性/指数退避
* `KoiDiscoveredDevice` 设备发现模型
* 18 单元测试
```

**`koi_printer/CHANGELOG.md`**:
```markdown
## 0.1.0

* 初始发布 (Initial release)
* `KoiPrinterManager` 双机管理器 (小票机 + 标签机)
* `KoiTemplateEngine` 模板引擎: 嵌套路径变量 `{{a.b.c}}` + ForEach 展开
* `KoiPreviewRenderer` 所见即所得预览: 支持 ESC/TSPL/CPCL
* `KoiPrinterProfile` 打印机能力数据库: 8 个主流型号
* `KoiPrintJobQueue` 异步打印队列
* 154 单元测试
```

### 验收标准
- [ ] 3 个 CHANGELOG.md 均已填写实质内容 (非空占位)

---

## Commit 规范

所有改动使用以下 commit message:

```
feat: Sprint 2 — CI/CD + 补齐4模板 + 完善文档元数据

- 新增 .github/workflows/ci.yml (三包自动化测试)
- 新增 KoiRefundTicketTemplate (退票模板)
- 新增 KoiPaymentRequestTemplate (交款申请模板)
- 新增 KoiSimpleReceiptTemplate (收据 Demo)
- 新增 KoiSimpleLabelTemplate (标签 Demo)
- 更新 3 个包的 pubspec.yaml (repository metadata)
- 更新 3 个包的 CHANGELOG.md (v0.1.0)
```

---

## 验收检查清单 (提交后告知 Antigravity)

```bash
# Antigravity 会运行以下验收命令:
flutter analyze koi_printer/example
git log --oneline -3
ls .github/workflows/
cat koi_printer_command/CHANGELOG.md
```
