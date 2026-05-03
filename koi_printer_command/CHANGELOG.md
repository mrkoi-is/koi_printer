## 0.1.0

* 初始发布 (Initial release)
* 打印文档模型: `KoiTicketDocument`, `KoiLabelDocument`
* 封装 sealed class 元素树: 37 个打印元素类型
* ESC/POS 渲染器: 支持 6 种 QR 策略, 中英文混排, 图片光栅化
* TSPL 渲染器: 坐标定位文本/条码/图片/几何图形
* CPCL 渲染器: 旋转文本, 扩展图形指令
* JSON 序列化: 完整的 `KoiJsonSerialization` 支持
* 142 单元测试, 覆盖核心渲染逻辑
