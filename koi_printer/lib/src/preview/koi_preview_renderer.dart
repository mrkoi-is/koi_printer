import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 预览渲染器 — 将 [KoiPrintDocument] 渲染为 Flutter Widget。
/// Preview renderer that converts a print document into a visual preview
/// matching real printer output.
///
/// 用法:
/// ```dart
/// KoiPreviewRenderer.build(
///   document: document,
///   paperWidthPx: 380,
///   fontFamily: 'SarasaMono', // 传入您配置的 1:2 严格等宽字体
/// );
/// ```
class KoiPreviewRenderer {
  const KoiPreviewRenderer._(); // coverage:ignore-line

  /// 构建预览 Widget。
  static Widget build({
    required KoiPrintDocument document,
    required double paperWidthPx,
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black,
    String? fontFamily,
  }) {
    return switch (document) {
      KoiTicketDocument() => _buildFlowPreview(
        document,
        paperWidthPx: paperWidthPx,
        backgroundColor: backgroundColor,
        textColor: textColor,
        fontFamily: fontFamily ?? 'monospace',
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
    required String fontFamily,
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
        children:
            document.elements
                .map((e) => _flowElement(e, textColor, paperWidthPx, fontFamily))
                .toList(),
      ),
    );
  }

  static Widget _flowElement(
    KoiTicketElement element,
    Color textColor,
    double paperWidth,
    String fontFamily,
  ) {
    return switch (element) {
      KoiTextElement() => _flowText(element, textColor, fontFamily),
      KoiTextRowElement() => _flowTextRow(element, textColor, fontFamily),
      KoiQrCodeElement() => _flowQrCode(element, textColor, fontFamily),
      KoiBarcodeElement() => _flowBarcode(element, textColor, fontFamily),
      KoiTicketImageElement() => _flowImage(element),
      KoiDividerElement() => _flowDivider(element, textColor, paperWidth, fontFamily),
      KoiSpacerElement() => _flowSpacer(element),
      KoiCutElement() => _flowCut(textColor),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _flowText(KoiTextElement e, Color color, String fontFamily) {
    final wScale = (e.widthSize?.value ?? e.size.value).toDouble();
    final hScale = (e.heightSize?.value ?? e.size.value).toDouble();
    
    // 基础字体大小 (基于点阵的 24 Dots)
    const baseFontSize = 24.0;
    final stretchX = wScale / hScale;

    Widget textWidget = Text(
      e.text,
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: baseFontSize * hScale,
        fontWeight: e.bold ? FontWeight.bold : FontWeight.normal,
        letterSpacing: fontFamily == 'monospace' ? -0.5 : 0,
        decoration:
            e.underline ? TextDecoration.underline : TextDecoration.none,
        color: e.reverse ? Colors.white : color,
        backgroundColor: e.reverse ? color : null,
      ),
    );

    if (stretchX != 1.0) {
      textWidget = Transform.scale(
        scaleX: stretchX,
        alignment: _align(e.align),
        child: textWidget,
      );
    }

    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: textWidget,
    );
  }

  static Widget _flowTextRow(KoiTextRowElement e, Color color, String fontFamily) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children:
            e.columns.map((col) {
              return Expanded(
                flex: col.ratio,
                child: Text(
                  col.text,
                  textAlign: _textAlign(col.align),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 24, // 与底层 1 倍字体 (24 dots) 的点阵精确对齐
                    fontWeight: col.bold ? FontWeight.bold : FontWeight.normal,
                    letterSpacing: fontFamily == 'monospace' ? -0.5 : 0,
                    color: color,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  static Widget _flowQrCode(KoiQrCodeElement e, Color color, String fontFamily) {
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

  static Widget _flowBarcode(KoiBarcodeElement e, Color color, String fontFamily) {
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: e.height * 0.8, // 稍微放大
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.3)),
              color: color.withValues(alpha: 0.05),
            ),
            child: Stack(
              children: [
                // 模拟条码线条
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      80, // 更密集的线条
                      (index) {
                        // 简单的伪随机生成类似真实条码的粗细
                        final w = ((index * 13) % 7) < 3 ? 2.5 : 1.0;
                        final space = ((index * 17) % 5) < 2 ? 1.0 : 2.0;
                        return Container(
                          width: w,
                          margin: EdgeInsets.only(right: space),
                          color: color,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            e.data,
            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
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

  static Widget _flowDivider(KoiDividerElement e, Color color, double paperWidthPx, String fontFamily) {
    final charsPerLine = (paperWidthPx / 12).floor();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        e.char * charsPerLine,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 24,
          letterSpacing: fontFamily == 'monospace' ? -0.5 : 0,
          color: color,
        ),
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
        children:
            document.elements
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
    // 严格按照打印机点阵 (dots) 匹配像素，基准为 24x24
    return switch (size) {
      KoiTextSize.size1 => 24,
      KoiTextSize.size2 => 48,
      KoiTextSize.size3 => 72,
      KoiTextSize.size4 => 96,
      KoiTextSize.size5 => 120,
      KoiTextSize.size6 => 144,
      KoiTextSize.size7 => 168,
      KoiTextSize.size8 => 192,
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
