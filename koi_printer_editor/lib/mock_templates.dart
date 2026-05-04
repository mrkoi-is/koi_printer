import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:koi_printer_editor/state/editor_state.dart';

String _genId() => DateTime.now().microsecondsSinceEpoch.toString();

final Map<String, List<EditorElement>> templateGallery = {
  '简单收据': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: 'Mr.Koi Store', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: 'www.mrkoi.com', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '商品', ratio: 6),
      KoiTextColumn(text: '数量', ratio: 2, align: KoiTextAlign.center),
      KoiTextColumn(text: '金额', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '{{items.name}}', ratio: 6),
      KoiTextColumn(text: '{{items.qty}}', ratio: 2, align: KoiTextAlign.center),
      KoiTextColumn(text: '{{items.price}}', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextRowElement(columns: [
      KoiTextColumn(text: '合计', ratio: 8, bold: true),
      KoiTextColumn(text: '¥{{fee.total}}', ratio: 4, align: KoiTextAlign.right),
    ])),
    EditorElement(id: _genId(), element: const KoiSpacerElement(lines: 1)),
    EditorElement(id: _genId(), element: const KoiQrCodeElement(data: 'https://mrkoi.io', align: KoiTextAlign.center, size: KoiQrSize.size5)),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '寄件物流面单': [
    EditorElement(id: _genId(), element: const KoiTextElement(text: '顺丰速运', align: KoiTextAlign.center, bold: true, size: KoiTextSize.size2)),
    EditorElement(id: _genId(), element: const KoiBarcodeElement(data: 'SF123456789', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '单号: {{waybillNo}}', align: KoiTextAlign.center)),
    EditorElement(id: _genId(), element: const KoiDividerElement()),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '收件人: 张三  13800138000', bold: true)),
    EditorElement(id: _genId(), element: const KoiTextElement(text: '地址: 广东省深圳市南山区科技园')),
    EditorElement(id: _genId(), element: const KoiDividerElement(char: '-')),
    EditorElement(id: _genId(), element: const KoiCutElement()),
  ],
  '空白模板': [],
};

final List<EditorElement> defaultTemplateElements = templateGallery['简单收据']!;
