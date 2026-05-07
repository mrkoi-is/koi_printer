import 'dart:typed_data';
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
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: '组件库'),
                Tab(text: '图层'),
                Tab(text: '数据源'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ComponentsTab(),
                  const _LayerTreeTab(),
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

  void _addNode(BuildContext context, KoiPrintElement element) {
    final state = context.read<EditorState>();

    // 阻止混合添加
    if (state.elements.isNotEmpty) {
      if (state.isTicketMode && element is! KoiTicketElement) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前为小票模式，无法添加标签元素')));
        return;
      }
      if (!state.isTicketMode && element is KoiTicketElement) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('当前为标签模式，无法添加小票元素')));
        return;
      }
    }

    final selected = state.selectedElement;
    final String? parentId = (selected?.element is KoiTicketForEachElement)
        ? selected!.id
        : null;
    state.execute(
      AddElementCommand(
        EditorElement(id: _genId(), element: element),
        parentId: parentId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();

    if (state.isTicketMode) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PaletteItem(
            icon: Icons.list_alt_rounded,
            label: '循环列表容器 (ForEach)',
            onAdd: () => _addNode(
              context,
              const KoiTicketForEachElement(listKey: 'items', templates: []),
            ),
          ),
          _PaletteItem(
            icon: Icons.text_fields,
            label: '文本 (Text)',
            onAdd: () => _addNode(
              context,
              const KoiTextElement(text: '默认文本', size: KoiTextSize.size1),
            ),
          ),
          _PaletteItem(
            icon: Icons.horizontal_rule,
            label: '分割线 (Divider)',
            onAdd: () => _addNode(context, const KoiDividerElement()),
          ),
          _PaletteItem(
            icon: Icons.qr_code,
            label: '二维码 (QR Code)',
            onAdd: () => _addNode(
              context,
              const KoiQrCodeElement(data: 'https://mrkoi.io'),
            ),
          ),
          _PaletteItem(
            icon: Icons.barcode_reader,
            label: '条形码 (Barcode)',
            onAdd: () =>
                _addNode(context, const KoiBarcodeElement(data: '1234567890')),
          ),
          _PaletteItem(
            icon: Icons.view_column,
            label: '多列排版 (Row)',
            dragElement: const KoiTextRowElement(
              columns: [
                KoiTextColumn(text: '左侧'),
                KoiTextColumn(text: '右侧', align: KoiTextAlign.right),
              ],
            ),
            onAdd: () => _addNode(
              context,
              const KoiTextRowElement(
                columns: [
                  KoiTextColumn(text: '左侧'),
                  KoiTextColumn(text: '右侧', align: KoiTextAlign.right),
                ],
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.space_bar,
            label: '空白行 (Spacer)',
            onAdd: () => _addNode(context, const KoiSpacerElement(lines: 1)),
          ),
          _PaletteItem(
            icon: Icons.code,
            label: '原始指令 (Raw)',
            onAdd: () => _addNode(
              context,
              const KoiRawCommandElement('SIZE 40 mm,30 mm\nGAP 2 mm,0 mm'),
            ),
          ),
        ],
      );
    } else {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PaletteItem(
            icon: Icons.settings_overscan,
            label: '纸张设置 (Setup)',
            onAdd: () => _addNode(
              context,
              const KoiLabelSetupElement(widthMm: 40, heightMm: 30),
            ),
          ),
          _PaletteItem(
            icon: Icons.text_format,
            label: '绝对文本 (Text)',
            onAdd: () => _addNode(
              context,
              const KoiPositionedTextElement(x: 10, y: 10, text: '示例文本'),
            ),
          ),
          _PaletteItem(
            icon: Icons.barcode_reader,
            label: '绝对条码 (Barcode)',
            onAdd: () => _addNode(
              context,
              const KoiPositionedBarcodeElement(x: 10, y: 10, data: '123456'),
            ),
          ),
          _PaletteItem(
            icon: Icons.qr_code,
            label: '绝对二维码 (QR)',
            onAdd: () => _addNode(
              context,
              const KoiPositionedQrCodeElement(
                x: 10,
                y: 10,
                data: 'https://mrkoi.io',
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.crop_square,
            label: '矩形框 (Box)',
            onAdd: () => _addNode(
              context,
              const KoiLabelBoxElement(x: 10, y: 10, width: 200, height: 100),
            ),
          ),
          _PaletteItem(
            icon: Icons.format_color_fill,
            label: '反白区域 (Reverse)',
            onAdd: () => _addNode(
              context,
              const KoiLabelReverseElement(
                x: 10,
                y: 10,
                width: 200,
                height: 100,
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.list_alt_rounded,
            label: '循环列表容器 (ForEach)',
            onAdd: () => _addNode(
              context,
              const KoiLabelForEachElement(listKey: 'items', templates: []),
            ),
          ),
          _PaletteItem(
            icon: Icons.image,
            label: '绝对图片 (Image)',
            onAdd: () => _addNode(
              context,
              KoiLabelImageElement(
                x: 10,
                y: 10,
                imageBytes: Uint8List(0),
                width: 100,
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.print,
            label: '触发打印 (Print)',
            onAdd: () => _addNode(
              context,
              const KoiLabelPrintElement(copies: 1, sets: 1),
            ),
          ),
          _PaletteItem(
            icon: Icons.text_snippet,
            label: '段落文本 (Block)',
            onAdd: () => _addNode(
              context,
              const KoiLabelBlockTextElement(
                x: 10,
                y: 10,
                width: 200,
                height: 100,
                text: '自动换行段落文本',
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.radio_button_unchecked,
            label: '圆形 (Circle)',
            onAdd: () => _addNode(
              context,
              const KoiLabelCircleElement(x: 10, y: 10, diameter: 50),
            ),
          ),
          _PaletteItem(
            icon: Icons.panorama_horizontal_select,
            label: '椭圆 (Ellipse)',
            onAdd: () => _addNode(
              context,
              const KoiLabelEllipseElement(
                x: 10,
                y: 10,
                width: 100,
                height: 50,
              ),
            ),
          ),
          _PaletteItem(
            icon: Icons.horizontal_rule_outlined,
            label: '斜线 (Diagonal)',
            onAdd: () => _addNode(
              context,
              const KoiLabelDiagonalElement(x: 10, y: 10, xEnd: 110, yEnd: 110),
            ),
          ),
          _PaletteItem(
            icon: Icons.volume_up,
            label: '蜂鸣器 (Beep)',
            onAdd: () => _addNode(context, const KoiLabelBeepElement()),
          ),
          _PaletteItem(
            icon: Icons.vertical_align_bottom,
            label: '走纸 (Feed)',
            onAdd: () => _addNode(context, const KoiLabelFeedElement()),
          ),
          _PaletteItem(
            icon: Icons.qr_code_scanner,
            label: 'PDF417 (二维)',
            onAdd: () => _addNode(
              context,
              const KoiLabelPdf417Element(x: 10, y: 10, data: 'PDF417'),
            ),
          ),
          _PaletteItem(
            icon: Icons.content_cut,
            label: '切纸 (Cut)',
            onAdd: () => _addNode(context, const KoiLabelCutElement()),
          ),
          _PaletteItem(
            icon: Icons.code,
            label: '原始指令 (Raw)',
            onAdd: () =>
                _addNode(context, const KoiRawCommandElement('PRINT 1,1')),
          ),
        ],
      );
    }
  }
}

class _PaletteItem extends StatelessWidget {
  const _PaletteItem({
    required this.icon,
    required this.label,
    required this.onAdd,
    this.dragElement,
  });

  final IconData icon;
  final String label;
  final VoidCallback onAdd;
  final KoiPrintElement? dragElement;

  @override
  Widget build(BuildContext context) {
    final card = Card(
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
              const Icon(
                Icons.add_circle_outline,
                size: 20,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );

    if (dragElement == null) return card;

    return Draggable<KoiPrintElement>(
      data: dragElement,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.8, child: SizedBox(width: 240, child: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: card),
      child: card,
    );
  }
}

class _LayerTreeTab extends StatelessWidget {
  const _LayerTreeTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<EditorState>();
    final elements = state.elements;

    if (elements.isEmpty) {
      return const Center(
        child: Text('画布为空', style: TextStyle(color: Colors.grey)),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: elements.length,
      onReorder: (oldIndex, newIndex) {
        state.execute(
          ReorderElementsCommand(oldIndex: oldIndex, newIndex: newIndex),
        );
      },
      itemBuilder: (context, index) {
        final el = elements[index];
        final isSelected = state.selectedElementId == el.id;

        IconData icon;
        String label;
        if (el.element is KoiTextElement) {
          icon = Icons.text_fields;
          label = '文本: ${(el.element as KoiTextElement).text}';
        } else if (el.element is KoiTicketForEachElement) {
          icon = Icons.list_alt_rounded;
          label = '小票循环 (${(el.element as KoiTicketForEachElement).listKey})';
        } else if (el.element is KoiDividerElement) {
          icon = Icons.horizontal_rule;
          label = '分割线';
        } else if (el.element is KoiQrCodeElement) {
          icon = Icons.qr_code;
          label = '二维码: ${(el.element as KoiQrCodeElement).data}';
        } else if (el.element is KoiBarcodeElement) {
          icon = Icons.barcode_reader;
          label = '条形码: ${(el.element as KoiBarcodeElement).data}';
        } else if (el.element is KoiTextRowElement) {
          icon = Icons.view_column;
          label =
              '多列排版 (${(el.element as KoiTextRowElement).columns.length} 列)';
        } else if (el.element is KoiSpacerElement) {
          icon = Icons.space_bar;
          label = '空白行 (${(el.element as KoiSpacerElement).lines} 行)';
        } else if (el.element is KoiLabelSetupElement) {
          final s = el.element as KoiLabelSetupElement;
          icon = Icons.settings_overscan;
          label = '纸张设置 (${s.widthMm}x${s.heightMm}mm)';
        } else if (el.element is KoiPositionedTextElement) {
          icon = Icons.text_format;
          label = '绝对文本: ${(el.element as KoiPositionedTextElement).text}';
        } else if (el.element is KoiLabelBoxElement) {
          icon = Icons.crop_square;
          label = '矩形框 (Box)';
        } else if (el.element is KoiPositionedBarcodeElement) {
          icon = Icons.barcode_reader;
          label = '绝对条码: ${(el.element as KoiPositionedBarcodeElement).data}';
        } else if (el.element is KoiPositionedQrCodeElement) {
          icon = Icons.qr_code;
          label = '绝对二维码: ${(el.element as KoiPositionedQrCodeElement).data}';
        } else if (el.element is KoiLabelLineElement) {
          icon = Icons.horizontal_rule;
          label = '直线 (Line)';
        } else if (el.element is KoiLabelReverseElement) {
          icon = Icons.format_color_fill;
          label = '反白区域 (Reverse)';
        } else if (el.element is KoiLabelImageElement) {
          icon = Icons.image;
          label = '绝对图片 (Image)';
        } else if (el.element is KoiLabelPrintElement) {
          icon = Icons.print;
          label = '触发打印 (${(el.element as KoiLabelPrintElement).copies} 份)';
        } else if (el.element is KoiLabelForEachElement) {
          icon = Icons.list_alt_rounded;
          label = '标签循环 (${(el.element as KoiLabelForEachElement).listKey})';
        } else if (el.element is KoiRawCommandElement) {
          icon = Icons.code;
          label = '原始指令 (Raw)';
        } else {
          icon = Icons.widgets;
          label = '未知组件';
        }

        return Card(
          key: ValueKey(el.id),
          elevation: isSelected ? 2 : 0,
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : null,
          margin: const EdgeInsets.only(bottom: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? Colors.blue : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.blueGrey,
              size: 20,
            ),
            title: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue.shade900 : Colors.black87,
              ),
            ),
            selected: isSelected,
            onTap: () => state.selectElement(el.id),
            trailing: const Icon(
              Icons.drag_handle,
              color: Colors.grey,
              size: 20,
            ),
          ),
        );
      },
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
                    TextField(
                      controller: keyCtrl,
                      decoration: const InputDecoration(
                        labelText: '变量 Key (英文/数字)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: labelCtrl,
                      decoration: const InputDecoration(
                        labelText: '展示名称 (Label)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<KoiFieldType>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: '数据类型 (Type)',
                      ),
                      items: KoiFieldType.values
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text(t.name)),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => type = val);
                      },
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
                    final key = keyCtrl.text.trim();
                    final label = labelCtrl.text.trim();
                    if (key.isEmpty || label.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Key 和 Label 不能为空')),
                      );
                      return;
                    }
                    final field = KoiTemplateField(
                      key: key,
                      label: label,
                      type: type,
                    );
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
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
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
                field.type == KoiFieldType.string
                    ? Icons.abc
                    : field.type == KoiFieldType.number
                    ? Icons.numbers
                    : Icons.list,
                color: Colors.blueGrey,
              ),
              title: Text(
                field.label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(
                '{{${field.key}}}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
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
                    icon: const Icon(
                      Icons.add_box,
                      size: 16,
                      color: Colors.blue,
                    ),
                    tooltip: '插入文本到画布',
                    onPressed: () {
                      state.execute(
                        AddElementCommand(
                          EditorElement(
                            id: _genId(),
                            element: KoiTextElement(
                              text: '{{${field.key}}}',
                              size: KoiTextSize.size1,
                            ),
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
