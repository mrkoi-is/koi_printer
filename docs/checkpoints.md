# Koi Printer — Checkpoint 执行清单
# Koi Printer — Checkpoint Execution Checklist

> 本文件为 Gemini AI 执行专用。每个 Checkpoint 是一个独立原子任务。
> This file is designed for Gemini AI execution. Each Checkpoint is an independent atomic task.
> 
> **执行规则:**
> 1. 按顺序执行每个 Checkpoint
> 2. 每完成一个 Checkpoint，在其标题后标注 `[DONE]`
> 3. 如果验收标准未通过，停下来描述问题
> 4. 所有 flutter/dart 命令使用 FVM: 前缀 `flutter` 即可（已配置）
> 5. 工作区根目录: `/Users/max/Workspace/SourceCode/mrkoi/koit_printer`

---

## CHECKPOINT 1: 提交 koi_printer_connection 测试成果 [DONE]

**包:** `koi_printer_connection`  
**预计用时:** 10 min  
**前置条件:** 无

**执行:**
1. `cd koi_printer_connection`
2. `flutter test --coverage` — 确认 64 tests 全部通过
3. 确认覆盖率 ≥ 93%
4. `git add .`
5. `git commit -m "test(connection): achieve 93.6% coverage with DI refactor for BLE scanner"`

**验收:** 
- [ ] 64 tests pass
- [ ] Coverage ≥ 93%
- [ ] Git commit 成功

---

## CHECKPOINT 2: koi_printer_connection Lint 修复 [DONE]

**包:** `koi_printer_connection`  
**预计用时:** 1 hour  
**前置条件:** CHECKPOINT 1

**执行:**
1. `cd koi_printer_connection`
2. `dart fix --apply` — 自动修复 cascade_invocations
3. 手动修复以下 lint rules:
   - `avoid_catches_without_on_clauses` — 把 `catch (e)` 改为 `on Object catch (e)`
     - 文件: `koi_ble_adapter.dart` (L103, L136, L142, L203)
     - 文件: `koi_network_adapter.dart`
     - 文件: `koi_classic_bt_adapter.dart`
   - `lines_longer_than_80_chars` — 拆分长行
     - 文件: `koi_ble_adapter.dart` (L133, L156)
   - `deprecated_member_use` — 移除 FBP `connecting`/`disconnecting` 枚举引用
     - 文件: `koi_ble_adapter.dart` (L85, L87)
   - `discarded_futures` — 添加 `unawaited()` 包裹
   - `unawaited_futures` — 添加 `unawaited()` 或 `await`
4. `flutter analyze` — 确认 0 issues
5. `flutter test` — 确认无回归
6. `git commit -m "fix(connection): resolve all lint issues"`

**验收:**
- [ ] `flutter analyze` 无 error/warning
- [ ] All tests pass
- [ ] Committed

---

## CHECKPOINT 3: KoiElementEditor 基础元素 Widget 测试 [DONE]

**包:** `koi_printer`  
**预计用时:** 3 hours  
**前置条件:** 无（可与 CHECKPOINT 1-2 并行在不同包）

**目标:** 为 `koi_element_editor.dart` 的 Text/Barcode/QrCode 元素编写 Widget 测试

**关键信息:**
- 源码: `lib/src/editor/koi_element_editor.dart` (636 行)
- 现有测试: `test/koi_element_editor_test.dart`
- 当前覆盖率: 43.1% (140/325) — 是整包唯一短板

**执行:**
1. 查看 `test/koi_element_editor_test.dart` 了解已有测试
2. 创建测试 helper：
   ```dart
   Widget buildEditor<T extends Object>(T element, ValueChanged<T> onChanged) {
     return MaterialApp(
       home: Scaffold(body: SingleChildScrollView(
         child: KoiElementEditor<T>(element: element, onChanged: onChanged),
       )),
     );
   }
   ```
3. 为 `KoiTextElement` 编写测试:
   - 渲染并验证 TextField 存在
   - 输入文本并验证 onChanged 被调用
   - 点击 Bold/Reverse 开关
   - 选择对齐方式和字体大小的下拉菜单
4. 为 `KoiBarcodeElement` 编写测试:
   - 输入条码数据
   - 选择对齐方式
5. 为 `KoiQrCodeElement` 编写测试:
   - 输入 QR 数据
   - 选择对齐方式
6. `flutter test test/koi_element_editor_test.dart`
7. `flutter test --coverage` 检查覆盖率提升

**验收:**
- [ ] 新增 ≥ 10 个测试用例
- [ ] `koi_element_editor.dart` 覆盖率 ≥ 60%
- [ ] `git commit -m "test(printer): add widget tests for basic element editors"`

