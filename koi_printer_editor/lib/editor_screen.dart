import 'package:flutter/material.dart';
import 'package:koi_printer_editor/widgets/center_canvas.dart';
import 'package:koi_printer_editor/widgets/left_palette.dart';
import 'package:koi_printer_editor/widgets/right_inspector.dart';
import 'package:koi_printer_editor/widgets/top_toolbar.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TopToolbar(),
          Expanded(
            child: Row(
              children: [
                const LeftPalette(),
                const Expanded(child: CenterCanvas()),
                const RightInspector(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
