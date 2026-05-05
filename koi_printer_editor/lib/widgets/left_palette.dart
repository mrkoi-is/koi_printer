import 'package:flutter/material.dart';
import 'package:koi_printer/koi_printer.dart';
import 'package:koi_printer_editor/state/editor_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

class LeftPalette extends StatelessWidget {
  const LeftPalette({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.dividerColor)),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '组件库'),
                Tab(text: '数据源'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ComponentsTab(),
                  _DataSchemaTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComponentsTab extends StatelessWidget {
  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _addNode(BuildContext context, KoiTicketElement element) {
    final state = context.read<EditorState>();
    final selected = state.selectedElement;
    final String? parentId = (selected?.element is KoiTicketForEachElement) ? selected!.id : null;
    state.execute(AddElementCommand(EditorElement(id: _genId(), element: element), parentId: parentId));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PaletteItem(
          icon: Icons.list_alt_rounded,
          label: '循环列表容器 (ForEach)',
          onAdd: () => _addNode(context, const KoiTicketForEachElement(listKey: 'items', templates: [])),
        ),
        _PaletteItem(
          icon: Icons.text_fields,
          label: '文本 (Text)',
          onAdd: () => _addNode(context, const KoiTextElement(text: '默认文本', size: KoiTextSize.size1)),
        ),
        _PaletteItem(
          icon: Icons.horizontal_rule,
          label: '分割线 (Divider)',
          onAdd: () => _addNode(context, const KoiDividerElement()),
        ),
        _PaletteItem(
          icon: Icons.qr_code,
          label: '二维码 (QR Code)',
          onAdd: () => _addNode(context, const KoiQrCodeElement(data: 'https://mrkoi.io')),
        ),
        _PaletteItem(
          icon: Icons.view_column,
          label: '多列排版 (Row)',
          onAdd: () => _addNode(context, const KoiTextRowElement(
            columns: [
              KoiTextColumn(text: '左侧'),
              KoiTextColumn(text: '右侧', align: KoiTextAlign.right),
            ],
          )),
        ),
        _PaletteItem(
          icon: Icons.space_bar,
          label: '空白行 (Spacer)',
          onAdd: () => _addNode(context, const KoiSpacerElement(lines: 1)),
        ),
      ],
    );
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({required this.icon, required this.label, required this.onAdd});
  final IconData icon;
  final String label;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(label)),
              const Icon(Icons.add_circle_outline, size: 20, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

class _DataSchemaTab extends StatelessWidget {
  String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

  void _showFieldDialog(BuildContext context, EditorState state, {int? index}) {
    final isEdit = index != null;
    final initialField = isEdit ? state.schema[index] : null;

    final keyCtrl = TextEditingController(text: initialField?.key ?? '');
    final labelCtrl = TextEditingController(text: initialField?.label ?? '');
    KoiFieldType type = initialField?.type ?? KoiFieldType.string;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text(isEdit ? '编辑字段' : '添加字段'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: keyCtrl, decoration: const InputDecoration(labelText: '变量 Key (英文/数字)')),
                    const SizedBox(height: 8),
                    TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: '展示名称 (Label)')),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<KoiFieldType>(
                      initialValue: type,
                      decoration: const InputDecoration(labelText: '数据类型 (Type)'),
                      items: KoiFieldType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => type = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                FilledButton(
                  onPressed: () {
                    final key = keyCtrl.text.trim();
                    final label = labelCtrl.text.trim();
                    if (key.isEmpty || label.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Key 和 Label 不能为空')));
                      return;
                    }
                    final field = KoiTemplateField(key: key, label: label, type: type);
                    if (isEdit) {
                      state.updateSchemaField(index, field);
                    } else {
                      state.addSchemaField(field);
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final fields = state.schema;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '单据模型: ${state.schemaEntity.isEmpty ? '自定义' : state.schemaEntity}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.blue),
              tooltip: '添加字段',
              onPressed: () => _showFieldDialog(context, state),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...fields.asMap().entries.map((entry) {
          final i = entry.key;
          final field = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Icon(
                field.type == KoiFieldType.string ? Icons.abc : 
                field.type == KoiFieldType.number ? Icons.numbers : Icons.list,
                color: Colors.blueGrey,
              ),
              title: Text(field.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('{{${field.key}}}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16),
                    tooltip: '编辑',
                    onPressed: () => _showFieldDialog(context, state, index: i),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    tooltip: '删除',
                    onPressed: () {
                      state.removeSchemaField(i);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box, size: 16, color: Colors.blue),
                    tooltip: '插入文本到画布',
                    onPressed: () {
                      state.execute(
                        AddElementCommand(
                          EditorElement(
                            id: _genId(),
                            element: KoiTextElement(text: '{{${field.key}}}', size: KoiTextSize.size1),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
