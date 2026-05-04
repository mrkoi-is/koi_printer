import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_example/src/screens/koi_device_management_screen.dart';
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
        children: [
          PreviewScreen(
            onNavigateToDeviceManagement: () =>
                setState(() => _currentIndex = 1),
          ),
          const KoiDeviceManagementScreen(),
        ],
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
  const PreviewScreen({super.key, required this.onNavigateToDeviceManagement});

  final VoidCallback onNavigateToDeviceManagement;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  KoiPrintConfig _config = const KoiPrintConfig();
  int _templateIndex = 0;

  final _templates = [
    ('TMS 动态模板 (JSON+Engine)', const KoiDynamicTemplateDemo()),
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
    final effectiveConfig = _config;

    // Generate documents from template
    // We pass dynamic map or void depending on the generic constraint, safely casted.
    final dynamicTemplate = templateTuple.$2 as dynamic;
    final docs = (templateTuple.$1 == '功能测试页')
        ? dynamicTemplate.build(null, effectiveConfig) as List<KoiPrintDocument>
        : dynamicTemplate.build(_mockData, effectiveConfig)
              as List<KoiPrintDocument>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模板预览'),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.tune),
                tooltip: '打印参数配置',
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              );
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                '通用配置',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              DropdownButton<KoiPaperSize>(
                isExpanded: true,
                value: effectiveConfig.paperSize,
                items: const [
                  DropdownMenuItem(
                    value: KoiPaperSize.mm58,
                    child: Text('58mm (384点宽)'),
                  ),
                  DropdownMenuItem(
                    value: KoiPaperSize.mm80,
                    child: Text('80mm (576点宽)'),
                  ),
                ],
                onChanged: (v) =>
                    setState(() => _config = _config.copyWith(paperSize: v)),
              ),
              const SizedBox(height: 16),
              const Text('打印份数:'),
              Slider(
                value: effectiveConfig.copies.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: effectiveConfig.copies.toString(),
                onChanged: (v) => setState(
                  () => _config = _config.copyWith(copies: v.toInt()),
                ),
              ),
              const SizedBox(height: 8),
              const Text('顶部空行:'),
              Slider(
                value: effectiveConfig.headerEmptyLines.toDouble(),
                min: 0,
                max: 10,
                divisions: 10,
                label: effectiveConfig.headerEmptyLines.toString(),
                onChanged: (v) => setState(
                  () => _config = _config.copyWith(headerEmptyLines: v.toInt()),
                ),
              ),
              const Divider(height: 32),
              if (!isLabel) ...[
                const Text(
                  '小票样式参数',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButton<KoiStubType>(
                  isExpanded: true,
                  value: effectiveConfig.stubType,
                  items: KoiStubType.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _config = _config.copyWith(stubType: v)),
                ),
                const SizedBox(height: 16),
                DropdownButton<KoiCutBehavior>(
                  isExpanded: true,
                  value: effectiveConfig.cutBehavior,
                  items: KoiCutBehavior.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
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
                const SizedBox(height: 16),
                DropdownButton<KoiLabelStyle>(
                  isExpanded: true,
                  value: effectiveConfig.labelStyle,
                  items: KoiLabelStyle.values
                      .map(
                        (e) => DropdownMenuItem(value: e, child: Text(e.name)),
                      )
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _config = _config.copyWith(labelStyle: v)),
                ),
              ],
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // 顶部模板选择器
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _templateIndex,
                items: List.generate(
                  _templates.length,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(
                      _templates[i].$1,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                onChanged: (v) => setState(() => _templateIndex = v ?? 0),
              ),
            ),
          ),
          const Divider(height: 1),
          // 渲染预览区
          Expanded(
            child: Container(
              color: Colors.grey.shade200,
              child: ListView.separated(
                padding: const EdgeInsets.only(
                  top: 16,
                  bottom: 80,
                  left: 16,
                  right: 16,
                ),
                itemCount: docs.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 24),
                itemBuilder: (context, i) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '第 ${i + 1} 联: ${docs[i].name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.contain,
                          alignment: Alignment.topCenter,
                          child: KoiPreviewRenderer.build(
                            document: docs[i],
                            paperWidthPx:
                                effectiveConfig.paperSize == KoiPaperSize.mm80
                                ? 576
                                : 384, // 动态适配纸张真实点数
                            fontFamily: 'SarasaMono', // 启用严格 1:2 等宽点阵渲染
                          ),
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
      floatingActionButton: FloatingActionButton.small(
        onPressed: () {
          if (globalTicketDevices.isNotEmpty) {
            final device = globalTicketDevices.first;
            executePrintJob(context, device, docs);
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('请先前往设置页面绑定打印机')));
            widget.onNavigateToDeviceManagement();
          }
        },
        child: const Icon(Icons.print),
      ),
    );
  }
}
