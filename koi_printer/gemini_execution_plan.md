# 🚀 Koi Printer - 阶段 5b & 6 执行与验收方案 (Gemini Execution & Acceptance Plan)

本文档是为 **Gemini** 准备的详细执行指南，涵盖了 `koi_printer` 项目中 **Phase 5b (Editor UI - 元素编辑器)** 和 **Phase 6 (Release & Documentation - 发布与文档)** 的开发任务。完成这些任务后，请提交给架构师节点进行验收。

This document serves as a detailed execution guide for **Gemini** to implement **Phase 5b (Editor UI)** and **Phase 6 (Release & Documentation)** in the `koi_printer` project. Once completed, submit the results to the architect node for acceptance.

---

## 🎯 任务目标 (Objectives)

### 1. Phase 5b: 模板元素编辑器 UI (Template Element Editor UI)
**目标:** 提供一个 Flutter 组件，能够根据传入的不同 `KoiTicketElement` 或 `KoiLabelElement`，动态生成对应的表单（如文本框、下拉菜单、开关等），允许用户实时修改元素的属性，并通过回调返回修改后的新元素。
**Objective:** Provide a Flutter component that dynamically generates forms (text fields, dropdowns, toggles) based on the provided `KoiTicketElement` or `KoiLabelElement`. It should allow users to modify properties in real-time and return the updated element via a callback.

### 2. Phase 6: 文档与发布准备 (Documentation & Release Prep)
**目标:** 完善所有公开 API 的文档注释 (docstrings)，编写完整的 `example` 示例项目，确保项目符合 `pub.dev` 的发布标准（包括 100% 通过 lint 检查）。
**Objective:** Complete docstrings for all public APIs, write a comprehensive `example` project, and ensure the project meets `pub.dev` publishing standards (including 100% lint compliance).

---

## 🛠️ 执行步骤详解 (Detailed Execution Steps)

### Step 1: 创建元素编辑器核心组件 (Create Element Editor Component)
**路径 (Path):** `koi_printer/lib/src/editor/koi_element_editor.dart`

**功能要求 (Requirements):**
- 创建 `KoiElementEditor` Widget，接收参数：`KoiPrintElement element` 和 `ValueChanged<KoiPrintElement> onChanged`。
- 根据 `element` 的具体类型 (如 `KoiTextElement`, `KoiBarcodeElement`, `KoiPositionedTextElement` 等) 渲染不同的编辑表单。
- 对于 `KoiTextElement`，需要提供：
  - 文本内容输入框 (Text Input)
  - 字体大小选择 (Dropdown: `KoiTextSize`)
  - 对齐方式选择 (Dropdown: `KoiTextAlign`)
  - 加粗开关 (Switch: `bold`)
  - 反白开关 (Switch: `reverse`)
- 对于 `KoiBarcodeElement` / `KoiQrCodeElement`，需要提供：
  - 数据输入框 (Data Input)
  - 高度/尺寸调整 (Slider 或 Number Input)
- **状态管理:** 由于 `KoiPrintElement` 是不可变的 (immutable)，当表单值改变时，需要利用 `copyWith` 模式（如果模型中没有，可以直接实例化新对象）并通过 `onChanged` 回传。
- **UI 风格:** 保持简洁的 Material 3 风格，使用 `TextFormField`、`DropdownButtonFormField` 等标准组件。

### Step 2: 编写编辑器测试用例 (Write Editor Tests)
**路径 (Path):** `koi_printer/test/koi_element_editor_test.dart`

**功能要求 (Requirements):**
- 编写 Widget Test，分别挂载传入 `KoiTextElement` 和 `KoiBarcodeElement` 的 `KoiElementEditor`。
- 模拟用户输入（如使用 `tester.enterText`），验证 `onChanged` 回调是否正确触发，并且返回的新元素包含了修改后的值。
- 确保测试覆盖率 (Coverage) 达标。

### Step 3: 完善 API 文档 (Complete API Documentation)
**路径 (Path):** 整个 `koi_printer` 和 `koi_printer_command` 包

**功能要求 (Requirements):**
- 检查 `analysis_options.yaml` 中是否启用了 `public_member_api_docs: true`。
- 运行 `dart analyze`，找出所有缺失文档注释的 `public` 类、方法和属性。
- 为这些 API 添加规范的 `///` 注释。特别注意 `KoiPreviewRenderer`、`KoiPrinterManager`、`KoiPrinterService` 以及所有的 `KoiPrintElement`。

### Step 4: 构建 Example 示例项目 (Build Example Project)
**路径 (Path):** `koi_printer/example/`

**功能要求 (Requirements):**
- 创建一个完整的 Flutter 示例应用。
- 包含一个左右分栏 (或上下分栏) 的 UI：
  - **预览区 (Preview Area):** 使用 `KoiPreviewRenderer` 实时展示标签或小票。
  - **编辑区 (Editor Area):** 列表展示当前模板的所有元素，点击某个元素后，弹出或在侧边栏显示 `KoiElementEditor` 进行修改。
- 包含一个 **打印/连接控制面板**：使用 `KoiPrinterManager` 演示如何搜索、连接蓝牙打印机，并将当前预览的文档发送打印。

---

## 🚦 验收标准 (Acceptance Criteria)

当 Gemini 完成上述开发后，架构师节点将通过以下标准进行验收：
When Gemini completes the development, the architect node will verify against the following criteria:

1. **功能验收 (Functional Verification):**
   - 运行 `flutter test`，所有测试必须 100% 通过（包括新增的编辑器测试）。
   - 编辑器 UI 能够成功渲染文本和条码的属性编辑表单，并在修改时触发数据更新回调。
   
2. **代码质量与 Lint (Code Quality & Linting):**
   - 运行 `dart analyze` 必须达到 `No issues found`（零警告、零错误）。
   - 必须通过 `public_member_api_docs` 的严格检查。
   - 不允许存在被注释掉的“僵尸代码”或未使用的变量。

3. **视觉与交互 (Visual & Interaction - Example App):**
   - 示例项目 (`example/lib/main.dart`) 可以正常编译运行（至少在 macOS 或 iOS/Android 模拟器上）。
   - 示例中修改编辑器里的文本或数字时，预览区域 (`KoiPreviewRenderer`) 必须能够实时更新，不发生重绘闪烁或状态丢失。

4. **架构合规性 (Architectural Compliance):**
   - `KoiElementEditor` 必须保持纯粹的 UI 组件性质 (Stateless 或仅包含本地表单状态的 Stateful)，不得耦合蓝牙通讯或本地存储逻辑。
   - 所有文件符合团队制定的导入顺序和命名规范。

---

## 💡 给 Gemini 的执行提示 (Tips for Gemini)
1. **小步提交 (Small Commits):** 建议分步骤执行。先完成 Editor UI 并写好测试，提交一次；再处理 API 文档和 Lint，提交一次；最后完成 Example，提交一次。
2. **复用现成组件 (Reuse Components):** 优先使用 Material 3 自带的组件，不需要引入庞大的第三方状态管理库，Example 中可以使用简单的 `ValueNotifier` 或 `setState` 来驱动实时预览。
3. **遇到平台报错时 (Handling Platform Errors):** 由于 `flutter_blue_plus` 等原生插件在桌面端模拟器上可能不支持，如果在运行 Widget Test 时遇到 MethodChannel 异常，请使用 `MockPrinterAdapter` 进行隔离。
