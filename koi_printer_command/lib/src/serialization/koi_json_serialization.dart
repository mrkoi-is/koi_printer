import 'dart:convert';
import 'dart:typed_data';

import 'package:koi_printer_command/src/model/koi_print_document.dart';
import 'package:koi_printer_command/src/model/koi_print_element.dart';
import 'package:koi_printer_command/src/model/koi_types.dart';

// ═══════════════════════════════════════════════════════════
// KoiTicketElement JSON 序列化
// ═══════════════════════════════════════════════════════════

/// 小票元素类型白名单。
const _ticketTypes = {
  'text',
  'textRow',
  'qrCode',
  'barcode',
  'ticketImage',
  'divider',
  'spacer',
  'cut',
  'beep',
  'cashDrawer',
  'leftMargin',
  'rawBytes',
  'ticketForEach',
};

/// 标签元素类型白名单。
const _labelTypes = {
  'labelSetup',
  'positionedText',
  'positionedBarcode',
  'positionedQrCode',
  'labelBox',
  'labelReverse',
  'labelLine',
  'labelImage',
  'labelPrint',
  'rawCommand',
  'labelForEach',
  'labelBlockText',
  'labelCircle',
  'labelEllipse',
  'labelDiagonal',
  'labelBeep',
  'labelCut',
  'labelFeed',
  'labelPdf417',
};

/// 反序列化小票元素。
KoiTicketElement koiTicketElementFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  if (_labelTypes.contains(type)) {
    throw FormatException('标签元素 "$type" 不能放入小票文档');
  }
  return switch (type) {
    'text' => _textFromJson(json),
    'textRow' => _textRowFromJson(json),
    'qrCode' => _qrCodeFromJson(json),
    'barcode' => _barcodeFromJson(json),
    'ticketImage' => _ticketImageFromJson(json),
    'divider' => _dividerFromJson(json),
    'spacer' => _spacerFromJson(json),
    'cut' => _cutFromJson(json),
    'beep' => _beepFromJson(json),
    'cashDrawer' => _cashDrawerFromJson(json),
    'leftMargin' => _leftMarginFromJson(json),
    'rawBytes' => _rawBytesFromJson(json),
    'ticketForEach' => _ticketForEachFromJson(json),
    _ => throw FormatException('未知小票元素类型: $type'),
  };
}

/// 序列化小票元素。
Map<String, dynamic> koiTicketElementToJson(KoiTicketElement element) {
  return switch (element) {
    KoiTextElement() => _textToJson(element),
    KoiTextRowElement() => _textRowToJson(element),
    KoiQrCodeElement() => _qrCodeToJson(element),
    KoiBarcodeElement() => _barcodeToJson(element),
    KoiTicketImageElement() => _ticketImageToJson(element),
    KoiDividerElement() => _dividerToJson(element),
    KoiSpacerElement() => _spacerToJson(element),
    KoiCutElement() => _cutToJson(element),
    KoiBeepElement() => _beepToJson(element),
    KoiCashDrawerElement() => _cashDrawerToJson(element),
    KoiLeftMarginElement() => _leftMarginToJson(element),
    KoiRawBytesElement() => _rawBytesToJson(element),
    KoiTicketForEachElement() => _ticketForEachToJson(element),
  };
}

// ═══════════════════════════════════════════════════════════
// KoiLabelElement JSON 序列化
// ═══════════════════════════════════════════════════════════

/// 反序列化标签元素。
KoiLabelElement koiLabelElementFromJson(Map<String, dynamic> json) {
  final type = json['type'] as String;
  if (_ticketTypes.contains(type)) {
    throw FormatException('小票元素 "$type" 不能放入标签文档');
  }
  return switch (type) {
    'labelSetup' => _labelSetupFromJson(json),
    'positionedText' => _positionedTextFromJson(json),
    'positionedBarcode' => _positionedBarcodeFromJson(json),
    'positionedQrCode' => _positionedQrCodeFromJson(json),
    'labelBox' => _labelBoxFromJson(json),
    'labelReverse' => _labelReverseFromJson(json),
    'labelLine' => _labelLineFromJson(json),
    'labelImage' => _labelImageFromJson(json),
    'labelPrint' => _labelPrintFromJson(json),
    'rawCommand' => _rawCommandFromJson(json),
    'labelForEach' => _labelForEachFromJson(json),
    'labelBlockText' => _labelBlockTextFromJson(json),
    'labelCircle' => _labelCircleFromJson(json),
    'labelEllipse' => _labelEllipseFromJson(json),
    'labelDiagonal' => _labelDiagonalFromJson(json),
    'labelBeep' => _labelBeepFromJson(json),
    'labelCut' => _labelCutFromJson(json),
    'labelFeed' => _labelFeedFromJson(json),
    'labelPdf417' => _labelPdf417FromJson(json),
    _ => throw FormatException('未知标签元素类型: $type'),
  };
}

