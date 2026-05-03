# Sprint 3 执行计划 — pub.dev 发布准备
# Execution Plan for Gemini

> **项目路径**: `/Users/max/Workspace/SourceCode/mrkoi/koit_printer`
> **前置条件**: Sprint 2 已完成 (CI/CD 绿色)
> **目标**: 通过 `dart pub publish --dry-run` 验证，达到 pub.dev 高分标准
> **验收人**: Antigravity (Claude)

---

## 背景

pub.dev 评分系统 (pub points) 评估以下维度:
- **Follow Dart conventions** (30pts): 无 lint errors/warnings
- **Provide documentation** (20pts): 公开 API 有 `///` 注释 + README 示例
- **Platform support** (20pts): pubspec 声明平台
- **Pass static analysis** (30pts): `flutter analyze` 无 error
- **Up-to-date deps** (20pts): 依赖版本最新兼容

---

## Task 1: API 文档注释

### 目标
所有 `public` 类和方法必须有 `///` 文档注释。

### 检查范围

运行以下命令找出缺少文档的公开 API:
```bash
cd koi_printer_command && dart analyze 2>&1 | grep "public_member_api_docs"
cd koi_printer_connection && flutter analyze 2>&1 | grep "public_member_api_docs"
cd koi_printer && flutter analyze 2>&1 | grep "public_member_api_docs"
```

### 文档注释格式规范

```dart
/// 简短一句话描述 (英文句号结尾)。
///
/// 详细说明 (可选), 支持 Markdown。
/// 参数说明用 [paramName] 引用。
///
/// Example:
/// ```dart
/// final result = MyClass.doSomething(param: 'value');
/// ```
class MyClass {
  /// 构造函数说明。
  const MyClass({required this.field});

  /// 字段说明。
  final String field;

  /// 方法说明，返回 [ReturnType]。
  ReturnType doSomething() { ... }
}
```

### 重点文件 (必须有文档)

**koi_printer_command:**
```
lib/koi_printer_command.dart              # 库入口
lib/src/model/koi_print_document.dart     # KoiTicketDocument, KoiLabelDocument
lib/src/model/koi_print_element.dart      # 所有 Element 类
lib/src/model/koi_print_result.dart       # KoiPrintSuccess, KoiPrintFailure
lib/src/model/koi_types.dart              # KoiPaperSize, enums
lib/src/renderer/koi_command_renderer.dart
lib/src/renderer/koi_esc_pos_renderer.dart
lib/src/renderer/koi_tspl_renderer.dart
lib/src/renderer/koi_cpcl_renderer.dart
lib/src/serialization/koi_json_serialization.dart
```

**koi_printer_connection:**
```
lib/koi_printer_connection.dart
lib/src/adapter/koi_printer_adapter.dart  # 抽象类，最重要
lib/src/model/koi_connection_config.dart
lib/src/model/koi_connection_policy.dart
lib/src/model/koi_connection_types.dart
lib/src/model/koi_discovered_device.dart
```

**koi_printer:**
```
lib/koi_printer.dart
lib/src/service/koi_printer_manager.dart  # 最重要的公开 API
lib/src/koi_template_engine.dart
lib/src/koi_printer_factory.dart
lib/src/model/koi_printer_profile.dart
lib/src/template/koi_print_template.dart
lib/src/preview/koi_preview_renderer.dart
```

### 验收标准
- [ ] `dart analyze` / `flutter analyze` 无 `public_member_api_docs` warning
- [ ] 至少主要公开类和方法有文档注释

---

## Task 2: pubspec.yaml 发布配置检查

### 检查 koi_printer/pubspec.yaml

确认以下字段:
```yaml
# 应该没有 publish_to: none (或删除该行)
# 应该有:
description: >-
  Flutter printer SDK for ESC/POS, TSPL, CPCL protocols.
  Supports BLE, Classic Bluetooth, TCP/IP, and USB connections
  with template engine and WYSIWYG preview.
