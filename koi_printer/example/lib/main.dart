import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/template/koi_templates.dart';

// Mock Data for the templates
final _mockData = <String, dynamic>{
  'waybillNo': 'YT1234567890987',
  'senderName': '李清照',
  'senderCity': '杭州市',
  'receiverName': '苏轼',
  'receiverInfo': '苏轼 13912345678',
  'receiverCity': '眉山市',
  'address': '四川省眉山市东坡区三苏祠',
  'routeNo': 'BJ-SH-001',
  'driver': '张三丰',
  'totalPackages': 156,
  'code': '8872',
  'location': 'A区-03架',
  'orderNo': 'PO202602260001',
  'amount': '128.50',
  'method': '微信支付',
  'items': [
    {'name': '丝绸长裙', 'count': 2, 'weight': 0.8},
    {'name': '西湖龙井礼盒', 'count': 1, 'weight': 1.2},
  ],
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Storage and Preferences
  final sharedPrefs = await SharedPreferences.getInstance();
  final storage = KoiPrinterStorage(sharedPrefs);
  final prefs = KoiUserPreferences(sharedPrefs);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        Provider.value(value: prefs),
      ],
      child: const KoiPrinterExampleApp(),
    ),
  );
}

class KoiPrinterExampleApp extends StatelessWidget {
  const KoiPrinterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koi Printer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [PreviewScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (v) => setState(() => _currentIndex = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.preview), label: '预览与模板'),
          NavigationDestination(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  KoiPrintConfig _config = const KoiPrintConfig();
  int _templateIndex = 0;

  final _templates = [
    ('寄件小票 (多联)', const KoiSenderTicketTemplate()),
    ('到件小票', const KoiReceiverTicketTemplate()),
    ('交接单', const KoiDeliveryNoteTemplate()),
    ('寄存凭条', const KoiDepositTemplate()),
    ('退款凭证', const KoiFinanceTicketTemplate(isPayment: true)),
    ('收款凭证', const KoiFinanceTicketTemplate(isPayment: false)),
    ('功能测试页', const KoiTestTicketTemplate()),
    ('寄件标签 (6种样式)', const KoiSenderLabelTemplate()),
  ];

  @override
  Widget build(BuildContext context) {
    final templateTuple = _templates[_templateIndex];
    final isLabel = templateTuple.$1.contains('标签');

    // Auto-adjust layout mode based on template type selection
    // Note: copies does not exist on KoiPrintConfig in `const`, need a safe copyWith if we use dynamic values
    final effectiveConfig = isLabel
        ? _config.copyWith(paperSize: KoiPaperSize.mm80)
        : _config;

    // Generate documents from template
    // We pass dynamic map or void depending on the generic constraint, safely casted.
    final dynamicTemplate = templateTuple.$2 as dynamic;
    final docs =
        (isLabel ||
            templateTuple.$1.contains('联') ||
            templateTuple.$1.contains('单') ||
            templateTuple.$1.contains('证') ||
            templateTuple.$1.contains('条'))
        ? dynamicTemplate.build(_mockData, effectiveConfig)
              as List<KoiTicketDocument>
        : dynamicTemplate.build(null, effectiveConfig)
              as List<KoiTicketDocument>;

    return Scaffold(
      appBar: AppBar(title: const Text('模板预览 (KoiPreviewRenderer)')),
      body: Row(
        children: [
          // 左侧：配置面板
          Expanded(
            flex: 1,
            child: Card(
              margin: const EdgeInsets.all(8),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    '选择模板',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<int>(
                    isExpanded: true,
                    value: _templateIndex,
                    items: List.generate(
                      _templates.length,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text(_templates[i].$1),
                      ),
                    ),
                    onChanged: (v) => setState(() => _templateIndex = v ?? 0),
                  ),
                  const Divider(),
                  const Text(
                    '通用配置',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      const Text('打印份数: '),
                      Expanded(
                        child: Slider(
                          value: effectiveConfig.copies.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          label: effectiveConfig.copies.toString(),
                          onChanged: (v) => setState(
                            () => _config = _config.copyWith(copies: v.toInt()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('顶部空行: '),
                      Expanded(
                        child: Slider(
                          value: effectiveConfig.headerEmptyLines.toDouble(),
                          min: 0,
                          max: 10,
                          divisions: 10,
                          label: effectiveConfig.headerEmptyLines.toString(),
                          onChanged: (v) => setState(
                            () => _config = _config.copyWith(
                              headerEmptyLines: v.toInt(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (!isLabel) ...[
                    const Text(
                      '小票样式参数',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<KoiStubType>(
                      isExpanded: true,
                      value: effectiveConfig.stubType,
                      items: KoiStubType.values
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _config = _config.copyWith(stubType: v),
                      ),
                    ),
                    DropdownButton<KoiCutBehavior>(
                      isExpanded: true,
                      value: effectiveConfig.cutBehavior,
                      items: KoiCutBehavior.values
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _config = _config.copyWith(cutBehavior: v),
                      ),
                    ),
                  ] else ...[
                    const Text(
                      '标签样式参数',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<KoiLabelStyle>(
                      isExpanded: true,
                      value: effectiveConfig.labelStyle,
                      items: KoiLabelStyle.values
                          .map(
                            (e) =>
                                DropdownMenuItem(value: e, child: Text(e.name)),
                          )
                          .toList(),
                      onChanged: (v) => setState(
                        () => _config = _config.copyWith(labelStyle: v),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 右侧：渲染预览区 (使用 KoiPreviewRenderer)
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey.shade200,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 16,
                ),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 32),
                itemBuilder: (context, i) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '第 ${i + 1} 联: ${docs[i].name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        KoiPreviewRenderer.build(
                          docs[i],
                          paperWidthPx: isLabel ? 300 : 380, // 根据类型给个预览基础宽度
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('打印机管理与发送在设置页配置并调用。')));
        },
        icon: const Icon(Icons.print),
        label: const Text('打印测试'),
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 真实应用中，这里使用 KoiPrinterManager 扫描并连接设备。
    return Scaffold(
      appBar: AppBar(title: const Text('打印机设置及全局偏好')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            title: Text('搜索并连接小票机 (Bluetooth)'),
            subtitle: Text('未连接'),
            trailing: Icon(Icons.bluetooth_searching),
          ),
          Divider(),
          ListTile(
            title: Text('搜索并连接标签机 (Bluetooth)'),
            subtitle: Text('未连接'),
            trailing: Icon(Icons.bluetooth_searching),
          ),
          Divider(),
          ListTile(
            title: Text('关于 Koi Printer Ecosystem'),
            subtitle: Text('Powered by xii_engine architecture V4.0'),
          ),
        ],
      ),
    );
  }
}
