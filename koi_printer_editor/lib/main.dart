import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koi_printer_editor/editor_screen.dart';
import 'package:koi_printer_editor/mock_templates.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/utils/template_loader.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KoiPrinterEditorApp());
}

class KoiPrinterEditorApp extends StatelessWidget {
  const KoiPrinterEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Koi Printer Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      themeMode: ThemeMode.system,
      home: const _BootstrapScreen(),
    );
  }
}

/// 启动引导页：异步加载模板 → 完成后进入编辑器。
/// 加载期间显示品牌 Splash，避免白屏。
class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final loaded = await KoiTemplateLoader.loadAllTemplates();
    TemplateRegistry.instance.initialize(loaded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        // 加载出错
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('模板加载失败: ${snapshot.error}'),
                ],
              ),
            ),
          );
        }

        // 加载中 → Splash
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print, size: 64, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Koi Printer Studio',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(width: 200, child: LinearProgressIndicator()),
                  const SizedBox(height: 8),
                  Text('正在加载模板...', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        // 加载完成 → 进入编辑器
        return ChangeNotifierProvider(
          create: (_) {
            final state = EditorState(initialElements: defaultTemplateElements);
            if (defaultManifest != null) {
              state.loadManifest(defaultManifest!, defaultTemplateElements);
            }
            return state;
          },
          child: const EditorScreen(),
        );
      },
    );
  }
}