/// 序列化标签元素。
Map<String, dynamic> koiLabelElementToJson(KoiLabelElement element) {
  return switch (element) {
    KoiLabelSetupElement() => _labelSetupToJson(element),
    KoiPositionedTextElement() => _positionedTextToJson(element),
    KoiPositionedBarcodeElement() => _positionedBarcodeToJson(element),
    KoiPositionedQrCodeElement() => _positionedQrCodeToJson(element),
    KoiLabelBoxElement() => _labelBoxToJson(element),
    KoiLabelReverseElement() => _labelReverseToJson(element),
    KoiLabelLineElement() => _labelLineToJson(element),
    KoiLabelImageElement() => _labelImageToJson(element),
    KoiLabelPrintElement() => _labelPrintToJson(element),
    KoiRawCommandElement() => _rawCommandToJson(element),
    KoiLabelForEachElement() => _labelForEachToJson(element),
    KoiLabelBlockTextElement() => _labelBlockTextToJson(element),
    KoiLabelCircleElement() => _labelCircleToJson(element),
    KoiLabelEllipseElement() => _labelEllipseToJson(element),
    KoiLabelDiagonalElement() => _labelDiagonalToJson(element),
    KoiLabelBeepElement() => _labelBeepToJson(element),
    KoiLabelCutElement() => _labelCutToJson(element),
    KoiLabelFeedElement() => _labelFeedToJson(element),
    KoiLabelPdf417Element() => _labelPdf417ToJson(element),
  };
}

// ═══════════════════════════════════════════════════════════
// KoiPrintDocument JSON 序列化
// ═══════════════════════════════════════════════════════════

/// [KoiPrintDocument] JSON 序列化扩展。
extension KoiPrintDocumentJson on KoiPrintDocument {
  /// 序列化为 Map。
  Map<String, dynamic> toJson() => switch (this) {
    KoiTicketDocument(:final elements, :final paperSize, :final name) => {
      'documentType': 'ticket',
      'paperSize': paperSize.widthMm,
      if (name != null) 'name': name,
      'elements': elements.map(koiTicketElementToJson).toList(),
    },
    KoiLabelDocument(:final elements, :final name) => {
      'documentType': 'label',
      if (name != null) 'name': name,
      'elements': elements.map(koiLabelElementToJson).toList(),
    },
  };

  /// 序列化为 JSON 字符串。
  String toJsonString() => json.encode(toJson());
}

/// 从 JSON Map 构建 [KoiPrintDocument]。
KoiPrintDocument koiPrintDocumentFromJson(Map<String, dynamic> json) {
  final docType = json['documentType'] as String;
  return switch (docType) {
    'ticket' => KoiTicketDocument(
      paperSize: _parsePaperSize(json['paperSize']),
      name: json['name'] as String?,
      elements:
          (json['elements'] as List)
              .map((e) => koiTicketElementFromJson(e as Map<String, dynamic>))
              .toList(),
    ),
    'label' => KoiLabelDocument(
      name: json['name'] as String?,
      elements:
          (json['elements'] as List)
              .map((e) => koiLabelElementFromJson(e as Map<String, dynamic>))
              .toList(),
    ),
    _ => throw FormatException('未知文档类型: $docType'),
  };
}

/// 从 JSON 字符串构建 [KoiPrintDocument]。
KoiPrintDocument koiPrintDocumentFromJsonString(String source) {
  return koiPrintDocumentFromJson(json.decode(source) as Map<String, dynamic>);
}

