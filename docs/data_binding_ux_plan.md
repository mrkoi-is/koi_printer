# Koi Printer Studio: 数据绑定层 UX/UI 优化方案 (Phase 3)

> **目标**: 彻底消除手动填写模板变量（如 `{{waybillNo}}`）带来的认知负担和格式错误，实现真正的“零代码、所见即所得”的数据绑定体验。

---

## 1. 核心痛点分析 (Current Pain Points)
目前使用纯文本直接编写 `{{变量名}}` 存在三大缺陷：
1. **易错性**：操作员（非技术人员）容易打错括号 `{}`, `[]` 或者拼错驼峰命名的英文变量名。
2. **预览断层**：在画布 (Center Canvas) 上，长串的英文字段（如 `{{sender.address.detail}}`）会直接破坏排版，导致用户无法判断实际打印出来的行高和对齐效果。
3. **记忆负担**：用户需要频繁在左侧“数据源”面板和右侧“属性检查器”之间来回确认字段名。

---

## 2. 优化方案设计 (UX Optimization Plan)

### 2.1 右侧检查器：从“文本输入”转变为“下拉映射” (Dropdown Binding)
*   **组件重构**：当选中的是一个 `KoiTextElement` 时，除了保留基础的固定文本输入框外，增加一个专用的 **“绑定变量” (Data Source Binding)** 下拉组件。
*   **交互逻辑**：
    1. 用户点击下拉框，展示 `DataSchema` 中的全部可用字段树（例如：`运单号 (waybillNo)`, `总运费 (fee.total)`）。
    2. 用户选中“运单号”后，底层的数据模型自动将 `element.text` 设置为 `{{waybillNo}}`，并且对用户隐藏大括号。
    3. UI 呈现：在文本框旁边显示一个绿色的 Pill (胶囊标签) `[已绑定: 运单号]`。

### 2.2 视觉画布：引入“预览/编辑”双模式切换 (Mock Data Injection)
在顶部工具栏增加一个明显的 Toggle Switch：**[编辑模式] <-> [真实数据预览]**。
*   **编辑模式 (Edit Mode)**：
    当元素内容是 `{{waybillNo}}` 时，拦截底层渲染器，将其强行渲染为高亮的中文别名标签，例如：`<运单号>`（带有浅蓝色背景色块）。这样既不破坏版面，又能让用户知道这是个动态框。
*   **真实数据预览 (Preview Mode)**：
    引入 `koi_printer` 核心库自带的 `KoiTemplateEngine.compile` 方法。我们在内存中准备一份 Mock JSON（假数据，比如 `{"waybillNo": "SF123456789"}`）。切换到此模式时，自动用假数据替换变量，让用户看到“SF123456789”在这个字号下是否会越界换行！这能极大提升“所见即所得”的体验。

### 2.3 左侧物料盘：沉浸式拖拽生成 (Drag-and-Drop Generation)
*   在左侧的“数据源” (Data Schema) Tab 下，允许用户直接**长按某一个字段**（如：商品列表），将其直接拖拽入中间的画布区。
*   **魔法生成**：松手后，编辑器自动将其转化为一个已经设置好 `{{items}}` 绑定关系的文本行或表格元素。不需要先建文本再绑数据，一步到位！

---

## 3. 技术实施路径 (Execution Steps)

1. **改造 `EditorState`**:
    * 引入 `bool isPreviewMode` 状态。
    * 提供生成 Mock 数据的工厂方法。
2. **重写 `_EditableElementWrap` 渲染拦截**:
    * 如果 `isPreviewMode == false`，通过正则匹配 `\{\{([^}]+)\}\}`，将匹配到的英文 Key 去 Schema 里查出中文 Label，替换为中文标签。
    * 如果 `isPreviewMode == true`，直接调用 `KoiTemplateEngine` 注入 Mock JSON 然后再交给 `KoiPreviewRenderer` 渲染。
3. **改造 `RightInspector`**:
    * 封装 `VariableSelectDropdown` 组件，读取 `context.read<EditorState>().currentSchema.fields`，将选项提供给用户。
