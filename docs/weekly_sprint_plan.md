# Koi Printer 生态系统 — 一周冲刺计划
# Koi Printer Ecosystem — Weekly Sprint Plan

> **制定日期 / Created:** 2026-05-05  
> **冲刺周期 / Sprint:** 2026-05-05 (Mon) → 2026-05-11 (Sun)  
> **目标 / Objective:** 全包测试覆盖率 ≥ 90%，Lint 清零，代码质量达到发布标准

---

## 📊 当前基线 / Current Baseline

| Package | Version | Coverage | Tests | Lint Issues | Target |
|:---|:---:|:---:|:---:|:---:|:---:|
| koi_printer_command | 0.1.0 | **97.0%** | 142 | 15 | 维持 ✅ |
| koi_printer_connection | 0.1.0 | **93.6%** | 64 | 28 | ≥90% ✅ |
| koi_printer_editor | 0.1.0+1 | **89.2%** | 29 | 0 | ≥90% |
| koi_printer | 0.1.0 | **80.1%** | 176 | 17 | ≥90% |
| **TOTAL** | - | - | **411** | **79** (info-level) | - |

### Lint Issues 分类（79 条 info-level）
- `cascade_invocations`: 22 条 — 可用 `dart fix --apply` 自动修复
- `avoid_catches_without_on_clauses`: 19 条 — 需手动改 `catch` 为 `on Object catch`
- `lines_longer_than_80_chars`: 17 条 — 需手动换行
- `discarded_futures`: 7 条 — 需要加 `unawaited()` 或 `await`
- 其他: 14 条（`deprecated_member_use`, `avoid_print`, `sort_pub_dependencies` 等）

---

## 📅 每日任务安排 / Daily Task Schedule

---

### Day 1 (Mon 5/5) — Git 提交 + koi_printer_connection 收尾

#### CHECKPOINT 1: 提交 koi_printer_connection 测试成果

**目标:** 将已完成的 koi_printer_connection 测试代码提交到仓库。

**步骤:**
```
1. 进入 koi_printer_connection 目录
2. 运行 `flutter test --coverage` 确认全部通过
3. 运行覆盖率统计确认 ≥ 93%
4. 执行 `git add .` 暂存所有变更
5. 执行 `git commit -m "test(connection): achieve 93.6% coverage with DI refactor for BLE scanner"`
```

**验收标准:**
- [x] 64 tests all pass
- [x] Coverage ≥ 93%
- [x] Commit 成功

#### CHECKPOINT 2: koi_printer_connection Lint 修复

**目标:** 清理 koi_printer_connection 包的 28 条 lint issues。

**步骤:**
```
1. 运行 `dart fix --apply` 自动修复 cascade_invocations 等
2. 手动修复 `avoid_catches_without_on_clauses` — 将 `catch (e)` 改为 `on Object catch (e)`
3. 修复 `lines_longer_than_80_chars` — 将长行拆分
4. 修复 `deprecated_member_use` — 移除 FBP 废弃的 connecting/disconnecting 状态引用
5. 运行 `flutter analyze` 确认 0 issues
6. 运行 `flutter test` 确认无回归
7. `git commit -m "fix(connection): resolve all lint issues"`
```

**验收标准:**
- [ ] `flutter analyze` 输出 0 issues（或仅 info-level）
- [ ] All tests still pass

**预计用时:** 1 hour

---

### Day 2 (Tue 5/6) — koi_printer 核心：koi_element_editor.dart Widget 测试 (Part 1)

#### CHECKPOINT 3: KoiElementEditor 基础元素 Widget 测试

**目标:** 为 `koi_element_editor.dart` 的 `KoiTextElement`, `KoiBarcodeElement`, `KoiQrCodeElement` 三种基础元素编写 Widget 测试。

**背景:** 这个文件是 636 行的 StatefulWidget，当前覆盖率仅 43.1% (140/325)，是整个 koi_printer 包 80.1% 覆盖率的唯一拖后腿文件。