// ═══════════════════════════════════════════════════════════
// 内部: 小票元素 toJson / fromJson
// ═══════════════════════════════════════════════════════════

// ── Text ──
Map<String, dynamic> _textToJson(KoiTextElement e) => {
  'type': 'text',
  'text': e.text,
  if (e.size != KoiTextSize.size1) 'size': e.size.name,
  if (e.widthSize != null) 'widthSize': e.widthSize!.name,
  if (e.heightSize != null) 'heightSize': e.heightSize!.name,
  if (e.align != KoiTextAlign.left) 'align': e.align.name,
  if (e.bold) 'bold': true,
  if (e.reverse) 'reverse': true,
  if (e.underline) 'underline': true,
  if (e.underlineStyle != KoiUnderlineStyle.none)
    'underlineStyle': e.underlineStyle.name,
  if (e.font != KoiFontType.fontA) 'font': e.font.name,
};

KoiTextElement _textFromJson(Map<String, dynamic> j) => KoiTextElement(
  text: j['text'] as String,
  size: _enumByName(KoiTextSize.values, j['size'], KoiTextSize.size1),
  widthSize:
      j['widthSize'] != null
          ? _enumByName(KoiTextSize.values, j['widthSize'], KoiTextSize.size1)
          : null,
  heightSize:
      j['heightSize'] != null
          ? _enumByName(KoiTextSize.values, j['heightSize'], KoiTextSize.size1)
          : null,
  align: _enumByName(KoiTextAlign.values, j['align'], KoiTextAlign.left),
  bold: j['bold'] as bool? ?? false,
  reverse: j['reverse'] as bool? ?? false,
  underline: j['underline'] as bool? ?? false,
  underlineStyle: _enumByName(
    KoiUnderlineStyle.values,
    j['underlineStyle'],
    KoiUnderlineStyle.none,
  ),
  font: _enumByName(KoiFontType.values, j['font'], KoiFontType.fontA),
);

// ── TextRow ──
Map<String, dynamic> _textRowToJson(KoiTextRowElement e) => {
  'type': 'textRow',
  'columns': e.columns.map(_columnToJson).toList(),
};

Map<String, dynamic> _columnToJson(KoiTextColumn c) => {
  'text': c.text,
  if (c.ratio != 1) 'ratio': c.ratio,
  if (c.align != KoiTextAlign.left) 'align': c.align.name,
  if (c.bold) 'bold': true,
  if (!c.containsChinese) 'containsChinese': false,
};

KoiTextRowElement _textRowFromJson(Map<String, dynamic> j) => KoiTextRowElement(
  columns:
      (j['columns'] as List)
          .map((c) => _columnFromJson(c as Map<String, dynamic>))
          .toList(),
);

KoiTextColumn _columnFromJson(Map<String, dynamic> j) => KoiTextColumn(
  text: j['text'] as String,
  ratio: j['ratio'] as int? ?? 1,
  align: _enumByName(KoiTextAlign.values, j['align'], KoiTextAlign.left),
  bold: j['bold'] as bool? ?? false,
  containsChinese: j['containsChinese'] as bool? ?? true,
);

// ── QR Code ──
Map<String, dynamic> _qrCodeToJson(KoiQrCodeElement e) => {
  'type': 'qrCode',
  'data': e.data,
  if (e.size != KoiQrSize.size6) 'size': e.size.name,
  if (e.strategy != KoiQrRenderStrategy.normal) 'strategy': e.strategy.name,
  if (e.correction != KoiQrCorrection.medium) 'correction': e.correction.name,
  if (e.align != KoiTextAlign.center) 'align': e.align.name,
};

KoiQrCodeElement _qrCodeFromJson(Map<String, dynamic> j) => KoiQrCodeElement(
  data: j['data'] as String,
  size: _enumByName(KoiQrSize.values, j['size'], KoiQrSize.size6),
  strategy: _enumByName(
    KoiQrRenderStrategy.values,
    j['strategy'],
    KoiQrRenderStrategy.normal,
  ),
  correction: _enumByName(
    KoiQrCorrection.values,
    j['correction'],
    KoiQrCorrection.medium,
  ),
  align: _enumByName(KoiTextAlign.values, j['align'], KoiTextAlign.center),
);

