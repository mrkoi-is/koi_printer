import 'package:koi_printer/koi_printer.dart';

/// 为打印元素提供局部 copyWith 方法，避免在编辑属性时手动重写所有字段导致漏参。
extension KoiTextElementEditorExt on KoiTextElement {
  KoiTextElement copyWith({
    String? text,
    KoiTextSize? size,
    KoiTextSize? widthSize,
    KoiTextSize? heightSize,
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
      widthSize: widthSize ?? this.widthSize,
      heightSize: heightSize ?? this.heightSize,
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
