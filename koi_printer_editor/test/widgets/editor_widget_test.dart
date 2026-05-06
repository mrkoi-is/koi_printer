import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/widgets/left_palette.dart';
import 'package:provider/provider.dart';

void main() {
  Widget buildTestApp(Widget child, EditorState state) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<EditorState>.value(
          value: state,
          child: child,
        ),
      ),
    );
  }

  group('LeftPalette Widget Tests', () {
    testWidgets('Renders 3 tabs and can switch between them', (
      WidgetTester tester,
    ) async {
      final state = EditorState();

      await tester.pumpWidget(buildTestApp(const LeftPalette(), state));
      await tester.pumpAndSettle();

      // Should find 3 tabs
      expect(find.text('组件库'), findsOneWidget);
      expect(find.text('图层'), findsOneWidget);
      expect(find.text('数据源'), findsOneWidget);

      // Verify Component tab is active
      expect(find.text('文本 (Text)'), findsOneWidget);

      // Tap on Layers tab
      await tester.tap(find.text('图层'));
      await tester.pumpAndSettle();
      expect(find.text('画布为空'), findsOneWidget);

      // Tap on Data tab
      await tester.tap(find.text('数据源'));
      await tester.pumpAndSettle();
      expect(find.text('单据模型: 自定义'), findsOneWidget);
    });

    testWidgets('Tapping on a component adds it to the EditorState', (
      WidgetTester tester,
    ) async {
      final state = EditorState();

      await tester.pumpWidget(buildTestApp(const LeftPalette(), state));
      await tester.pumpAndSettle();

      expect(state.elements.length, 0);

      // Tap to add text element
      await tester.tap(find.text('文本 (Text)'));
      await tester.pumpAndSettle();

      expect(state.elements.length, 1);
      expect(
        state.elements.first.element.runtimeType.toString(),
        'KoiTextElement',
      );
    });
  });
}