// ── Barcode ──
Map<String, dynamic> _barcodeToJson(KoiBarcodeElement e) => {
  'type': 'barcode',
  'data': e.data,
  if (e.type != KoiBarcodeType.code128) 'barcodeType': e.type.name,
  if (e.height != 60) 'height': e.height,
  if (e.width != 2) 'width': e.width,
  if (e.align != KoiTextAlign.center) 'align': e.align.name,
  if (e.textPosition != KoiBarcodeTextPosition.below)
    'textPosition': e.textPosition.name,
  if (e.font != KoiFontType.fontA) 'font': e.font.name,
};

KoiBarcodeElement _barcodeFromJson(Map<String, dynamic> j) => KoiBarcodeElement(
  data: j['data'] as String,
  type: _enumByName(
    KoiBarcodeType.values,
    j['barcodeType'],
    KoiBarcodeType.code128,
  ),
  height: j['height'] as int? ?? 60,
  width: j['width'] as int? ?? 2,
  align: _enumByName(KoiTextAlign.values, j['align'], KoiTextAlign.center),
  textPosition: _enumByName(
    KoiBarcodeTextPosition.values,
    j['textPosition'],
    KoiBarcodeTextPosition.below,
  ),
  font: _enumByName(KoiFontType.values, j['font'], KoiFontType.fontA),
);

// ── Ticket Image ──
Map<String, dynamic> _ticketImageToJson(KoiTicketImageElement e) => {
  'type': 'ticketImage',
  'imageBytes': base64Encode(e.imageBytes),
  if (e.width != null) 'width': e.width,
  if (e.align != KoiTextAlign.center) 'align': e.align.name,
  if (e.renderMode != KoiImageRenderMode.raster)
    'renderMode': e.renderMode.name,
};

KoiTicketImageElement _ticketImageFromJson(Map<String, dynamic> j) =>
    KoiTicketImageElement(
      imageBytes: Uint8List.fromList(base64Decode(j['imageBytes'] as String)),
      width: j['width'] as int?,
      align: _enumByName(KoiTextAlign.values, j['align'], KoiTextAlign.center),
      renderMode: _enumByName(
        KoiImageRenderMode.values,
        j['renderMode'],
        KoiImageRenderMode.raster,
      ),
    );

// ── Divider ──
Map<String, dynamic> _dividerToJson(KoiDividerElement e) => {
  'type': 'divider',
  if (e.char != '-') 'char': e.char,
};

KoiDividerElement _dividerFromJson(Map<String, dynamic> j) =>
    KoiDividerElement(char: j['char'] as String? ?? '-');

// ── Spacer ──
Map<String, dynamic> _spacerToJson(KoiSpacerElement e) => {
  'type': 'spacer',
  if (e.lines != 1) 'lines': e.lines,
};

KoiSpacerElement _spacerFromJson(Map<String, dynamic> j) =>
    KoiSpacerElement(lines: j['lines'] as int? ?? 1);

// ── Cut ──
Map<String, dynamic> _cutToJson(KoiCutElement e) => {
  'type': 'cut',
  if (e.mode != KoiCutMode.full) 'mode': e.mode.name,
};

KoiCutElement _cutFromJson(Map<String, dynamic> j) => KoiCutElement(
  mode: _enumByName(KoiCutMode.values, j['mode'], KoiCutMode.full),
);

// ── Beep ──
Map<String, dynamic> _beepToJson(KoiBeepElement e) => {
  'type': 'beep',
  if (e.count != 3) 'count': e.count,
  if (e.durationMs != 100) 'durationMs': e.durationMs,
};

KoiBeepElement _beepFromJson(Map<String, dynamic> j) => KoiBeepElement(
  count: j['count'] as int? ?? 3,
  durationMs: j['durationMs'] as int? ?? 100,
);

// ── Cash Drawer ──
Map<String, dynamic> _cashDrawerToJson(KoiCashDrawerElement e) => {
  'type': 'cashDrawer',
  if (e.pin != KoiCashDrawerPin.pin2) 'pin': e.pin.name,
};

KoiCashDrawerElement _cashDrawerFromJson(Map<String, dynamic> j) =>
    KoiCashDrawerElement(
      pin: _enumByName(
        KoiCashDrawerPin.values,
        j['pin'],
        KoiCashDrawerPin.pin2,
      ),
    );

