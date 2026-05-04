import 'package:flutter/material.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

class TopToolbar extends StatelessWidget {
  const TopToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final theme = Theme.of(context);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.print, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'Koi Printer Studio',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 24),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          const SizedBox(width: 8),
          
          // Paper size dropdown mock
          DropdownButton<String>(
            value: '80mm',
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: '58mm', child: Text('58mm 小票')),
              DropdownMenuItem(value: '80mm', child: Text('80mm 小票')),
              DropdownMenuItem(value: '100x150', child: Text('100x150 面单')),
            ],
            onChanged: (_) {},
          ),
          
          const Spacer(),
          
          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo ? () => context.read<EditorState>().undo() : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: state.canRedo ? () => context.read<EditorState>().redo() : null,
            tooltip: '重做',
          ),
          
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: () {
              // TODO: Implement save & publish
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已保存至云端')),
              );
            },
            icon: const Icon(Icons.cloud_upload, size: 18),
            label: const Text('保存发布'),
          ),
        ],
      ),
    );
  }
}
