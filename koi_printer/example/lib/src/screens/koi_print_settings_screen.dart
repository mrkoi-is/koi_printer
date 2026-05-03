import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 打印设置界面。
/// 迁移自旧 XIIPrintSettingsScreen (164 LOC)。
///
/// 使用 [KoiUserPreferences] 读写配置, 支持:
/// - 存根类型切换 (none / withStub)
/// - 打印样式 (normal / large)
/// - 标签样式 (6 种)
/// - 切纸设置 (按联 / 结尾 / 不切)
/// - 收货联顶部空行数
class KoiPrintSettingsScreen extends StatefulWidget {
  const KoiPrintSettingsScreen({super.key});

  @override
  State<KoiPrintSettingsScreen> createState() => _KoiPrintSettingsScreenState();
}

class _KoiPrintSettingsScreenState extends State<KoiPrintSettingsScreen> {
  KoiUserPreferences? _prefs;
  final TextEditingController _headerLinesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    final sp = await SharedPreferences.getInstance();
    setState(() {
      _prefs = KoiUserPreferences(sp);
      _headerLinesController.text = _prefs!.headerEmptyLines.toString();
    });
  }

  @override
  void dispose() {
    _headerLinesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final prefs = _prefs!;

    return Scaffold(
      appBar: AppBar(title: const Text('打印设置')),
      body: ListView(
        children: [
          // ── 打印设置区 ──
          _sectionHeader('打印设置'),

          // 存根类型
          ListTile(
            title: const Text('存根联打印'),
            subtitle: const Text('控制是否同时打印存根联'),
            trailing: Text(prefs.stubType.name),
            onTap: () async {
              await prefs.switchStubType();
              setState(() {});
            },
          ),

          // 打印样式
          ListTile(
            title: const Text('打印样式'),
            subtitle: const Text('标准 / 大字'),
            trailing: Text(prefs.printStyle.name),
            onTap: () async {
              await prefs.switchPrintStyle();
              setState(() {});
            },
          ),

          // 标签样式
          ListTile(
            title: const Text('标签样式'),
            subtitle: const Text('6 种企业标签布局'),
            trailing: Text(prefs.labelStyle.name),
            onTap: () async {
              await prefs.switchLabelStyle();
              setState(() {});
            },
          ),

          // 收货联顶部空行
          ListTile(
            title: const Text('提货客户联顶部空行'),
            trailing: SizedBox(
              width: 80,
              height: 50,
              child: TextField(
                textAlign: TextAlign.center,
                controller: _headerLinesController,
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final count = int.tryParse(value) ?? 0;
                  prefs.setHeaderEmptyLines(count < 0 ? 0 : count);
                },
              ),
            ),
          ),

          // ── 切纸设置区 ──
          _sectionHeader('切纸设置'),

          // 按联切纸
          SwitchListTile(
            title: const Text('按联切纸'),
            subtitle: const Text('每联打完后自动切纸'),
            activeColor: Colors.orange,
            value: prefs.isCutEnabled(KoiCutBehavior.cutPerCopy),
            onChanged: (v) async {
              await prefs.setCutEnabled(
                behavior: KoiCutBehavior.cutPerCopy,
                enabled: v,
              );
              setState(() {});
            },
          ),
          const Divider(),

          // 结尾切纸
          SwitchListTile(
            title: const Text('结尾切纸'),
            subtitle: const Text('整单打完后切纸'),
            activeColor: Colors.orange,
            value: prefs.isCutEnabled(KoiCutBehavior.cutAtEnd),
            onChanged: (v) async {
              await prefs.setCutEnabled(
                behavior: KoiCutBehavior.cutAtEnd,
                enabled: v,
              );
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      color: Colors.grey.shade300,
      padding: const EdgeInsets.all(8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