// ── Left Margin ──
Map<String, dynamic> _leftMarginToJson(KoiLeftMarginElement e) => {
  'type': 'leftMargin',
  if (e.dots != 0) 'dots': e.dots,
};

KoiLeftMarginElement _leftMarginFromJson(Map<String, dynamic> j) =>
    KoiLeftMarginElement(dots: (j['dots'] as num?)?.toInt() ?? 0);

// ── Raw Bytes ──
Map<String, dynamic> _rawBytesToJson(KoiRawBytesElement e) => {
  'type': 'rawBytes',
  'bytes': e.bytes,
};

KoiRawBytesElement _rawBytesFromJson(Map<String, dynamic> j) =>
    KoiRawBytesElement((j['bytes'] as List).cast<int>());

// ── Ticket ForEach ──
Map<String, dynamic> _ticketForEachToJson(KoiTicketForEachElement e) => {
  'type': 'ticketForEach',
  'listKey': e.listKey,
  'templates': e.templates.map(koiTicketElementToJson).toList(),
};

KoiTicketForEachElement _ticketForEachFromJson(Map<String, dynamic> j) =>
    KoiTicketForEachElement(
      listKey: j['listKey'] as String,
      templates:
          (j['templates'] as List)
              .map((e) => koiTicketElementFromJson(e as Map<String, dynamic>))
              .toList(),
    );

// ═══════════════════════════════════════════════════════════
// 内部: 标签元素 toJson / fromJson
// ═══════════════════════════════════════════════════════════

// ── Label Setup ──
Map<String, dynamic> _labelSetupToJson(KoiLabelSetupElement e) => {
  'type': 'labelSetup',
  'widthMm': e.widthMm,
  'heightMm': e.heightMm,
  if (e.gapMm != 2) 'gapMm': e.gapMm,
  if (e.dpi != 203) 'dpi': e.dpi,
  if (e.density != null) 'density': e.density,
  if (e.speed != null) 'speed': e.speed,
  if (e.referenceX != 0) 'referenceX': e.referenceX,
  if (e.referenceY != 0) 'referenceY': e.referenceY,
  if (e.codepage != null) 'codepage': e.codepage,
  if (e.direction != KoiLabelDirection.backward) 'direction': e.direction.name,
  if (e.paperType != KoiLabelPaperType.gap) 'paperType': e.paperType.name,
  if (e.blackMarkMm != 0) 'blackMarkMm': e.blackMarkMm,
};

KoiLabelSetupElement _labelSetupFromJson(Map<String, dynamic> j) =>
    KoiLabelSetupElement(
      widthMm: j['widthMm'] as int,
      heightMm: j['heightMm'] as int,
      gapMm: j['gapMm'] as int? ?? 2,
      dpi: j['dpi'] as int? ?? 203,
      density: j['density'] as int?,
      speed: (j['speed'] as num?)?.toDouble(),
      referenceX: j['referenceX'] as int? ?? 0,
      referenceY: j['referenceY'] as int? ?? 0,
      codepage: j['codepage'] as String?,
      direction: _enumByName(
        KoiLabelDirection.values,
        j['direction'],
        KoiLabelDirection.backward,
      ),
      paperType: _enumByName(
        KoiLabelPaperType.values,
        j['paperType'],
        KoiLabelPaperType.gap,
      ),
      blackMarkMm: j['blackMarkMm'] as int? ?? 0,
    );

// ── Positioned Text ──
Map<String, dynamic> _positionedTextToJson(KoiPositionedTextElement e) => {
  'type': 'positionedText',
  'x': e.x,
  'y': e.y,
  'text': e.text,
  if (e.fontSize != 24) 'fontSize': e.fontSize,
  if (e.font != 'TSS24.BF2') 'font': e.font,
  if (e.rotation != 0) 'rotation': e.rotation,
  if (e.xScale != 1) 'xScale': e.xScale,
  if (e.yScale != 1) 'yScale': e.yScale,
  if (e.bold) 'bold': true,
};

