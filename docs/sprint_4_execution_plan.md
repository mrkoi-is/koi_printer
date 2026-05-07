# Koi Printer Studio — Sprint 4 开源发布冲刺计划 (OSS Release Plan)

> **制定日期 / Created:** 2026-05-07  
> **目标 / Objective:** 完善合规性与开发者体验，将 4 个核心包（包含 Editor）推向 pub.dev。

---

## CHECKPOINT 1: 合规性与基础文档 (Compliance & Documentation) [DONE]

**目标:** 为所有包建立合规的开源协议和发布基线。

**执行:**
1. 在项目根目录以及 `command`, `connection`, `printer`, `editor` 4 个包中均添加 `LICENSE` (MIT) 文件。
2. 确保所有包的 `pubspec.yaml`：
   - 移除 `publish_to: 'none'`
   - 配置正确的 `homepage`, `repository`, `issue_tracker` 链接。
   - 统一 Version 为 `0.1.0`。
3. 更新/添加各包的 `CHANGELOG.md`，记录 0.1.0 首发内容。

---

## CHECKPOINT 2: Editor 库化重构 (Editor Package Refactoring) [DONE]

**目标:** 将原本作为私有 App 开发的 `koi_printer_editor` 改造为可独立引用的 Flutter Package。

**执行:**
1. 在 `koi_printer_editor/lib` 下创建入口文件 `koi_printer_editor.dart`，暴露 `KoiEditorWidget` 和相关的状态类（如 `EditorState`, `KoiTemplateManifest`）。
2. 将现有的 `lib/main.dart` 迁移至 `example/lib/main.dart`，作为该 Package 的演示工程。
3. 确保对外暴露的类名没有隐私依赖或业务硬编码。

---

## CHECKPOINT 3: 示例工程补齐 (Examples Completion) [DONE]

**目标:** 满足 pub.dev 满分 140/140 的必要条件：每个包必须有 `example/` 目录。

**执行:**
1. 为 `koi_printer_command` 添加 `example/lib/main.dart` (纯 Dart 控制台 Demo，演示如何生成 TSPL 字节)。
2. 为 `koi_printer_connection` 添加 `example/lib/main.dart` (Flutter Demo，演示如何扫描蓝牙并连接)。
3. 为 `koi_printer` 补全并验证已有的 `example` 能否跑通。

---

## CHECKPOINT 4: Dartdoc 补齐与最终静态检查 (Documentation & Analysis) [PENDING]

**目标:** 为所有公开 API 补充 `///` 文档，确保没有任何分析警告。

**执行:**
1. 对 4 个包分别执行 `flutter analyze`，确保 0 问题。
2. 运行 `pana` 本地模拟打分工具，检查是否达到 140/140。
3. (可选) 提供完整的对外开放的 API 接入说明。

---

> **验收标准 / Definition of Done**: 当所有代码满足 `pana` 静态检查高分，并且可以直接通过 `flutter pub publish --dry-run` 时，Sprint 4 即宣告完成！
