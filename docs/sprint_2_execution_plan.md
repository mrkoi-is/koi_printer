# Koi Printer Studio — Sprint 2 冲刺执行计划 (Execution Checkpoints)

> **制定日期 / Created:** 2026-05-07  
> **冲刺周期 / Sprint:** 2026-05-07 → 2026-05-21  
> **目标 / Objective:** 编辑器商业化 — 数据绑定 UX、双模式预览、ForEach 可视化、模板大厅

---

## CHECKPOINT 1: 遗留问题修复与文档整理 [DONE]

**目标:** 修复测试不稳定性，整理仓库基础文档。

**执行:**
1. 修复 `koi_printer` 测试 (`test/koi_service_test.dart`) 中的 `connectAll handles label adapter connect error` flaky 问题。可能是由于事件流时序问题导致。
2. 更新 `README.md`，在快速开始中加入 `git config core.hooksPath .githooks` 提示。
3. 提交代码: `git commit -m "chore: fix flaky test and update docs"`

**验收:**
- [x] 测试 100% 稳定通过。
- [x] README.md 已更新。

---

## CHECKPOINT 2: 右侧检查器 — 数据绑定优化 (Data Binding UX) [PENDING]

**目标:** 让用户从下拉列表中选择变量，而不是手动输入 `{{xxx}}`。

**执行:**
1. 在 `koi_printer_editor` 中封装 `VariableSelectDropdown` 组件，读取 `context.read<EditorState>().currentSchema.fields`。
2. 改造 `TextElementInspector`：
   - 增加“绑定变量”与“固定文本”的切换模式。
   - 当绑定变量时，显示绿色的 `[已绑定: xxx]` 标签，并将真实的 `{{xxx}}` 写入 `KoiTextElement.text`。
3. 改造 `BarcodeElementInspector` 和 `QrCodeElementInspector`，支持类似的数据绑定。

**验收:**
- [ ] 文本、条码、二维码可以在 UI 上下拉选择字段。
- [ ] 选中字段后，底层的 JSON 会正确反映为 `{{fieldKey}}` 格式。

---

## CHECKPOINT 3: 双模式预览 (Dual-Mode Preview) [PENDING]

**目标:** 实现【编辑模式】与【真实数据预览】的切换。

**执行:**
1. 在 `EditorState` 中增加 `bool isPreviewMode = false`，以及 `Map<String, dynamic> mockData`。
2. 在 `TopToolbar` 中增加 Switch 切换按钮。
3. 在 `_EditableElementWrap` 中：
   - 如果 `!isPreviewMode`: 对包含 `{{xxx}}` 的元素，正则匹配并替换为中文名称（高亮显示），如 `<运单号>`。
   - 如果 `isPreviewMode`: 使用 `KoiTemplateEngine.compile` 与 `mockData` 预渲染，展示真实的文本换行和数据填充效果。

**验收:**
- [ ] 切换开关可以正常工作。
- [ ] 预览模式下可以看到模拟的数据填充。

---

## CHECKPOINT 4: ForEach 循环容器可视化 [PENDING]

**目标:** 在画布中直观展现循环列表，并支持子元素拖拽。

**执行:**
1. 左侧 `LeftPalette` 添加 “循环容器 (ForEach)” 组件。
2. 在 `CenterCanvas` 中处理 `KoiTicketForEachElement`，渲染为带虚线框的容器。
3. 修改拖拽/排序逻辑，允许用户将 `TextRowElement` 拖拽到 ForEach 容器的 `itemTemplate` 位置内。

**验收:**
- [ ] 画布中可以正确显示循环容器。
- [ ] 可将其他元素拖入容器中。

---

## CHECKPOINT 5: 模板大厅 (Template Gallery) [PENDING]

**目标:** 提供内置模板库的图形化加载。

**执行:**
1. 新增 `TemplateGalleryModal` 弹窗。
2. 将 `mock_templates.dart` 中的模板序列化为卡片列表（附带截图或预览）。
3. 用户点击卡片后，触发 `EditorCommand` 清空当前画布并加载新模板。

**验收:**
- [ ] 能够通过 UI 弹窗选择并加载不同的模板。