KoiPositionedTextElement _positionedTextFromJson(Map<String, dynamic> j) =>
    KoiPositionedTextElement(
      x: j['x'] as int,
      y: j['y'] as int,
      text: j['text'] as String,
      fontSize: j['fontSize'] as int? ?? 24,
      font: j['font'] as String? ?? 'TSS24.BF2',
      rotation: j['rotation'] as int? ?? 0,
      xScale: j['xScale'] as int? ?? 1,
      yScale: j['yScale'] as int? ?? 1,
      bold: j['bold'] as bool? ?? false,
    );

// ── Positioned Barcode ──
Map<String, dynamic> _positionedBarcodeToJson(KoiPositionedBarcodeElement e) =>
    {
      'type': 'positionedBarcode',
      'x': e.x,
      'y': e.y,
      'data': e.data,
      if (e.height != 60) 'height': e.height,
      if (e.type != '128') 'barcodeType': e.type,
      if (e.readable != 1) 'readable': e.readable,
      if (e.rotation != 0) 'rotation': e.rotation,
      if (e.narrow != 2) 'narrow': e.narrow,
      if (e.wide != 2) 'wide': e.wide,
    };

KoiPositionedBarcodeElement _positionedBarcodeFromJson(
  Map<String, dynamic> j,
) => KoiPositionedBarcodeElement(
  x: j['x'] as int,
  y: j['y'] as int,
  data: j['data'] as String,
  height: j['height'] as int? ?? 60,
  type: j['barcodeType'] as String? ?? '128',
  readable: j['readable'] as int? ?? 1,
  rotation: j['rotation'] as int? ?? 0,
  narrow: j['narrow'] as int? ?? 2,
  wide: j['wide'] as int? ?? 2,
);

// ── Positioned QR Code ──
Map<String, dynamic> _positionedQrCodeToJson(KoiPositionedQrCodeElement e) => {
  'type': 'positionedQrCode',
  'x': e.x,
  'y': e.y,
  'data': e.data,
  if (e.cellSize != 6) 'cellSize': e.cellSize,
  if (e.eccLevel != 'L') 'eccLevel': e.eccLevel,
  if (e.rotation != 0) 'rotation': e.rotation,
};

KoiPositionedQrCodeElement _positionedQrCodeFromJson(Map<String, dynamic> j) =>
    KoiPositionedQrCodeElement(
      x: j['x'] as int,
      y: j['y'] as int,
      data: j['data'] as String,
      cellSize: j['cellSize'] as int? ?? 6,
      eccLevel: j['eccLevel'] as String? ?? 'L',
      rotation: j['rotation'] as int? ?? 0,
    );

// ── Label Box ──
Map<String, dynamic> _labelBoxToJson(KoiLabelBoxElement e) => {
  'type': 'labelBox',
  'x': e.x,
  'y': e.y,
  'width': e.width,
  'height': e.height,
  if (e.thickness != 2) 'thickness': e.thickness,
};

KoiLabelBoxElement _labelBoxFromJson(Map<String, dynamic> j) =>
    KoiLabelBoxElement(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int,
      thickness: j['thickness'] as int? ?? 2,
    );

// ── Label Reverse ──
Map<String, dynamic> _labelReverseToJson(KoiLabelReverseElement e) => {
  'type': 'labelReverse',
  'x': e.x,
  'y': e.y,
  'width': e.width,
  'height': e.height,
};

KoiLabelReverseElement _labelReverseFromJson(Map<String, dynamic> j) =>
    KoiLabelReverseElement(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int,
    );

// ── Label Line ──
Map<String, dynamic> _labelLineToJson(KoiLabelLineElement e) => {
  'type': 'labelLine',
  'x': e.x,
  'y': e.y,
  'width': e.width,
  'height': e.height,
};

KoiLabelLineElement _labelLineFromJson(Map<String, dynamic> j) =>
    KoiLabelLineElement(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int,
    );

// ── Label Image ──
Map<String, dynamic> _labelImageToJson(KoiLabelImageElement e) => {
  'type': 'labelImage',
  'x': e.x,
  'y': e.y,
  'imageBytes': base64Encode(e.imageBytes),
  if (e.width != null) 'width': e.width,
  if (e.ditherMode != KoiImageDitherMode.threshold)
    'ditherMode': e.ditherMode.name,
};

