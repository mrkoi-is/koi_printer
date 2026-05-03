import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 预览渲染器 — 将 [KoiPrintDocument] 渲染为 Flutter Widget。
/// Preview renderer that converts a print document into a visual preview
/// matching real printer output.
///
/// 用法:
/// ```dart
/// KoiPreviewRenderer.build(document);
/// ```
class KoiPreviewRenderer {
  const KoiPreviewRenderer._(); // coverage:ignore-line

  /// 构建预览 Widget。
  static Widget build(
    KoiPrintDocument document, {
    double paperWidthPx = 380,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
  }) {
    return switch (document) {
      KoiTicketDocument() => _buildFlowPreview(
        document,
        paperWidthPx: paperWidthPx,
        backgroundColor: backgroundColor,
        textColor: textColor,
      ),
      KoiLabelDocument() => _buildPositionedPreview(
        document,
        paperWidthPx: paperWidthPx,
        backgroundColor: backgroundColor,
        textColor: textColor,
      ),
    };
  }

  // ═══════════════════════════════════════════════════════════
  // 流式布局预览 (ESC/POS 小票)
  // ═══════════════════════════════════════════════════════════

  static Widget _buildFlowPreview(
    KoiTicketDocument document, {
    required double paperWidthPx,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return Container(
      width: paperWidthPx,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: document.elements
            .map((e) => _flowElement(e, textColor, paperWidthPx))
            .toList(),
      ),
    );
  }

