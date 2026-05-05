import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children:
            document.elements
                .map(
                  (e) => _flowElement(e, textColor, paperWidthPx, fontFamily),
                )
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
      KoiDividerElement() => _flowDivider(
        element,
        textColor,
        paperWidth,
        fontFamily,
      ),
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

    // 强制按宽度拉伸比例计算 fontSize，以确保 Flutter 文本换行策略与物理打印机的水平点阵限制完全一致。
    final fontSize = baseFontSize * wScale;

    // 计算为了达到目标高度，需要对文本进行的垂直物理拉伸比例。
    final stretchY = hScale / wScale;

    Widget textWidget = Text(
      e.text,
      textAlign: _textAlign(e.align),
      style: TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: e.bold ? FontWeight.bold : FontWeight.normal,
        letterSpacing: fontFamily == 'monospace' ? -0.5 : 0,
        decoration:
            e.underline ? TextDecoration.underline : TextDecoration.none,
        color: e.reverse ? Colors.white : color,
        backgroundColor: e.reverse ? color : null,
      ),
    );

    if (stretchY != 1.0) {
      // 通过 Transform.scale 仅进行垂直渲染拉伸
      textWidget = Transform.scale(
        scaleY: stretchY,
        child: textWidget,
      );

      // 通过 Align.heightFactor 动态调整排版高度，使其与垂直拉伸后的视觉高度完全一致，避免组件重叠。
      textWidget = Align(
        heightFactor: stretchY,
        widthFactor: 1,
        child: textWidget,
      );
    }

    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: textWidget,
    );
  }

  static Widget _flowTextRow(
    KoiTextRowElement e,
    Color color,
    String fontFamily,
  ) {
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

  static Widget _flowQrCode(
    KoiQrCodeElement e,
    Color color,
    String fontFamily,
  ) {
    final size = e.size.value * 16.0;
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: QrImageView(
        data: e.data,
        size: size,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: color,
        ),
        gapless: false,
      ),
    );
  }

  static Widget _flowBarcode(
    KoiBarcodeElement e,
    Color color,
    String fontFamily,
  ) {
    return Container(
      alignment: _align(e.align),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        height: e.height.toDouble(),
        width: 300, // Reasonable default width for preview
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: e.data,
          color: color,
          drawText: e.textPosition != KoiBarcodeTextPosition.none,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: color,
          ),
          textPadding: 4,
        ),
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

  static Widget _flowDivider(
    KoiDividerElement e,
    Color color,
    double paperWidthPx,
    String fontFamily,
  ) {
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
                .map((e) => renderPositionedElement(e, textColor, scale))
                .toList(),
      ),
    );
  }

  /// 渲染单个绝对定位的标签元素为 Flutter Widget
  static Widget renderPositionedElement(
    KoiLabelElement element,
    Color textColor,
    double scale,
  ) {
    return switch (element) {
      KoiPositionedTextElement() => _posText(element, textColor, scale),
      KoiPositionedBarcodeElement() => _posBarcode(element, textColor, scale),
      KoiPositionedQrCodeElement() => _posQr(element, textColor, scale),
      KoiLabelBoxElement() => _posBox(element, textColor, scale),
      KoiLabelLineElement() => _posLine(element, textColor, scale),
      KoiLabelReverseElement() => _posReverse(element, textColor, scale),
      _ => const SizedBox.shrink(),
    };
  }

  static Widget _posLine(KoiLabelLineElement e, Color color, double scale) {
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
      child: SizedBox(
        width: 120 * scale,
        height: e.height * scale,
        child: BarcodeWidget(
          barcode: Barcode.code128(),
          data: e.data,
          color: color,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 10 * scale,
            color: color,
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
      child: QrImageView(
        data: e.data,
        size: size,
        eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: color),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: color,
        ),
        gapless: false,
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
