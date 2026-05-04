import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
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

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PaletteItem(
          icon: Icons.text_fields,
          label: '文本 (Text)',
          onAdd: () {
            context.read<EditorState>().execute(
              AddElementCommand(
                EditorElement(
                  id: _genId(), 
                  element: const KoiTextElement(text: '默认文本', size: KoiTextSize.size1),
                ),
              ),
            );
          },
        ),
        _PaletteItem(
          icon: Icons.horizontal_rule,
          label: '分割线 (Divider)',
          onAdd: () {
            context.read<EditorState>().execute(
              AddElementCommand(
                EditorElement(id: _genId(), element: const KoiDividerElement()),
              ),
            );
          },
        ),
        _PaletteItem(
          icon: Icons.qr_code,
          label: '二维码 (QR Code)',
          onAdd: () {
            context.read<EditorState>().execute(
              AddElementCommand(
                EditorElement(id: _genId(), element: const KoiQrCodeElement(data: 'https://mrkoi.io')),
              ),
            );
          },
        ),
        _PaletteItem(
          icon: Icons.view_column,
          label: '多列排版 (Row)',
          onAdd: () {
            context.read<EditorState>().execute(
              AddElementCommand(
                EditorElement(
                  id: _genId(),
                  element: const KoiTextRowElement(
                    columns: [
                      KoiTextColumn(text: '左侧'),
                      KoiTextColumn(text: '右侧', align: KoiTextAlign.right),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        _PaletteItem(
          icon: Icons.space_bar,
          label: '空白行 (Spacer)',
          onAdd: () {
            context.read<EditorState>().execute(
              AddElementCommand(
                EditorElement(id: _genId(), element: const KoiSpacerElement(lines: 1)),
              ),
            );
          },
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

  @override
  Widget build(BuildContext context) {
    final schema = context.watch<EditorState>().currentSchema;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '单据模型: ${schema.entity}',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...schema.fields.map((field) => ListTile(
          leading: Icon(
            field.type == 'string' ? Icons.abc : 
            field.type == 'number' ? Icons.numbers : Icons.list,
          ),
          title: Text(field.label),
          subtitle: Text('{{${field.key}}}'),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.read<EditorState>().execute(
                AddElementCommand(
                  EditorElement(
                    id: _genId(),
                    element: KoiTextElement(text: '{{${field.key}}}', size: KoiTextSize.size1),
                  ),
                ),
              );
            },
          ),
        )),
      ],
    );
  }
}
