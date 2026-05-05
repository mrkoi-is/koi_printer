## 0.2.0

* **Feature**: `koi_printer_editor` fully supports metadata, schema configuration, and dynamic mock data editing.
* **Feature**: Added Inspector support for `KoiTextRowElement` (multi-column tables).
* **Coverage**: Achieved ~97% average test coverage across the ecosystem (445 tests total).
* **Fix**: Refined widget interactions and state management across `KoiElementEditor` and `koi_printer_editor`.
* **Refactor**: Resolved all static analysis warnings across all packages (0 lint issues).

## 0.1.0

* 初始发布 (Initial release)
* `KoiPrinterManager` 双机管理器 (小票机 + 标签机)
* `KoiTemplateEngine` 模板引擎: 彻底支持 JSON 动态模板解析，支持全局变量 `{{a.b.c}}` 替换与 `<ForEach>` 列表展开
* `KoiPreviewRenderer` 所见即所得预览: 纯 Flutter Widget 1:1 还原 ESC/TSPL 打印效果
* `KoiElementEditor` 可视化组件编辑器: 支持动态加载打印元素配置，实时反馈编辑属性
* `KoiPrinterProfile` 打印机能力数据库: 内置芯烨/芝科等主流型号适配
* `KoiPrintJobQueue` 异步并发队列: 防止并发打印造成的硬件丢包
* `KoiJsonSerialization` 结合: 彻底实现「后端定义排版 -> 移动端拉取 JSON 渲染打印」的架构闭环
* 引入了全模块 `public_member_api_docs` 代码文档合规验证与严格类型检查
* 完善了 Example 测试与演示应用 (Demo)
* 154 单元测试，保证所有边界异常安全
