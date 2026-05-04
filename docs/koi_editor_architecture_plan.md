# Koi Printer Studio — 可视化模板编辑器架构与产品规划

> **状态**: 规划中 (Planning)
> **定位**: SaaS 级企业打印模板在线设计器 (Web/Desktop)
> **目标用户**: TMS 系统实施人员、网点操作员、财务人员（无代码基础）

## 1. 产品愿景与核心价值 (Product Vision)

目前的 `koi_printer` 已经完美解决了底层指令翻译和物理硬件连接的问题，并且通过 JSON 实现了模板的序列化。
**Koi Printer Studio** 的使命是：将 JSON 模板的编写过程彻底**图形化、零代码化**。让普通用户能够像使用 PPT 或 BarTender 一样，通过拖拽和配置完成复杂单据（小票/面单）的设计，实现云端分发。

## 2. 产品交互设计 (UX/UI Design)

系统采用经典的 **三栏式 Web 布局 (3-Pane Layout)**：

### 2.1 顶部操作条 (Top Toolbar)
* **纸张设置**: 切换画布物理尺寸 (例如：58mm 卷纸、80mm 卷纸、100x150mm 面单)。
* **历史操作**: 撤销 (Undo) / 重做 (Redo)。
* **视图控制**: 缩放画布 (Zoom In/Out)、网格线开关。
* **发布与测试**:
  * **真机预览**: 在 Web 上点击，局域网内的手机通过 WebSocket 接收 JSON 并直接驱动真实打印机打样。
  * **云端保存**: 保存为 JSON 并同步到 TMS 模板库。

### 2.2 左侧物料与数据池 (Left Palette)
分为两个主要 Tab：
1. **组件库 (Components)**：
   * 基础组件：文本 (Text)、图片 (Logo)、一维码 (Barcode)、二维码 (QR)。
   * 排版组件：横向分栏 (Row Grid)、分割线 (Divider)、空白行 (Spacer)。
   * 逻辑组件：循环列表 (ForEach - 用于商品明细)。
2. **数据源 (Data Schema)**：
   * 树状展示当前单据绑定的可用变量字典（如 `收件人 -> 姓名`, `运费 -> 代收货款`）。
   * 交互：用户可以直接将树节点拖拽到画布中，自动生成绑定好变量的组件。

### 2.3 中间操作画布 (Center Canvas)
分为两种渲染引擎，对用户透明，但交互不同：
* **小票模式 (流式排版 Flow Layout)**：
  * 行为类似 Word。组件从上到下排列。
  * 交互支持：上下拖拽调整顺序 (Reorder)，点击选中高亮。
* **面单模式 (绝对坐标 Absolute Layout)**：*(需底层拓展支持)*
  * 行为类似 PPT。组件拥有 `(x, y)` 坐标。
  * 交互支持：自由拖拽移动，八向控制点缩放大小，网格吸附 (Snap to grid)，智能对齐辅助线。

### 2.4 右侧属性检查器 (Right Inspector)
当在画布上点击选中某个元素时，右侧展示该元素的动态属性表单：
* **样式设置**: 字体大小、加粗、下划线、对齐方式、反白显示。
* **条码设置**: 纠错级别、条码标准 (Code128/EAN8等)、高度宽度。
* **数据绑定**: 提供下拉框，将组件文本与左侧的“数据源”字段进行双向绑定。

---

## 3. 软件架构设计 (Technical Architecture)

基于 Flutter Web / Desktop 构建，彻底解耦底层的打印逻辑。

### 3.1 核心状态管理与历史引擎 (Command Pattern)
抛弃简单的 `setState`，引入命令模式以支持复杂的撤销和重做。

```dart
/// 编辑器全局状态树
class EditorState {
  KoiPrintDocument document;
  String? selectedElementId;
  DataSchema currentSchema;
}

/// 用户操作基类
abstract class EditorCommand {
  void execute(EditorState state);
  void undo(EditorState state);
}

// 具体操作示例
class AddElementCommand extends EditorCommand { ... }
class MoveElementCommand extends EditorCommand { ... } 
class UpdatePropertyCommand extends EditorCommand { ... }
```

### 3.2 交互式画布引擎 (Interactive Canvas Engine)
利用目前的 `KoiPreviewRenderer` 作为基础，在其外围包裹一层拦截与手势层：

1. **选中态注入**: 重写渲染逻辑，为每个 `KoiPrintElement` 外层包裹 `GestureDetector` 和 `Container`。当元素的 ID 与 `selectedElementId` 匹配时，绘制蓝色的 Bounding Box（边界框）和控制手柄。
2. **流式拖拽**: 使用 `SliverReorderableList` 渲染元素列表，监听 `onReorder` 触发排序 Command。
3. **坐标系转换**: 对于面单，使用 `InteractiveViewer` 支持画布整体缩放拖拽。子元素使用 `Positioned` 包裹，监听 `onPanUpdate` 将屏幕像素增量转换为物理毫米增量。

### 3.3 领域数据字典映射 (Data Schema Mapping)
定义一套 JSON Schema 格式来描述 TMS 的业务数据：

```json
{
  "entity": "SenderTicket",
  "fields": [
    { "key": "waybillNo", "label": "运单号", "type": "string" },
    { "key": "fee.total", "label": "总运费", "type": "number" },
    { "key": "items", "label": "商品列表", "type": "array" }
  ]
}
```
编辑器加载此 Schema。当用户将“总运费”绑定到某个文本组件时，底层数据模型 `KoiTextElement.text` 会被自动覆写为 `{{fee.total}}`，供最终端的 `KoiTemplateEngine` 解析。

---

## 4. 实施演进路线 (Implementation Roadmap)

### Phase 1: 核心基础构建 (Core Foundation)
* 搭建三栏式 Web 布局骨架。
* 实现 `EditorState` 和基础的撤销/重做栈。
* 能够将当前屏幕状态实时序列化为 JSON 字符串并反序列化。

### Phase 2: 小票流式编辑器 (Flow Editor)
* 实现左侧物料面板到中间画布的点击添加/拖拽添加。
* 中间画布使用 `ReorderableListView` 实现上下排序。
* 右侧属性面板实现文本、分割线、二维码等组件属性的双向绑定与修改。

### Phase 3: 数据绑定与业务化 (Data Binding)
* 引入 Data Schema 解析引擎。
* 右侧面板增加“变量绑定”功能，取代手动输入 `{{}}`。
* 增加“云端加载模板”和“发布到云端”的 API 接口。

### Phase 4: 高级交互拓展 (Advanced UX & Layout) *可选*
* 为底层 `KoiPrintElement` 协议增加 `x, y` 坐标属性扩展。
* 开发绝对定位模式的 Canvas，支持面单的精细拖拽。
* 增加标尺、网格线和智能吸附功能。

---

**总结**：`Koi Printer Studio` 不仅仅是一个界面壳，它是一个独立的前端工程。它充分复用了 `koi_printer_command` 中的数据模型与渲染逻辑，通过在 UI 层面引入命令模式与手势系统，完成从“代码配置”到“可视化拖拽”的跨越。
