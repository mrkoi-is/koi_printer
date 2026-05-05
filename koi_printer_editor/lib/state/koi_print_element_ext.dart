import 'package:koi_printer/koi_printer.dart';

/// 为打印元素提供局部 copyWith 方法，避免在编辑属性时手动重写所有字段导致漏参。
extension KoiTextElementEditorExt on KoiTextElement {
  KoiTextElement copyWith({
    String? text,
    KoiTextSize? size,
    KoiTextSize? widthSize,
    bool clearWidthSize = false,
    KoiTextSize? heightSize,
    bool clearHeightSize = false,
    KoiTextAlign? align,
    bool? bold,
    bool? reverse,
    bool? underline,
    KoiUnderlineStyle? underlineStyle,
    KoiFontType? font,
  }) {
    return KoiTextElement(
      text: text ?? this.text,
      size: size ?? this.size,
      widthSize: clearWidthSize ? null : (widthSize ?? this.widthSize),
      heightSize: clearHeightSize ? null : (heightSize ?? this.heightSize),
      align: align ?? this.align,
      bold: bold ?? this.bold,
      reverse: reverse ?? this.reverse,
      underline: underline ?? this.underline,
      underlineStyle: underlineStyle ?? this.underlineStyle,
      font: font ?? this.font,
    );
  }
}

extension KoiQrCodeElementEditorExt on KoiQrCodeElement {
  KoiQrCodeElement copyWith({
    String? data,
    KoiQrSize? size,
    KoiQrRenderStrategy? strategy,
    KoiQrCorrection? correction,
    KoiTextAlign? align,
  }) {
    return KoiQrCodeElement(
      data: data ?? this.data,
      size: size ?? this.size,
      strategy: strategy ?? this.strategy,
      correction: correction ?? this.correction,
      align: align ?? this.align,
    );
  }
}

extension KoiBarcodeElementEditorExt on KoiBarcodeElement {
  KoiBarcodeElement copyWith({
    String? data,
    KoiBarcodeType? type,
    int? height,
    int? width,
    KoiTextAlign? align,
    KoiBarcodeTextPosition? textPosition,
    KoiFontType? font,
  }) {
    return KoiBarcodeElement(
      data: data ?? this.data,
      type: type ?? this.type,
      height: height ?? this.height,
      width: width ?? this.width,
      align: align ?? this.align,
      textPosition: textPosition ?? this.textPosition,
      font: font ?? this.font,
    );
  }
}

extension KoiTicketForEachElementEditorExt on KoiTicketForEachElement {
  KoiTicketForEachElement copyWith({
    String? listKey,
    List<KoiTicketElement>? templates,
  }) {
    return KoiTicketForEachElement(
      listKey: listKey ?? this.listKey,
      templates: templates ?? this.templates,
    );
  }
}

extension KoiTextRowElementExt on KoiTextRowElement {
  KoiTextRowElement copyWith({
    List<KoiTextColumn>? columns,
  }) {
    return KoiTextRowElement(
      columns: columns ?? this.columns,
    );
  }
}

extension KoiTextColumnExt on KoiTextColumn {
  KoiTextColumn copyWith({
    String? text,
    int? ratio,
    KoiTextAlign? align,
    bool? bold,
  }) {
    return KoiTextColumn(
      text: text ?? this.text,
      ratio: ratio ?? this.ratio,
      align: align ?? this.align,
      bold: bold ?? this.bold,
    );
  }
}

extension KoiLabelBoxElementEditorExt on KoiLabelBoxElement {
  KoiLabelBoxElement copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    int? thickness,
  }) {
    return KoiLabelBoxElement(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      thickness: thickness ?? this.thickness,
    );
  }
}

extension KoiPositionedTextElementEditorExt on KoiPositionedTextElement {
  KoiPositionedTextElement copyWith({
    int? x,
    int? y,
    String? text,
    int? fontSize,
    String? font,
    int? rotation,
    int? xScale,
    int? yScale,
    bool? bold,
  }) {
    return KoiPositionedTextElement(
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      fontSize: fontSize ?? this.fontSize,
      font: font ?? this.font,
      rotation: rotation ?? this.rotation,
      xScale: xScale ?? this.xScale,
      yScale: yScale ?? this.yScale,
      bold: bold ?? this.bold,
    );
  }
}

extension KoiPositionedBarcodeElementEditorExt on KoiPositionedBarcodeElement {
  KoiPositionedBarcodeElement copyWith({
    int? x,
    int? y,
    String? data,
    int? height,
    String? type,
  }) {
    return KoiPositionedBarcodeElement(
      x: x ?? this.x,
      y: y ?? this.y,
      data: data ?? this.data,
      height: height ?? this.height,
      type: type ?? this.type,
    );
  }
}

extension KoiPositionedQrCodeElementEditorExt on KoiPositionedQrCodeElement {
  KoiPositionedQrCodeElement copyWith({
    int? x,
    int? y,
    String? data,
    int? cellSize,
  }) {
    return KoiPositionedQrCodeElement(
      x: x ?? this.x,
      y: y ?? this.y,
      data: data ?? this.data,
      cellSize: cellSize ?? this.cellSize,
    );
  }
}

extension KoiLabelReverseElementEditorExt on KoiLabelReverseElement {
  KoiLabelReverseElement copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return KoiLabelReverseElement(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

extension KoiLabelLineElementEditorExt on KoiLabelLineElement {
  KoiLabelLineElement copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return KoiLabelLineElement(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}

extension KoiLabelSetupElementEditorExt on KoiLabelSetupElement {
  KoiLabelSetupElement copyWith({
    int? widthMm,
    int? heightMm,
    int? gapMm,
    int? dpi,
    int? density,
    double? speed,
    int? referenceX,
    int? referenceY,
    String? codepage,
  }) {
    return KoiLabelSetupElement(
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      gapMm: gapMm ?? this.gapMm,
      dpi: dpi ?? this.dpi,
      density: density ?? this.density,
      speed: speed ?? this.speed,
      referenceX: referenceX ?? this.referenceX,
      referenceY: referenceY ?? this.referenceY,
      codepage: codepage ?? this.codepage,
    );
  }
}