  static Widget _flowElement(
    KoiTicketElement element,
    Color textColor,
    double paperWidth,
  ) {
    return switch (element) {
      KoiTextElement() => _flowText(element, textColor),
      KoiTextRowElement() => _flowTextRow(element, textColor),
      KoiQrCodeElement() => _flowQrCode(element, textColor),
      KoiBarcodeElement() => _flowBarcode(element, textColor),
      KoiTicketImageElement() => _flowImage(element),
      KoiDividerElement() => _flowDivider(element, textColor),
      KoiSpacerElement() => _flowSpacer(element),
      KoiCutElement() => _flowCut(textColor),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _flowText(KoiTextElement e, Color color) {
    final fontSize = _sizeToFontSize(e.size);
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        e.text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: fontSize,
          fontWeight: e.bold ? FontWeight.bold : FontWeight.normal,
          decoration: e.underline
              ? TextDecoration.underline
              : TextDecoration.none,
          color: e.reverse ? Colors.white : color,
          backgroundColor: e.reverse ? color : null,
        ),
      ),
    );
  }

  static Widget _flowTextRow(KoiTextRowElement e, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: e.columns.map((col) {
          return Expanded(
            flex: col.ratio,
            child: Text(
              col.text,
              textAlign: _textAlign(col.align),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: col.bold ? FontWeight.bold : FontWeight.normal,
                color: color,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  static Widget _flowQrCode(KoiQrCodeElement e, Color color) {
    final size = e.size.value * 16.0;
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code_2, size: size * 0.6, color: color),
              Text(
                'QR',
                style: TextStyle(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _flowBarcode(KoiBarcodeElement e, Color color) {
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 180,
            height: e.height * 0.5,
            decoration: BoxDecoration(border: Border.all(color: color)),
            child: Center(
              child: Text(
                '||||| ${e.data} |||||',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: color,
                ),
              ),
            ),
          ),
          Text(
            e.data,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _flowImage(KoiTicketImageElement e) {
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Image.memory(
        e.imageBytes,
        width: e.width?.toDouble(),
        fit: BoxFit.contain,
      ),
    );
  }

  static Widget _flowDivider(KoiDividerElement e, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        e.char * 48,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: color),
      ),
    );
  }

  static Widget _flowSpacer(KoiSpacerElement e) {
    return SizedBox(height: e.lines * 18.0);
  }

  static Widget _flowCut(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text('✂️', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: color.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 坐标定位预览 (TSPL/CPCL 标签)
  // ═══════════════════════════════════════════════════════════

  static Widget _buildPositionedPreview(
    KoiLabelDocument document, {
    required double paperWidthPx,
    required Color backgroundColor,
    required Color textColor,
  }) {
    var labelWidth = paperWidthPx;
    var labelHeight = paperWidthPx * 0.6;

    for (final e in document.elements) {
      if (e is KoiLabelSetupElement) {
        labelWidth = e.widthMm * 3.78;
        labelHeight = e.heightMm * 3.78;
        break;
      }
    }

    // 坐标元素缩放比 (dot → px, 基于 203dpi)
    final scale = labelWidth / (labelWidth / 3.78 * 203 / 25.4);

    return Container(
      width: labelWidth,
      height: labelHeight,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Stack(
        children: document.elements
            .map((e) => _positionedElement(e, textColor, scale))
            .toList(),
      ),
    );
  }

  static Widget _positionedElement(
    KoiLabelElement element,
    Color textColor,
    double scale,
  ) {
    return switch (element) {
      KoiPositionedTextElement() => _posText(element, textColor, scale),
      KoiPositionedBarcodeElement() => _posBarcode(element, textColor, scale),
      KoiPositionedQrCodeElement() => _posQr(element, textColor, scale),
      KoiLabelBoxElement() => _posBox(element, textColor, scale),
      KoiLabelReverseElement() => _posReverse(element, textColor, scale),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _posText(
    KoiPositionedTextElement e,
    Color color,
    double scale,
  ) {
    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Transform.rotate(
        angle: e.rotation * 3.14159 / 180,
        child: Text(
          e.text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: e.fontSize * scale * 0.6,
            color: color,
          ),
        ),
      ),
    );
  }

  static Widget _posBarcode(
    KoiPositionedBarcodeElement e,
    Color color,
    double scale,
  ) {
    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Container(
        width: 120 * scale,
        height: e.height * scale * 0.5,
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Center(
          child: Text(
            e.data,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _posQr(
    KoiPositionedQrCodeElement e,
    Color color,
    double scale,
  ) {
    final size = e.cellSize * 16.0 * scale;
    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(border: Border.all(color: color)),
        child: Icon(Icons.qr_code_2, size: size * 0.6, color: color),
      ),
    );
  }

  static Widget _posBox(KoiLabelBoxElement e, Color color, double scale) {
    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Container(
        width: e.width * scale,
        height: e.height * scale,
        decoration: BoxDecoration(
          border: Border.all(color: color, width: e.thickness * scale),
        ),
      ),
    );
  }

  static Widget _posReverse(
    KoiLabelReverseElement e,
    Color color,
    double scale,
  ) {
    return Positioned(
      left: e.x * scale,
      top: e.y * scale,
      child: Container(
        width: e.width * scale,
        height: e.height * scale,
        color: color,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // 工具方法
  // ═══════════════════════════════════════════════════════════

  static double _sizeToFontSize(KoiTextSize size) {
    return switch (size) {
      KoiTextSize.size1 => 13,
      KoiTextSize.size2 => 18,
      KoiTextSize.size3 => 22,
      KoiTextSize.size4 => 26,
      KoiTextSize.size5 => 30,
      KoiTextSize.size6 => 34,
      KoiTextSize.size7 => 38,
      KoiTextSize.size8 => 42,
    };
  }

  static AlignmentGeometry _align(KoiTextAlign align) {
    return switch (align) {
      KoiTextAlign.left => Alignment.centerLeft,
      KoiTextAlign.center => Alignment.center,
      KoiTextAlign.right => Alignment.centerRight,
    };
  }

  static TextAlign _textAlign(KoiTextAlign align) {
    return switch (align) {
      KoiTextAlign.left => TextAlign.left,
      KoiTextAlign.center => TextAlign.center,
      KoiTextAlign.right => TextAlign.right,
    };
  }
}