---

## CHECKPOINT 4: KoiElementEditor 定位元素 Widget 测试 [DONE]

**包:** `koi_printer`  
**预计用时:** 2.5 hours  
**前置条件:** CHECKPOINT 3

**执行:**
1. 为 `KoiPositionedTextElement` 编写 Widget 测试:
   - X/Y 坐标输入验证（包含 `_parseInt` fallback 逻辑）
   - 文本内容输入
   - Bold 开关
2. 为 `KoiPositionedBarcodeElement` 编写:
   - X/Y + Data 三个输入框
3. 为 `KoiPositionedQrCodeElement` 编写:
   - X/Y + Data 三个输入框
4. `flutter test --coverage`

**验收:**
- [ ] 新增 ≥ 8 个测试用例
- [ ] `koi_element_editor.dart` 覆盖率 ≥ 75%
- [ ] `git commit -m "test(printer): add widget tests for positioned element editors"`

---

## CHECKPOINT 5: KoiElementEditor 标签元素 + 边界情况 [DONE]

**包:** `koi_printer`  
**预计用时:** 2 hours  
**前置条件:** CHECKPOINT 4

**执行:**
1. 为 `KoiLabelBoxElement` 编写 X/Y 坐标测试
2. 为 `KoiLabelReverseElement` 编写 X/Y 坐标测试
3. 测试不支持的元素类型显示回退文本
4. 测试 `didUpdateWidget`:
   - 先 pumpWidget 一个 TextElement，再换成 BarcodeElement
   - 验证 `_initControllers` 被重新调用
5. 运行 `flutter test --coverage` 获取整包覆盖率

**验收:**
- [ ] `koi_element_editor.dart` 覆盖率 ≥ 85%
- [ ] `koi_printer` 整包覆盖率 ≥ 90%
- [ ] `git commit -m "test(printer): complete element editor coverage to 85%+"`

---

## CHECKPOINT 6: editor_command.dart 测试补齐

**包:** `koi_printer_editor`  
**预计用时:** 1.5 hours  
**前置条件:** 无

**关键信息:**
- 源码: `lib/state/editor_command.dart` (179行)
- 当前覆盖率: 70.5% (55/78)
- 未覆盖: `AddElementCommand` 的 `parentId` 分支 (L20-L38, L56-L70)

**执行:**
1. 阅读 `editor_command.dart` 理解 `parentId` + `KoiTicketForEachElement` 子元素逻辑
2. 阅读 `editor_state.dart` 了解 `EditorState` 接口
3. 编写测试:
   - `AddElementCommand.execute` 带 `parentId` 到 `KoiTicketForEachElement`:
     - 有效 parentId + 有效 index → 插入到指定位置
     - 有效 parentId + null index → 追加到末尾
     - 无效 parentId (不存在) → no-op
     - parentId 对应的不是 ForEach 元素 → no-op
   - `AddElementCommand.undo` 带 `parentId`:
     - 从 ForEach 的 templates 中移除子元素
4. `flutter test --coverage`

**验收:**
- [ ] `editor_command.dart` 覆盖率 ≥ 90%
- [ ] `koi_printer_editor` 整包覆盖率 ≥ 93%
- [ ] `git commit -m "test(editor): cover AddElementCommand parentId/index branches"`

---

## CHECKPOINT 7: koi_printer + koi_printer_command Lint 清理

**包:** `koi_printer`, `koi_printer_command`  
**预计用时:** 2 hours  
**前置条件:** CHECKPOINT 5

**执行:**
1. **koi_printer_command (15 条):**
   ```bash
   cd koi_printer_command
   dart fix --apply
   ```
   手动修复:
   - `lines_longer_than_80_chars`: koi_cpcl_renderer.dart:72, koi_esc_pos_renderer.dart:516, etc.
   - `missing_whitespace_between_adjacent_strings`: koi_tspl_renderer.dart:51,59,67
   - `sort_pub_dependencies`: pubspec.yaml
   - `avoid_print`: test_raster.dart:37,61
   ```bash
   dart analyze
   flutter test
   ```

2. **koi_printer (17 条):**
   ```bash
   cd koi_printer
   dart fix --apply
   ```
   手动修复:
   - `avoid_catches_without_on_clauses`: koi_printer_storage.dart:95
   - `lines_longer_than_80_chars`: koi_preview_renderer.dart
   - `discarded_futures`: 多处
   - `comment_references`: koi_printer.dart
   ```bash
   flutter analyze
   flutter test
   ```

3. `git commit -m "fix: resolve all lint issues in koi_printer and koi_printer_command"`

**验收:**
- [ ] 两个包 `flutter analyze` / `dart analyze` = 0 issues
- [ ] All tests pass
- [ ] Committed

