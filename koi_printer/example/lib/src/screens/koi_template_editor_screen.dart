import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:koi_printer/koi_printer.dart';

/// 打印文档编辑器 — 支持拖拽排序 + JSON 导入导出。
/// Gaps 11 & 12: ReorderableListView + JSON import/export.
class KoiTemplateEditorScreen extends StatefulWidget {
  const KoiTemplateEditorScreen({super.key, this.initialDocument});

  /// 可选初始文档, 用于编辑已有模板。
  final KoiPrintDocument? initialDocument;

  @override
  State<KoiTemplateEditorScreen> createState() =>
      _KoiTemplateEditorScreenState();
}

class _KoiTemplateEditorScreenState extends State<KoiTemplateEditorScreen> {
  late List<KoiTicketElement> _elements;
  late String _docName;

  @override
  void initState() {
    super.initState();
    final doc = widget.initialDocument;
    if (doc is KoiTicketDocument) {
      _elements = List.of(doc.elements);
      _docName = doc.name ?? '未命名模板';
    } else {
      _elements = [];
      _docName = '未命名模板';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_docName),
        actions: [
          // JSON 导入
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: '导入 JSON',
            onPressed: _importJson,
          ),
          // JSON 导出
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: '导出 JSON',
            onPressed: _exportJson,
          ),
          // 添加元素
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加元素',
            onPressed: _addElement,
          ),
        ],
      ),
      body: _elements.isEmpty
          ? const Center(child: Text('空模板, 点击右上角 + 添加元素'))
          : ReorderableListView.builder(
              itemCount: _elements.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final element = _elements[index];
                return _ElementTile(
                  key: ValueKey('$index-${element.hashCode}'),
                  index: index,
                  element: element,
                  onDelete: () => _removeElement(index),
                );
              },
            ),
    );
  }

  // ── 拖拽排序 (Gap 11) ──

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _elements.removeAt(oldIndex);
      _elements.insert(newIndex, item);
    });
  }

  // ── 添加 / 删除元素 ──

  void _addElement() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                '添加打印元素',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _addTile('文本', Icons.text_fields, () {
              _insert(const KoiTextElement(text: '新文本'));
            }),
            _addTile('分割线', Icons.horizontal_rule, () {
              _insert(const KoiDividerElement());
            }),
            _addTile('空行', Icons.space_bar, () {
              _insert(const KoiSpacerElement(lines: 1));
            }),
            _addTile('条码', Icons.qr_code_scanner, () {
              _insert(const KoiBarcodeElement(data: '0000000000'));
            }),
            _addTile('二维码', Icons.qr_code_2, () {
              _insert(const KoiQrCodeElement(data: 'https://example.com'));
            }),
            _addTile('切纸', Icons.content_cut, () {
              _insert(const KoiCutElement());
            }),
          ],
        ),
      ),
    );
  }

  Widget _addTile(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _insert(KoiTicketElement element) {
    setState(() => _elements.add(element));
  }

  void _removeElement(int index) {
    setState(() => _elements.removeAt(index));
  }

  // ── JSON 导入 / 导出 (Gap 12) ──

  Future<void> _exportJson() async {
    final doc = KoiTicketDocument(
      name: _docName,
      paperSize: KoiPaperSize.mm80,
      elements: _elements,
    );

    final json = doc.toJson();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(json);

    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('JSON 已复制到剪贴板')));
  }

  Future<void> _importJson() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('剪贴板为空')));
      return;
    }

    try {
      final json = jsonDecode(data.text!) as Map<String, dynamic>;
      final doc = koiPrintDocumentFromJson(json);
      if (doc is! KoiTicketDocument) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('仅支持导入小票文档')));
        return;
      }
      setState(() {
        _elements = List.of(doc.elements);
        _docName = doc.name ?? '导入模板';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已导入: ${doc.name} (${doc.elements.length} 个元素)'),
        ),
      );
    } on Object catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('JSON 解析失败: $e')));
    }
  }
}

// ── 元素显示 Tile ──

class _ElementTile extends StatelessWidget {
  const _ElementTile({
    super.key,
    required this.index,
    required this.element,
    required this.onDelete,
  });

  final int index;
  final KoiTicketElement element;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final info = _elementInfo(element);

    return Dismissible(
      key: ValueKey('dismiss-$index-${element.hashCode}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Icon(info.$1, size: 20),
        title: Text(info.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(info.$3, style: const TextStyle(fontSize: 11)),
        trailing: const Icon(Icons.drag_handle, color: Colors.grey),
      ),
    );
  }

  /// 返回 (icon, title, subtitle) 描述元素。
  (IconData, String, String) _elementInfo(KoiTicketElement el) {
    return switch (el) {
      KoiTextElement() => (
        Icons.text_fields,
        el.text,
        'Text size=${el.size.name}',
      ),
      KoiTextRowElement() => (
        Icons.table_rows,
        '${el.columns.length} 列表格行',
        'TextRow',
      ),
      KoiDividerElement() => (Icons.horizontal_rule, '分割线', 'Divider'),
      KoiSpacerElement() => (Icons.space_bar, '空行 ×${el.lines}', 'Spacer'),
      KoiBarcodeElement() => (
        Icons.qr_code_scanner,
        el.data,
        'Barcode h=${el.height}',
      ),
      KoiQrCodeElement() => (
        Icons.qr_code_2,
        el.data,
        'QR size=${el.size.name}',
      ),
      KoiTicketImageElement() => (Icons.image, '图片', 'Image w=${el.width}'),
      KoiCutElement() => (Icons.content_cut, '切纸', 'Cut ${el.mode.name}'),
      _ => (Icons.help_outline, el.runtimeType.toString(), 'Element'),
    };
  }
}
