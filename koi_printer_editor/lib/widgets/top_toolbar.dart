import 'package:flutter/material.dart';
import 'package:koi_printer_editor/mock_templates.dart';
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
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.grid_view, size: 18),
            label: const Text('模板大厅'),
            onPressed: () => _showTemplateGallery(context),
          ),
          const SizedBox(width: 8),
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

          // 预览模式切换
          Row(
            children: [
              Text('编辑', style: TextStyle(color: state.isPreviewMode ? Colors.grey : theme.colorScheme.primary, fontWeight: FontWeight.bold)),
              Switch(
                value: state.isPreviewMode,
                onChanged: (_) => context.read<EditorState>().togglePreviewMode(),
                activeColor: theme.colorScheme.primary,
              ),
              Text('预览 (假数据)', style: TextStyle(color: state.isPreviewMode ? theme.colorScheme.primary : Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 24),
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

  void _showTemplateGallery(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('选择模板'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: templateGallery.keys.map((key) {
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      context.read<EditorState>().loadTemplate(templateGallery[key]!);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          key,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }
}