---

## CHECKPOINT 8: koi_printer_manager.dart 精确补漏

**包:** `koi_printer`  
**预计用时:** 1 hour  
**前置条件:** CHECKPOINT 5

**关键信息:**
- 未覆盖行: L199-201, L220-222 (6行)
- 这些很可能是 connectAll 中某特定 adapter 组合的 error 分支

**执行:**
1. 查看 `koi_printer_manager.dart` L195-225 具体代码
2. 识别未覆盖的条件分支
3. 编写针对性测试（可能需要 mock 特定 adapter 行为）
4. `flutter test --coverage`

**验收:**
- [ ] koi_printer_manager.dart ≥ 97%
- [ ] Tests pass

---

## CHECKPOINT 9: koi_preview_renderer.dart + koi_print_job_queue.dart 补漏

**包:** `koi_printer`  
**预计用时:** 1 hour  
**前置条件:** CHECKPOINT 8

**关键信息:**
- `koi_preview_renderer.dart`: 未覆盖 L137, L143 (2行)
- `koi_print_job_queue.dart`: 未覆盖 L129, L130 (2行)

**执行:**
1. 查看具体未覆盖行的代码
2. 编写针对性测试
3. `flutter test --coverage`
4. `git commit -m "test(printer): close coverage gaps in manager, preview, and job queue"`

**验收:**
- [ ] 两个文件均 ≥ 99%
- [ ] koi_printer 整包 ≥ 92%
- [ ] Committed

---

## CHECKPOINT 10: GitHub Actions CI 覆盖率门槛

**包:** 全局 `.github/workflows/ci.yml`  
**预计用时:** 1 hour  
**前置条件:** CHECKPOINT 7

**执行:**
1. 编辑 `.github/workflows/ci.yml`
2. 在每个包的 test step 后添加覆盖率检查 step:
   ```yaml
   - name: Check coverage (koi_printer)
     working-directory: koi_printer
     run: |
       LH=$(grep -c 'LH:' coverage/lcov.info | head -1 || echo 0)
       LF=$(grep -c 'LF:' coverage/lcov.info | head -1 || echo 1)
       # 使用 awk 计算百分比并检查门槛
       awk '/^LF:/{lf+=$0+0}/^LH:/{lh+=$0+0}END{pct=lh/lf*100; if(pct<85){print "FAIL: "pct"%"; exit 1}else{print "PASS: "pct"%"}}' coverage/lcov.info
   ```
3. 对 koi_printer_command, koi_printer_connection, koi_printer_editor 重复
4. Push 并确认 CI 通过

**验收:**
- [ ] CI pipeline 包含覆盖率门槛检查
- [ ] CI 绿色通过

---

## CHECKPOINT 11: README + CHANGELOG 更新

**包:** 全局  
**预计用时:** 30 min  
**前置条件:** CHECKPOINT 9, 10

**执行:**
1. 更新 `koi_printer/README.md`:
   - 覆盖率数据更新
   - 测试数量更新
2. 更新各包 `CHANGELOG.md`:
   - 记录测试覆盖率提升
   - 记录 lint 清理
   - 记录 BLE scanner DI 重构
3. `git commit -m "docs: update coverage metrics and changelogs"`

**验收:**
- [ ] README 数据准确
- [ ] CHANGELOG 记录完整
- [ ] Committed

---

## CHECKPOINT 12: 最终全量验证

**包:** 全部  
**预计用时:** 30 min  
**前置条件:** 全部 CHECKPOINT 1-11

**执行:**
```bash
echo "=== FINAL VALIDATION ==="
for pkg in koi_printer_command koi_printer_connection koi_printer koi_printer_editor; do
  echo ""
  echo "--- $pkg ---"
  cd $pkg
  flutter analyze 2>&1 | tail -3
  flutter test --coverage 2>&1 | tail -3
  # 打印覆盖率
  python3 -c "
with open('coverage/lcov.info') as f:
  lf=lh=0
  for l in f:
    if l.startswith('LF:'): lf+=int(l[3:])
    elif l.startswith('LH:'): lh+=int(l[3:])
  pct = lh/lf*100 if lf > 0 else 0
  status = '✅' if pct >= 90 else '❌'
  print(f'{status} {lh}/{lf} = {pct:.1f}%')
"
  cd ..
done
```

**最终验收标准:**
- [ ] koi_printer_command ≥ 95%
- [ ] koi_printer_connection ≥ 90%
- [ ] koi_printer_editor ≥ 90%
- [ ] koi_printer ≥ 90%
- [ ] 所有包 Lint 0 issues
- [ ] CI 绿色
- [ ] 全部 commit 并 push
