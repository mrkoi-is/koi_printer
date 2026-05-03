## 0.1.0

* 初始发布 (Initial release)
* `KoiPrinterManager` 双机管理器 (小票机 + 标签机)
* `KoiTemplateEngine` 模板引擎: 彻底支持 JSON 动态模板解析，支持全局变量 `{{a.b.c}}` 替换与 `<ForEach>` 列表展开
* `KoiPreviewRenderer` 所见即所得预览: 纯 Flutter Widget 1:1 还原 ESC/TSPL 打印效果
* `KoiPrinterProfile` 打印机能力数据库: 内置芯烨/芝科等主流型号适配
* `KoiPrintJobQueue` 异步并发队列: 防止并发打印造成的硬件丢包
* `KoiJsonSerialization` 结合: 彻底实现「后端定义排版 -> 移动端拉取 JSON 渲染打印」的架构闭环
* 154 单元测试，保证所有边界异常安全