**文件位置:**
- 源码: `koi_printer/lib/src/editor/koi_element_editor.dart`
- 测试: `koi_printer/test/koi_element_editor_test.dart`（已存在，需要扩展）

**步骤:**
```
1. 查看现有 koi_element_editor_test.dart 了解已有测试模式
2. 为 KoiTextElement 编写 Widget 测试:
   - pumpWidget 一个 MaterialApp 包裹的 KoiElementEditor<KoiTextElement>
   - 验证文本输入框显示并能触发 onChanged
   - 验证对齐方式下拉菜单
   - 验证字体大小下拉菜单
   - 验证加粗/反白开关
3. 为 KoiBarcodeElement 编写 Widget 测试:
   - 验证条码数据输入
   - 验证对齐方式下拉
4. 为 KoiQrCodeElement 编写 Widget 测试:
   - 验证 QR 数据输入
   - 验证对齐方式下拉
5. 运行 `flutter test test/koi_element_editor_test.dart` 确认通过
```

**验收标准:**
- [ ] 3 种基础元素的 Widget 测试全部通过
- [ ] `koi_element_editor.dart` 覆盖率提升至 ≥ 60%
- [ ] `git commit -m "test(printer): add widget tests for basic element editors"`

**预计用时:** 3 hours

---

### Day 3 (Wed 5/7) — koi_printer 核心：koi_element_editor.dart Widget 测试 (Part 2)

#### CHECKPOINT 4: KoiElementEditor 定位元素 Widget 测试

**目标:** 为 `KoiPositionedTextElement`, `KoiPositionedBarcodeElement`, `KoiPositionedQrCodeElement` 三种定位元素编写 Widget 测试。

**步骤:**
```
1. 为 KoiPositionedTextElement 编写 Widget 测试:
   - 验证 X/Y 坐标输入
   - 验证文本输入
   - 验证加粗开关
   - 验证 _parseInt fallback 逻辑（输入非数字时）
2. 为 KoiPositionedBarcodeElement 编写:
   - 验证 X/Y + Data 输入
3. 为 KoiPositionedQrCodeElement 编写:
   - 验证 X/Y + Data 输入
4. 运行覆盖率检查
```

**验收标准:**
- [ ] 6 种元素类型的 Widget 测试全部通过
- [ ] `koi_element_editor.dart` 覆盖率提升至 ≥ 75%
- [ ] `git commit -m "test(printer): add widget tests for positioned element editors"`

**预计用时:** 2.5 hours

#### CHECKPOINT 5: KoiElementEditor 标签元素 + 边界情况

**目标:** 补充 `KoiLabelBoxElement`, `KoiLabelReverseElement` 和不支持元素类型的测试。

**步骤:**
```
1. 为 KoiLabelBoxElement 编写:
   - 验证 X/Y 坐标输入
2. 为 KoiLabelReverseElement 编写:
   - 验证 X/Y 坐标输入
3. 验证 "不支持的元素类型" 回退显示
4. 验证 didUpdateWidget 路径:
   - 先用一种元素 pump，再换另一种元素 pump
5. 验证 _initControllers 各分支
6. 运行 `flutter test --coverage` 获取整包覆盖率
```

**验收标准:**
- [ ] `koi_element_editor.dart` 覆盖率 ≥ 85%
- [ ] `koi_printer` 整包覆盖率 ≥ 90%
- [ ] `git commit -m "test(printer): complete element editor coverage to 85%+"`

**预计用时:** 2 hours

---

### Day 4 (Thu 5/8) — koi_printer_editor 补齐 + koi_printer Lint 清理

#### CHECKPOINT 6: editor_command.dart 测试补齐

**目标:** 将 `editor_command.dart` 覆盖率从 70.5% 提升至 ≥ 90%。

**文件位置:**
- 源码: `koi_printer_editor/lib/state/editor_command.dart`
- 测试: `koi_printer_editor/test/` 下新建或扩展

