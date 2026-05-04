import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:koi_printer_editor/editor_screen.dart';
import 'package:koi_printer_editor/mock_templates.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) {
        final state = EditorState(initialElements: defaultTemplateElements);
        // 同步 Schema、mockData、manifest 身份 (避免初始状态为空)
        state.loadManifest(defaultManifest, defaultTemplateElements);
        return state;
      },
      child: const KoiPrinterEditorApp(),
    ),
  );
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
      home: const EditorScreen(),
    );
  }
}
