import 'package:koi_printer_command/koi_printer_command.dart';

/// 模板引擎 — 展开 ForEach 元素, 处理动态数据。
/// Template engine that expands ForEach elements with runtime data.
///
/// 使用方法:
/// ```dart
/// final engine = KoiTemplateEngine();
/// final expanded = engine.expandTicket(document, {
///   'items': [
///     {'name': '商品A', 'price': '10.00', 'qty': '2'},
///     {'name': '商品B', 'price': '20.00', 'qty': '1'},
///   ],
/// });
/// ```
class KoiTemplateEngine {
  /// Constant constructor.
  const KoiTemplateEngine();

  /// 展开小票文档中的 [KoiTicketForEachElement]。
  KoiTicketDocument expandTicket(
    KoiTicketDocument document,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final expandedElements = <KoiTicketElement>[];

    for (final element in document.elements) {
      if (element is KoiTicketForEachElement) {
        expandedElements.addAll(_expandTicketForEach(element, data));
      } else {
        expandedElements.add(element);
      }
    }

    return KoiTicketDocument(
      paperSize: document.paperSize,
      name: document.name,
      elements: expandedElements,
    );
  }

  /// 展开标签文档中的 [KoiLabelForEachElement]。
  KoiLabelDocument expandLabel(
    KoiLabelDocument document,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final expandedElements = <KoiLabelElement>[];

    for (final element in document.elements) {
      if (element is KoiLabelForEachElement) {
        expandedElements.addAll(_expandLabelForEach(element, data));
      } else {
        expandedElements.add(element);
      }
    }

    return KoiLabelDocument(name: document.name, elements: expandedElements);
  }

  // ── 内部: 小票 ForEach 展开 ──

  List<KoiTicketElement> _expandTicketForEach(
    KoiTicketForEachElement forEach,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final collection = data[forEach.listKey];
    if (collection == null || collection.isEmpty) return [];

    final result = <KoiTicketElement>[];
    for (final item in collection) {
      for (final template in forEach.templates) {
        result.add(_substituteTicketElement(template, item));
      }
    }
    return result;
  }

  KoiTicketElement _substituteTicketElement(
    KoiTicketElement element,
    Map<String, dynamic> item,
  ) {
    return switch (element) {
      KoiTextElement() => KoiTextElement(
        text: _substitute(element.text, item),
        align: element.align,
        size: element.size,
        widthSize: element.widthSize,
        heightSize: element.heightSize,
        bold: element.bold,
        underline: element.underline,
        underlineStyle: element.underlineStyle,
        reverse: element.reverse,
        font: element.font,
      ),
      KoiTextRowElement() => KoiTextRowElement(
        columns: element.columns
            .map(
              (col) => KoiTextColumn(
                text: _substitute(col.text, item),
                ratio: col.ratio,
                align: col.align,
                bold: col.bold,
                containsChinese: col.containsChinese,
              ),
            )
            .toList(),
      ),
      KoiBarcodeElement() => KoiBarcodeElement(
        data: _substitute(element.data, item),
        type: element.type,
        height: element.height,
        width: element.width,
        align: element.align,
        textPosition: element.textPosition,
        font: element.font,
      ),
      KoiQrCodeElement() => KoiQrCodeElement(
        data: _substitute(element.data, item),
        align: element.align,
        size: element.size,
        correction: element.correction,
        strategy: element.strategy,
      ),
      // 非文本元素直接返回 (无需替换)
      _ => element,
    };
  }

  // ── 内部: 标签 ForEach 展开 ──

  List<KoiLabelElement> _expandLabelForEach(
    KoiLabelForEachElement forEach,
    Map<String, List<Map<String, dynamic>>> data,
  ) {
    final collection = data[forEach.listKey];
    if (collection == null || collection.isEmpty) return [];

    final result = <KoiLabelElement>[];
    for (final item in collection) {
      for (final template in forEach.templates) {
        result.add(_substituteLabelElement(template, item));
      }
    }
    return result;
  }

  KoiLabelElement _substituteLabelElement(
    KoiLabelElement element,
    Map<String, dynamic> item,
  ) {
    return switch (element) {
      KoiPositionedTextElement() => KoiPositionedTextElement(
        x: element.x,
        y: element.y,
        text: _substitute(element.text, item),
        font: element.font,
        fontSize: element.fontSize,
        rotation: element.rotation,
        xScale: element.xScale,
        yScale: element.yScale,
        bold: element.bold,
      ),
      KoiPositionedBarcodeElement() => KoiPositionedBarcodeElement(
        x: element.x,
        y: element.y,
        data: _substitute(element.data, item),
        type: element.type,
        height: element.height,
      ),
      KoiPositionedQrCodeElement() => KoiPositionedQrCodeElement(
        x: element.x,
        y: element.y,
        data: _substitute(element.data, item),
        cellSize: element.cellSize,
      ),
      _ => element,
    };
  }

  // ── 通用: 模板变量替换 ──

  /// 执行 {{key}} → value 替换, 支持嵌套 Map 点号路径。
  String _substitute(String template, Map<String, dynamic> values) {
    return template.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
      final key = match.group(1)!;
      final resolved = _resolveDotPath(key, values);
      return resolved ?? match.group(0)!;
    });
  }

  /// 按 `.` 分割 key, 递归查找嵌套 Map 中的值。
  String? _resolveDotPath(String path, Map<String, dynamic> values) {
    final parts = path.split('.');
    dynamic current = values;

    for (final part in parts) {
      if (current is Map<String, dynamic>) {
        current = current[part];
      } else {
        return null;
      }
    }

    return current?.toString();
  }
}
