import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/services/cloud_sync_service.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:koi_printer_editor/widgets/template_gallery_dialog.dart';
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.grid_view, size: 18),
            label: const Text('模板大厅'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const TemplateGalleryDialog(),
              );
            },
          ),
          const SizedBox(width: 8),
          const VerticalDivider(width: 1, indent: 12, endIndent: 12),
          const SizedBox(width: 8),

          // Paper size dropdown
          DropdownButton<double>(
            value: state.paperWidthPx,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: 280.0, child: Text('58mm 小票')),
              DropdownMenuItem(value: 380.0, child: Text('80mm 小票')),
              DropdownMenuItem(value: 500.0, child: Text('100x150 面单')),
            ],
            onChanged: (val) {
              if (val != null) {
                context.read<EditorState>().updatePaperWidthPx(val);
              }
            },
          ),

          const Spacer(),

          // 预览模式切换
          Row(
            children: [
              Text(
                '编辑',
                style: TextStyle(
                  color: state.isPreviewMode
                      ? Colors.grey
                      : theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: state.isPreviewMode,
                onChanged: (_) =>
                    context.read<EditorState>().togglePreviewMode(),
                activeTrackColor: theme.colorScheme.primary,
              ),
              Text(
                '预览 (假数据)',
                style: TextStyle(
                  color: state.isPreviewMode
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.data_object),
            tooltip: '配置测试数据 (Mock Data)',
            onPressed: () => _showMockDataEditor(context, state),
          ),
          const SizedBox(width: 16),
          // Undo / Redo
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: state.canUndo
                ? () => context.read<EditorState>().undo()
                : null,
            tooltip: '撤销',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: state.canRedo
                ? () => context.read<EditorState>().redo()
                : null,
            tooltip: '重做',
          ),

          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '模板基础设置',
            onPressed: () => _showMetadataEditor(context, state),
          ),
          TextButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: const Text('保存到云端'),
            onPressed: () => _showSaveToCloudDialog(context, state),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              // 构建完整的模板清单信封 (复用当前加载的 manifest 身份)
              final manifest = KoiTemplateManifest(
                id: state.currentManifestId.isNotEmpty
                    ? state.currentManifestId
                    : 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: state.currentManifestName.isNotEmpty
                    ? state.currentManifestName
                    : '自定义模板',
                category: state.currentManifestCategory,
                description: state.currentManifestDescription,
                document: state.document,
                schema: state.schema,
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
                          Text(
                            '包含: 模板元数据 + Schema (${manifest.schema.length} 字段) + 打印文档',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
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
                                  style: const TextStyle(
                                    fontFamily: 'SarasaMono',
                                    fontSize: 12,
                                  ),
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

  void _showSaveToCloudDialog(BuildContext context, EditorState state) {
    final idCtrl = TextEditingController(text: state.currentManifestId);
    final nameCtrl = TextEditingController(text: state.currentManifestName);
    final descCtrl = TextEditingController(
      text: state.currentManifestDescription,
    );
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('保存到云端 (Save to Cloud)'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idCtrl,
                      decoration: const InputDecoration(
                        labelText: '模板 ID (唯一标识)',
                      ),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: '模板名称'),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(labelText: '模板描述'),
                      maxLines: 2,
                      enabled: !isSaving,
                    ),
                    if (isSaving) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final id = idCtrl.text.trim();
                          final name = nameCtrl.text.trim();
                          if (id.isEmpty || name.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('ID 和名称不能为空')),
                            );
                            return;
                          }

                          setState(() => isSaving = true);

                          final manifest = KoiTemplateManifest(
                            id: id,
                            name: name,
                            description: descCtrl.text.trim(),
                            category: state.currentManifestCategory,
                            schema: state.schema,
                            document: state.document,
                          );

                          try {
                            await CloudSyncService().uploadTemplate(manifest);
                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已成功保存到云端！')),
                              );
                            }
                          } catch (e) {
                            if (ctx.mounted) {
                              setState(() => isSaving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('上传失败: $e')),
                              );
                            }
                          }
                        },
                  child: const Text('确认保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMetadataEditor(BuildContext context, EditorState state) {
    final idCtrl = TextEditingController(text: state.currentManifestId);
    final nameCtrl = TextEditingController(text: state.currentManifestName);
    final categoryCtrl = TextEditingController(
      text: state.currentManifestCategory,
    );
    final descCtrl = TextEditingController(
      text: state.currentManifestDescription,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('模板基础设置 (Metadata)'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: idCtrl,
                  decoration: const InputDecoration(labelText: '模板 ID (英文/数字)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: '模板名称 (Name)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: '分类 (Category)'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '描述 (Description)',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final id = idCtrl.text.trim();
                final name = nameCtrl.text.trim();
                if (id.isEmpty || name.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('模板 ID 和名称不能为空')),
                  );
                  return;
                }
                context.read<EditorState>().updateManifestMetadata(
                  id: id,
                  name: name,
                  category: categoryCtrl.text.trim(),
                  description: descCtrl.text.trim(),
                );
                Navigator.pop(ctx);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showMockDataEditor(BuildContext context, EditorState state) {
    final ctrl = TextEditingController(
      text: const JsonEncoder.withIndent('  ').convert(state.mockData),
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('配置测试数据 (Mock Data)'),
          content: SizedBox(
            width: 500,
            height: 400,
            child: TextField(
              controller: ctrl,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'SarasaMono', fontSize: 13),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '{\n  "key": "value"\n}',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                try {
                  final data = jsonDecode(ctrl.text);
                  if (data is Map<String, dynamic>) {
                    context.read<EditorState>().updateMockData(data);
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('错误：根节点必须是 JSON Object ({})'),
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text('JSON 语法错误: $e')));
                }
              },
              child: const Text('应用'),
            ),
          ],
        );
      },
    );
  }
}
