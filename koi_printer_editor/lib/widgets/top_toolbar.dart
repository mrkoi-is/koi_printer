import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
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
              // 构建完整的模板清单信封
              final manifest = KoiTemplateManifest(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: '自定义模板',
                document: state.document,
                schema: state.currentSchema.fields.map((f) => KoiTemplateField(
                  key: f.key,
                  label: f.label,
                  type: f.type == 'array' ? KoiFieldType.array
                      : f.type == 'number' ? KoiFieldType.number
                      : KoiFieldType.string,
                )).toList(),
                mockData: state.mockData,
              );
              final jsonStr = manifest.toJsonString();
              
              showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('导出模板清单 (Manifest)'),
                    content: SizedBox(
                      width: 600,
                      height: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('包含: 模板元数据 + Schema (${manifest.schema.length} 字段) + 打印文档',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  jsonStr,
                                  style: const TextStyle(fontFamily: 'SarasaMono', fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('关闭'),
                      ),
                      FilledButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: jsonStr));
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('已复制到剪贴板！')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制 JSON'),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(Icons.save_alt, size: 18),
            label: const Text('导出模板'),
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
          title: const Text('模板大厅'),
          content: SizedBox(
            width: 560,
            height: 420,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: templateManifests.length,
              itemBuilder: (_, i) {
                final m = templateManifests[i];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      final elements = manifestToEditorElements(m);
                      context.read<EditorState>().loadManifest(m, elements);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.white],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(m.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          if (m.description.isNotEmpty)
                            Text(m.description,
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Text('${m.schema.length} 个字段',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade400)),
                        ],
                      ),
                    ),
                  ),
                );
              },
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
