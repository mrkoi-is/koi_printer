# Koi Printer Studio — Sprint 3 冲刺执行计划 (Execution Checkpoints)

> **制定日期 / Created:** 2026-05-07  
> **冲刺周期 / Sprint:** 2026-05-22 → 2026-06-05  
> **目标 / Objective:** 高级交互 — 绝对坐标拖拽、云端分发与真机远程打样

---

## CHECKPOINT 1: 面单模式绝对坐标拖拽 (Absolute Positioning Editor) [PENDING]

**目标:** 在“面单模式” (Label Mode) 下，支持用户直接在画布上拖拽元素来改变其绝对坐标 (x, y)。

**执行:**
1. 升级 `CenterCanvas` 中的 `KoiLabelDocument` 渲染逻辑。
2. 为画布中的 `KoiPositionedElement` (如文本、条码、二维码) 包裹 `Positioned` + `GestureDetector` / `Draggable`。
3. 捕获 `onPanUpdate` 和 `onPanEnd` 事件，实时更新临时拖拽状态。
4. 拖拽结束时触发 `UpdateElementCommand`，更新对应元素的 `x` 和 `y` 属性。
5. （可选增强）实现简单的网格吸附 (Grid Snapping) 功能。

**验收:**
- [ ] 面单模式下的组件能在画布中自由拖拽移动。
- [ ] 拖拽结束后，右侧属性检查器中的 x, y 坐标会随之更新。
- [ ] 撤销/重做 (Undo/Redo) 支持拖拽坐标的恢复。

---

## CHECKPOINT 2: 云端保存与分发 API (Cloud Sync API) [PENDING]

**目标:** 允许用户将本地编辑好的模板保存到云端，以及从云端加载模板，摆脱纯本地资产依赖。

**执行:**
1. 定义云端同步接口（接口规范：获取模板列表、上传模板JSON、下载模板JSON）。
2. 在 `EditorState` 或新建 `CloudSyncService` 中实现 API 调用逻辑。
3. 更新 `TopToolbar` 的“模板大厅”，加入“云端模板” Tab 或刷新功能。
4. 实现“另存为”功能，调用上传 API 并输入新模板信息。

**验收:**
- [ ] 能够通过网络请求获取远端模板列表。
- [ ] 当前画布能序列化为 JSON 并通过 API 上传成功。
- [ ] 编辑器具备“云端”和“本地”模板切换能力。

---

## CHECKPOINT 3: 真机远程打样 (Remote Proofing) [PENDING]

**目标:** 利用局域网 WebSocket 或扫码形式，实现 Web/PC 编辑器与手机端 (Printer App) 的互联，一键将当前模板下发到真机打印打样。

**执行:**
1. 设计编辑器端 WebSocket Server / Client 或二维码数据传输协议。
2. `TopToolbar` 新增“真机打样”按钮。
3. 点击“真机打样”后，将当前 `EditorState.document` 序列化，通过通信通道发往移动设备端。
4. 确保网络模块的解耦，编写完善的测试用例验证连通性与失败处理。

**验收:**
- [ ] 提供直观的远程连接方式（局域网 IP 直连或扫码连网）。
- [ ] 一键触发真机打样，设备端能顺利接收 JSON 并解析打印。
- [ ] 断线/发送失败时提供清晰的错误提示。

---

> **注意:** 本计划将确保新功能持续满足 90% 以上测试覆盖率，并在合并代码前通过严格的静态分析检查。
