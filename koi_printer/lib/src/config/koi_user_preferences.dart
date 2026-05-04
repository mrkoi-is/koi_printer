import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户打印偏好 — 切纸/样式/标签 等用户自定义设置。
/// 来源: 旧 XIIPrintSettings (176 LOC, Singleton)
/// 改进: 构造函数注入 (无 Singleton), 使用 Dart 3 enum。
class KoiUserPreferences {
  /// 构造用户偏好设置实例，依赖 SharedPreferences。
  KoiUserPreferences(this._prefs);

  final SharedPreferences _prefs;

  static const _cutPrefix = 'koi_cut_';
  static const _stubTypeKey = 'koi_stub_type';
  static const _printStyleKey = 'koi_print_style';
  static const _labelStyleKey = 'koi_label_style';
  static const _headerLinesKey = 'koi_header_empty_lines';

  // ── 切纸偏好 ──

  /// 获取指定场景的切纸偏好。
  bool isCutEnabled(KoiCutBehavior behavior) {
    final key = '$_cutPrefix${behavior.index}';
    return _prefs.getBool(key) ?? _cutDefault(behavior);
  }

  /// 设置切纸偏好。
  Future<bool> setCutEnabled({
    required KoiCutBehavior behavior,
    required bool enabled,
  }) {
    final key = '$_cutPrefix${behavior.index}';
    return _prefs.setBool(key, enabled);
  }

  bool _cutDefault(KoiCutBehavior behavior) {
    return switch (behavior) {
      KoiCutBehavior.cutPerCopy => true,
      KoiCutBehavior.cutAtEnd => true,
      KoiCutBehavior.noCut => false,
    };
  }

  // ── 存根类型 ──

  /// 获取发货小票存根类型。
  KoiStubType get stubType {
    final index = _prefs.getInt(_stubTypeKey);
    if (index == null || index >= KoiStubType.values.length) {
      return KoiStubType.withStub;
    }
    return KoiStubType.values[index];
  }

  /// 设置存根类型。
  Future<bool> setStubType(KoiStubType type) {
    return _prefs.setInt(_stubTypeKey, type.index);
  }

  /// 循环切换存根类型。
  Future<bool> switchStubType() {
    final nextIndex = (stubType.index + 1) % KoiStubType.values.length;
    return _prefs.setInt(_stubTypeKey, nextIndex);
  }

  // ── 打印样式 ──

  /// 获取打印样式。
  KoiPrintStyle get printStyle {
    final index = _prefs.getInt(_printStyleKey);
    if (index == null || index >= KoiPrintStyle.values.length) {
      return KoiPrintStyle.normal;
    }
    return KoiPrintStyle.values[index];
  }

  /// 循环切换打印样式。
  Future<bool> switchPrintStyle() {
    final nextIndex = (printStyle.index + 1) % KoiPrintStyle.values.length;
    return _prefs.setInt(_printStyleKey, nextIndex);
  }

  // ── 标签样式 ──

  /// 获取标签样式。
  KoiLabelStyle get labelStyle {
    final index = _prefs.getInt(_labelStyleKey);
    if (index == null || index >= KoiLabelStyle.values.length) {
      return KoiLabelStyle.style1;
    }
    return KoiLabelStyle.values[index];
  }

  /// 循环切换标签样式。
  Future<bool> switchLabelStyle() {
    final nextIndex = (labelStyle.index + 1) % KoiLabelStyle.values.length;
    return _prefs.setInt(_labelStyleKey, nextIndex);
  }

  // ── 收货联顶部空行 ──

  /// 获取收货联顶部空行数。
  int get headerEmptyLines => _prefs.getInt(_headerLinesKey) ?? 0;

  /// 设置收货联顶部空行数。
  Future<bool> setHeaderEmptyLines(int lines) {
    return _prefs.setInt(_headerLinesKey, lines);
  }
}
