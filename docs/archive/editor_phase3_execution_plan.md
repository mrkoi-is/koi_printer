# Koi Printer Studio: Phase 3 & 4 执行计划

> 本计划旨在补全可视化编辑器的核心商业化能力，涵盖字段映射重构、预览机制、模板大厅以及循环渲染容器。

## 🎯 实施路径 (Execution Steps)

### 第一步：右侧属性检查器 - 数据绑定优化 (Right Inspector Data Binding)
- [ ] 改造 `RightInspector` 中 `KoiTextElement` 的编辑区域。
- [ ] 引入 `VariableDropdown`：读取 `DataSchema` 的字段。
- [ ] 支持三种模式切换：静态文本 (Static)、绑定变量 (Variable)、表达式 (Expression)。
- [ ] 选中“绑定变量”时，UI 隐藏大括号语法，显示绿色的 `[已绑定: 变量名]` 标签。

### 第二步：视觉画布 - 双模式预览机制 (Dual-Mode Canvas)
- [ ] 在 `TopToolbar` 增加一个 Toggle 按钮：**[编辑模式] <-> [真实数据预览]**。
- [ ] 扩展 `EditorState`，增加 `isPreviewMode` 和 `mockData` 属性。
- [ ] **拦截渲染**：在 `_EditableElementWrap` 中：
    - 编辑模式：使用正则解析 `{{xxx}}`，强行替换为带背景色的中文别名（如 `<运单号>`）。
    - 预览模式：调用底层 `KoiTemplateEngine.compile` 注入假数据（如 `SF123456789`），展示最真实的换行效果。

### 第三步：列表循环组件的可视化暴露 (ForEach Block)
- [ ] 在左侧 `LeftPalette` 组件库增加 **“循环容器 (List ForEach)”**。
- [ ] 底层对接 `KoiTicketForEachElement`。
- [ ] 在 `CenterCanvas` 渲染为一个带有虚线边框的容器区域。
- [ ] **痛点攻克**：允许用户将文本行 (`KoiTextRowElement`) 拖入到这个循环容器内部。这需要对 `EditorState` 的拖拽排序树结构进行升级（支持嵌套级联）。

### 第四步：模板大厅与 JSON 持久化加载 (Template Gallery)
- [ ] 提取 `mock_templates.dart` 和 `example` 中的现有模板，将其序列化存入本地（如 `assets/templates/` 目录或内部常量）。
- [ ] 实现 `TemplateGalleryModal`（弹窗）：以卡片网格形式展示可用模板的缩略图或名称。
- [ ] 用户点击模板卡片后，通过 `KoiPrintTemplate.fromJson` 反序列化并全量替换 `EditorState.elements`，实现一键换板。

---
我们将按照以上步骤顺序执行。第一步先从最急迫的“右侧下拉绑定体验”开始重构！