KoiLabelImageElement _labelImageFromJson(Map<String, dynamic> j) =>
    KoiLabelImageElement(
      x: j['x'] as int,
      y: j['y'] as int,
      imageBytes: Uint8List.fromList(base64Decode(j['imageBytes'] as String)),
      width: j['width'] as int?,
      ditherMode: _enumByName(
        KoiImageDitherMode.values,
        j['ditherMode'],
        KoiImageDitherMode.threshold,
      ),
    );

// ── Label Print ──
Map<String, dynamic> _labelPrintToJson(KoiLabelPrintElement e) => {
  'type': 'labelPrint',
  if (e.copies != 1) 'copies': e.copies,
  if (e.sets != 1) 'sets': e.sets,
};

KoiLabelPrintElement _labelPrintFromJson(Map<String, dynamic> j) =>
    KoiLabelPrintElement(
      copies: j['copies'] as int? ?? 1,
      sets: j['sets'] as int? ?? 1,
    );

// ── Raw Command ──
Map<String, dynamic> _rawCommandToJson(KoiRawCommandElement e) => {
  'type': 'rawCommand',
  'command': e.command,
};

KoiRawCommandElement _rawCommandFromJson(Map<String, dynamic> j) =>
    KoiRawCommandElement(j['command'] as String);

// ── Label ForEach ──
Map<String, dynamic> _labelForEachToJson(KoiLabelForEachElement e) => {
  'type': 'labelForEach',
  'listKey': e.listKey,
  'templates': e.templates.map(koiLabelElementToJson).toList(),
};

KoiLabelForEachElement _labelForEachFromJson(Map<String, dynamic> j) =>
    KoiLabelForEachElement(
      listKey: j['listKey'] as String,
      templates:
          (j['templates'] as List)
              .map((e) => koiLabelElementFromJson(e as Map<String, dynamic>))
              .toList(),
    );

// ── Label Block Text ──
Map<String, dynamic> _labelBlockTextToJson(KoiLabelBlockTextElement e) => {
  'type': 'labelBlockText',
  'x': e.x,
  'y': e.y,
  'width': e.width,
  'height': e.height,
  'text': e.text,
  if (e.font != 'TSS24.BF2') 'font': e.font,
  if (e.rotation != 0) 'rotation': e.rotation,
  if (e.xScale != 1) 'xScale': e.xScale,
  if (e.yScale != 1) 'yScale': e.yScale,
  if (e.space != 0) 'space': e.space,
  if (e.align != 0) 'align': e.align,
  if (e.fit != 0) 'fit': e.fit,
};

KoiLabelBlockTextElement _labelBlockTextFromJson(Map<String, dynamic> j) =>
    KoiLabelBlockTextElement(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int,
      text: j['text'] as String,
      font: j['font'] as String? ?? 'TSS24.BF2',
      rotation: j['rotation'] as int? ?? 0,
      xScale: j['xScale'] as int? ?? 1,
      yScale: j['yScale'] as int? ?? 1,
      space: j['space'] as int? ?? 0,
      align: j['align'] as int? ?? 0,
      fit: j['fit'] as int? ?? 0,
    );

// ── Label Circle ──
Map<String, dynamic> _labelCircleToJson(KoiLabelCircleElement e) => {
  'type': 'labelCircle',
  'x': e.x,
  'y': e.y,
  'diameter': e.diameter,
  if (e.thickness != 2) 'thickness': e.thickness,
};

KoiLabelCircleElement _labelCircleFromJson(Map<String, dynamic> j) =>
    KoiLabelCircleElement(
      x: j['x'] as int,
      y: j['y'] as int,
      diameter: j['diameter'] as int,
      thickness: j['thickness'] as int? ?? 2,
    );

// ── Label Ellipse ──
Map<String, dynamic> _labelEllipseToJson(KoiLabelEllipseElement e) => {
  'type': 'labelEllipse',
  'x': e.x,
  'y': e.y,
  'width': e.width,
  'height': e.height,
  if (e.thickness != 2) 'thickness': e.thickness,
};