version: 0.1.0
repository: https://github.com/mrkoi-is/koi_printer/tree/main/koi_printer
homepage: https://github.com/mrkoi-is/koi_printer
issue_tracker: https://github.com/mrkoi-is/koi_printer/issues

# flutter 平台支持 (如果 pubspec 没有 platforms 字段，添加):
flutter:
  plugin:
    platforms:
      android:
      ios:
```

> [!NOTE]
> `koi_printer` 和 `koi_printer_connection` 是 Flutter 包 (有平台依赖)。
> `koi_printer_command` 是纯 Dart 包，不需要 platforms 字段。

---

## Task 3: dry-run 验证

### 发布顺序 (按依赖顺序，不能颠倒)

```bash
# Step 1: 先验证 command 包
cd /Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer_command
dart pub publish --dry-run 2>&1

# Step 2: 验证 connection 包
cd /Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer_connection
dart pub publish --dry-run 2>&1

# Step 3: 验证 printer 包
cd /Users/max/Workspace/SourceCode/mrkoi/koit_printer/koi_printer
flutter pub publish --dry-run 2>&1
```

### 常见错误处理

| 错误信息 | 解决方案 |
|---------|---------|
| `Package contains no Dart files` | 检查 `lib/` 目录 |
| `Missing required field: description` | pubspec.yaml 添加 description |
| `description too short/long` | description 60-180 字符 |
| `Invalid SDK constraint` | 检查 `environment.sdk` |
| `path dependencies` | path 依赖不能发布，需换成版本号或 git |

> [!IMPORTANT]
> 当前 3 个包之间使用 `path:` 依赖。在正式发布前需要:
> - 先将 `koi_printer_command` 和 `koi_printer_connection` 发布到 pub.dev
> - 然后将 `koi_printer` 的 `path:` 引用改为版本号引用
> 
> **本 Sprint 目标只是验证 dry-run 通过，不实际发布**。

### 验收标准
- [ ] `koi_printer_command` dry-run: `Package validation complete.` ✅
- [ ] `koi_printer_connection` dry-run 无 error
- [ ] `koi_printer` dry-run 无 error (path dep warning 可接受)

---

## Task 4: README 质量提升

### koi_printer_command/README.md

检查并完善，确保包含:

```markdown
# koi_printer_command

[![pub package](https://img.shields.io/pub/v/koi_printer_command.svg)](https://pub.dev/packages/koi_printer_command)
[![CI](https://github.com/mrkoi-is/koi_printer/actions/workflows/ci.yml/badge.svg)](https://github.com/mrkoi-is/koi_printer/actions)

> 纯 Dart 打印指令库，无 Flutter 依赖。支持 ESC/POS、TSPL、CPCL 协议。

## Features / 特性
- 类型安全的打印文档模型 (sealed class)
- ESC/POS 渲染器: 6 种 QR 策略, 中英文混排
- TSPL 渲染器: 坐标定位布局
- CPCL 渲染器: 旋转文本、扩展图形
- JSON 序列化支持

## Quick Start / 快速开始

\`\`\`dart
import 'package:koi_printer_command/koi_printer_command.dart';

// 创建小票文档
const doc = KoiTicketDocument(
  elements: [
    KoiTextElement(text: '感谢惠顾', align: KoiTextAlign.center, bold: true),
    KoiDividerElement(),
    KoiQrCodeElement(data: 'https://mrkoi.com'),
    KoiCutElement(),
  ],
);

// 渲染为 ESC/POS 字节
const renderer = KoiEscPosRenderer();
final List<List<int>> chunks = renderer.render(doc);
\`\`\`
```

### 验收标准
- [ ] 3 个 README 均含: 徽章、Features、Quick Start 代码示例

---

## Commit 规范

```
feat: Sprint 3 — pub.dev 发布准备

- 补全所有公开 API 的 /// 文档注释
- 更新 3 个 pubspec.yaml (发布配置)
- 更新 3 个 README.md (徽章 + Quick Start)
- dart pub publish --dry-run 验证通过
```