**未覆盖代码分析（23 行）:**
- `AddElementCommand.execute`: 带 `parentId` 和 `index` 的子元素插入路径（L20-L38）
- `AddElementCommand.undo`: 带 `parentId` 的子元素移除路径（L56-L70）

**步骤:**
```
1. 阅读 editor_command.dart 了解 AddElementCommand 的 parentId 逻辑
2. 编写测试:
   - AddElementCommand 带 parentId 到 KoiTicketForEachElement 的子元素插入
   - AddElementCommand 带 index 指定位置插入
   - AddElementCommand.undo 从 KoiTicketForEachElement 中移除子元素
   - parentId 不存在时的 no-op 情况
3. 运行 `flutter test --coverage`
4. 确认 editor_command.dart ≥ 90%
5. 确认 koi_printer_editor 整包 ≥ 93%
```

**验收标准:**
- [ ] `editor_command.dart` 覆盖率 ≥ 90%
- [ ] `koi_printer_editor` 整包覆盖率 ≥ 93%
- [ ] `git commit -m "test(editor): cover AddElementCommand parentId/index branches"`

**预计用时:** 1.5 hours

#### CHECKPOINT 7: koi_printer + koi_printer_command Lint 清理

**目标:** 修复 koi_printer（17条）和 koi_printer_command（15条）的 lint issues。

**步骤:**
```
1. koi_printer_command:
   - `cd koi_printer_command && dart fix --apply`
   - 手动修复 lines_longer_than_80_chars (5处)
   - 修复 missing_whitespace_between_adjacent_strings (3处)
   - 修复 sort_pub_dependencies (pubspec.yaml)
   - 修复 avoid_print (test_raster.dart)
   - `flutter analyze` 确认清零
   - `flutter test` 确认无回归
   
2. koi_printer:
   - `cd koi_printer && dart fix --apply`
   - 手动修复 avoid_catches_without_on_clauses
   - 修复 lines_longer_than_80_chars
   - 修复 comment_references
   - `flutter analyze` 确认清零
   - `flutter test` 确认无回归
   
3. `git commit -m "fix: resolve all lint issues in koi_printer and koi_printer_command"`
```

**验收标准:**
- [ ] 两个包 `flutter analyze` 均为 0 issues
- [ ] All tests still pass
- [ ] Committed

**预计用时:** 2 hours

---

### Day 5 (Fri 5/9) — koi_printer 精细覆盖 + koi_printer_manager 补漏

#### CHECKPOINT 8: koi_printer_manager.dart 未覆盖行修复

**目标:** 覆盖 `koi_printer_manager.dart` 的 6 行未覆盖代码（L199-201, L220-222）。

**步骤:**
```
1. 查看 koi_printer_manager.dart L199-222 确认未覆盖逻辑
2. 可能是 connectAll 的某些错误路径或特定设备类型组合
3. 编写针对性测试用例
4. 运行 `flutter test --coverage`
```

**验收标准:**
- [ ] koi_printer_manager.dart ≥ 97%
- [ ] Tests pass

#### CHECKPOINT 9: koi_preview_renderer.dart + koi_print_job_queue.dart 补漏

**目标:** 修复 `koi_preview_renderer.dart`（2行: L137, L143）和 `koi_print_job_queue.dart`（2行: L129, L130）的覆盖缺口。

**步骤:**
```
1. 查看未覆盖行的具体代码
2. 编写针对性测试
3. 运行覆盖率确认
4. `git commit -m "test(printer): close coverage gaps in manager, preview, and job queue"`
```

**验收标准:**
- [ ] koi_preview_renderer.dart ≥ 99%
- [ ] koi_print_job_queue.dart ≥ 99%
- [ ] koi_printer 整包确认 ≥ 92%

**预计用时:** 2 hours

---

### Day 6 (Sat 5/10) — CI 加固 + 文档更新

#### CHECKPOINT 10: GitHub Actions CI 增加覆盖率门槛