KoiLabelEllipseElement _labelEllipseFromJson(Map<String, dynamic> j) =>
    KoiLabelEllipseElement(
      x: j['x'] as int,
      y: j['y'] as int,
      width: j['width'] as int,
      height: j['height'] as int,
      thickness: j['thickness'] as int? ?? 2,
    );

// ── Label Diagonal ──
Map<String, dynamic> _labelDiagonalToJson(KoiLabelDiagonalElement e) => {
  'type': 'labelDiagonal',
  'x': e.x,
  'y': e.y,
  'xEnd': e.xEnd,
  'yEnd': e.yEnd,
  if (e.thickness != 2) 'thickness': e.thickness,
};

KoiLabelDiagonalElement _labelDiagonalFromJson(Map<String, dynamic> j) =>
    KoiLabelDiagonalElement(
      x: j['x'] as int,
      y: j['y'] as int,
      xEnd: j['xEnd'] as int,
      yEnd: j['yEnd'] as int,
      thickness: j['thickness'] as int? ?? 2,
    );

// ── Label Beep ──
Map<String, dynamic> _labelBeepToJson(KoiLabelBeepElement e) => {
  'type': 'labelBeep',
  if (e.level != 0) 'level': e.level,
  if (e.interval != 100) 'interval': e.interval,
};

KoiLabelBeepElement _labelBeepFromJson(Map<String, dynamic> j) =>
    KoiLabelBeepElement(
      level: j['level'] as int? ?? 0,
      interval: j['interval'] as int? ?? 100,
    );

// ── Label Cut ──
Map<String, dynamic> _labelCutToJson(KoiLabelCutElement e) => {
  'type': 'labelCut',
};

KoiLabelCutElement _labelCutFromJson(Map<String, dynamic> j) =>
    const KoiLabelCutElement();

// ── Label Feed ──
Map<String, dynamic> _labelFeedToJson(KoiLabelFeedElement e) => {
  'type': 'labelFeed',
  if (e.dots != 100) 'dots': e.dots,
};

KoiLabelFeedElement _labelFeedFromJson(Map<String, dynamic> j) =>
    KoiLabelFeedElement(
      dots: j['dots'] as int? ?? 100,
    );

// ═══════════════════════════════════════════════════════════
// 工具方法
// ═══════════════════════════════════════════════════════════

/// 安全地从枚举名称查找枚举值, 不存在时返回默认值。
T _enumByName<T extends Enum>(List<T> values, Object? name, T defaultValue) {
  if (name == null) return defaultValue;
  final nameStr = name.toString();
  for (final value in values) {
    if (value.name == nameStr) return value;
  }
  return defaultValue;
}

/// 解析 KoiPaperSize (支持 int widthMm)。
KoiPaperSize _parsePaperSize(Object? value) {
  if (value is int) {
    return switch (value) {
      80 => KoiPaperSize.mm80,
      58 => KoiPaperSize.mm58,
      _ => KoiPaperSize.custom(value),
    };
  }
  if (value is String) {
    return switch (value) {
      'mm80' => KoiPaperSize.mm80,
      'mm58' => KoiPaperSize.mm58,
      _ => KoiPaperSize.mm80,
    };
  }
  return KoiPaperSize.mm80;
}

// ─── PDF417 ────────────────────────────────────────────────

KoiLabelPdf417Element _labelPdf417FromJson(Map<String, dynamic> json) {
  return KoiLabelPdf417Element(
    x: json['x'] as int? ?? 0,
    y: json['y'] as int? ?? 0,
    width: json['width'] as int? ?? 200,
    height: json['height'] as int? ?? 100,
    rotation: json['rotation'] as int? ?? 0,
    errorLevel: json['errorLevel'] as int? ?? 1,
    columns: json['columns'] as int? ?? 3,
    rows: json['rows'] as int? ?? 0,
    option: json['option'] as String? ?? '',
    data: json['data'] as String? ?? '',
  );
}

Map<String, dynamic> _labelPdf417ToJson(KoiLabelPdf417Element e) {
  return {
    'type': 'labelPdf417',
    'x': e.x,
    'y': e.y,
    'width': e.width,
    'height': e.height,
    'rotation': e.rotation,
    'errorLevel': e.errorLevel,
    'columns': e.columns,
    'rows': e.rows,
    'option': e.option,
    'data': e.data,
  };
}