**目标:** 在 CI pipeline 中加入覆盖率最低门槛检查。

**步骤:**
```
1. 编辑 .github/workflows/ci.yml
2. 在每个包的 test step 后添加覆盖率检查:
   - 使用 lcov.info 解析覆盖率
   - 如果低于 85% 则失败
3. 可选：添加覆盖率 badge 生成
4. Push 并验证 CI 通过
```

**验收标准:**
- [ ] CI 包含覆盖率门槛检查
- [ ] main 分支 CI 绿色通过

#### CHECKPOINT 11: README 和 CHANGELOG 更新

**目标:** 更新各包的文档反映当前测试成果。

**步骤:**
```
1. 更新 koi_printer/README.md 中的测试覆盖率数据
2. 更新各包 CHANGELOG.md 记录测试改进
3. 清理 docs/ 中过期的规划文件
4. `git commit -m "docs: update coverage metrics and changelogs"`
```

**预计用时:** 1.5 hours

---

### Day 7 (Sun 5/11) — 缓冲日 + 全面验证

#### CHECKPOINT 12: 最终全量验证

**目标:** 运行全部包的测试+覆盖率+Lint，生成最终报告。

**步骤:**
```
1. 对每个包依次运行:
   - `flutter analyze`（或 `dart analyze`）
   - `flutter test --coverage`
   - 生成覆盖率报告
2. 确认全包覆盖率 ≥ 90%
3. 确认 Lint issues = 0
4. 如有未达标项，利用缓冲时间修补
5. 最终 commit + push
```

**最终验收标准:**
- [ ] koi_printer_command ≥ 95% ✅
- [ ] koi_printer_connection ≥ 90% ✅
- [ ] koi_printer_editor ≥ 90%
- [ ] koi_printer ≥ 90%
- [ ] 所有包 Lint = 0
- [ ] CI 绿色

---

## 📈 预期覆盖率提升曲线

```
Day 1: connection 93.6% ✅ (已完成, 提交)
Day 2: printer    ~72% → ~82% (基础元素 editor 测试)
Day 3: printer    ~82% → ~92% (定位+标签 editor 测试)
Day 4: editor     89.2% → 93%+ (command 测试)
Day 5: printer    ~92% → 95%+ (manager/preview/queue 补漏)
Day 6: CI + Docs
Day 7: 全量验证
```

---

## ⚠️ 风险与注意事项

> [!WARNING]
> **Day 2-3 的 `koi_element_editor.dart` Widget 测试是最大工作量**。
> 这个文件有 8 种元素类型 × 各自不同的 UI 控件 = 大量重复但必要的 `pumpWidget` 测试。
> 建议使用 helper 函数减少样板代码。

> [!NOTE]
> 所有 Checkpoint 都设计为**可独立执行**的原子任务。
> Gemini 可以按顺序逐个 Checkpoint 领取执行。
> 每个 Checkpoint 都有明确的「验收标准」和「步骤」。

> [!TIP]
> `dart fix --apply` 可以自动修复约 30% 的 lint issues（主要是 `cascade_invocations`）。
> 优先运行它，然后再手动修复剩余问题。

---

## 🔧 实用命令参考

```bash
# 单包测试+覆盖率
flutter test --coverage && \
python3 -c "
with open('coverage/lcov.info') as f:
  lf=lh=0
  for l in f:
    if l.startswith('LF:'): lf+=int(l[3:])
    elif l.startswith('LH:'): lh+=int(l[3:])
  print(f'{lh}/{lf} = {lh/lf*100:.1f}%')
"

# 全包一次性检查
for pkg in koi_printer_command koi_printer_connection koi_printer koi_printer_editor; do
  echo "=== $pkg ===" && cd $pkg && flutter test --coverage 2>&1 | tail -3 && cd ..
done

# 自动修复 lint
dart fix --apply

# 格式化检查
dart format --output=none --set-exit-if-changed .
```
