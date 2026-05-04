import 'package:flutter/material.dart';
import 'package:koi_printer_command/koi_printer_command.dart';

/// 打印元素属性编辑器。
/// Property editor for print elements.
class KoiElementEditor<T extends Object> extends StatefulWidget {
  /// 创建一个元素编辑器。
  const KoiElementEditor({
    required this.element,
    required this.onChanged,
    super.key,
  });

  /// 当前需要编辑的打印元素。
  final T element;

  /// 当属性修改时触发的回调，返回全新的元素实例。
  final ValueChanged<T> onChanged;

  @override
  State<KoiElementEditor<T>> createState() => _KoiElementEditorState<T>();
}

class _KoiElementEditorState<T extends Object>
    extends State<KoiElementEditor<T>> {
  final _textController = TextEditingController();
  final _dataController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  @override
  void didUpdateWidget(KoiElementEditor<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element != widget.element) {
      _initControllers();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _dataController.dispose();
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _initControllers() {
    final e = widget.element;
    if (e is KoiTextElement) {
      if (_textController.text != e.text) _textController.text = e.text;
    } else if (e is KoiBarcodeElement) {
      if (_dataController.text != e.data) _dataController.text = e.data;
    } else if (e is KoiQrCodeElement) {
      if (_dataController.text != e.data) _dataController.text = e.data;
    } else if (e is KoiPositionedTextElement) {
      if (_textController.text != e.text) _textController.text = e.text;
      if (_xController.text != e.x.toString()) {
        _xController.text = e.x.toString();
      }
      if (_yController.text != e.y.toString()) {
        _yController.text = e.y.toString();
      }
    } else if (e is KoiPositionedBarcodeElement) {
      if (_dataController.text != e.data) _dataController.text = e.data;
      if (_xController.text != e.x.toString()) {
        _xController.text = e.x.toString();
      }
      if (_yController.text != e.y.toString()) {
        _yController.text = e.y.toString();
      }
    } else if (e is KoiPositionedQrCodeElement) {
      if (_dataController.text != e.data) _dataController.text = e.data;
      if (_xController.text != e.x.toString()) {
        _xController.text = e.x.toString();
      }
      if (_yController.text != e.y.toString()) {
        _yController.text = e.y.toString();
      }
    } else if (e is KoiLabelBoxElement) {
      if (_xController.text != e.x.toString()) {
        _xController.text = e.x.toString();
      }
      if (_yController.text != e.y.toString()) {
        _yController.text = e.y.toString();
      }
    } else if (e is KoiLabelReverseElement) {
      if (_xController.text != e.x.toString()) {
        _xController.text = e.x.toString();
      }
      if (_yController.text != e.y.toString()) {
        _yController.text = e.y.toString();
      }
    }
  }

  int _parseInt(String value, int fallback) {
    return int.tryParse(value) ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.element;

    if (e is KoiTextElement) return _buildTextEditor(e);
    if (e is KoiBarcodeElement) return _buildBarcodeEditor(e);
    if (e is KoiQrCodeElement) return _buildQrEditor(e);
    if (e is KoiPositionedTextElement) return _buildPosTextEditor(e);
    if (e is KoiPositionedBarcodeElement) return _buildPosBarcodeEditor(e);
    if (e is KoiPositionedQrCodeElement) return _buildPosQrEditor(e);
    if (e is KoiLabelBoxElement) return _buildBoxEditor(e);
    if (e is KoiLabelReverseElement) return _buildReverseEditor(e);

    return const Padding(
      padding: EdgeInsets.all(16),
      child: Text('此元素暂不支持编辑 / Editing not supported for this element'),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdown<E>(
    String label,
    E value,
    List<E> items,
    String Function(E) labelBuilder,
    ValueChanged<E?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<E>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        items:
            items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(labelBuilder(item)),
              );
            }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildTextEditor(KoiTextElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField('文本内容 (Text)', _textController, (val) {
          widget.onChanged(
            KoiTextElement(
                  text: val,
                  bold: e.bold,
                  reverse: e.reverse,
                  size: e.size,
                  font: e.font,
                  align: e.align,
                )
                as T,
          );
        }),
        _buildDropdown<KoiTextAlign>(
          '对齐方式 (Align)',
          e.align,
          KoiTextAlign.values,
          (a) => a.name,
          (val) {
            if (val != null) {
              widget.onChanged(
                KoiTextElement(
                      text: e.text,
                      bold: e.bold,
                      reverse: e.reverse,
                      size: e.size,
                      font: e.font,
                      align: val,
                    )
                    as T,
              );
            }
          },
        ),
        _buildDropdown<KoiTextSize>(
          '字体大小 (Size)',
          e.size,
          KoiTextSize.values,
          (s) => s.name,
          (val) {
            if (val != null) {
              widget.onChanged(
                KoiTextElement(
                      text: e.text,
                      bold: e.bold,
                      reverse: e.reverse,
                      size: val,
                      font: e.font,
                      align: e.align,
                    )
                    as T,
              );
            }
          },
        ),
        _buildSwitch('加粗 (Bold)', e.bold, (val) {
          widget.onChanged(
            KoiTextElement(
                  text: e.text,
                  bold: val,
                  reverse: e.reverse,
                  size: e.size,
                  font: e.font,
                  align: e.align,
                )
                as T,
          );
        }),
        _buildSwitch('反白 (Reverse)', e.reverse, (val) {
          widget.onChanged(
            KoiTextElement(
                  text: e.text,
                  bold: e.bold,
                  reverse: val,
                  size: e.size,
                  font: e.font,
                  align: e.align,
                )
                as T,
          );
        }),
      ],
    );
  }

  Widget _buildBarcodeEditor(KoiBarcodeElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField('条码数据 (Data)', _dataController, (val) {
          widget.onChanged(
            KoiBarcodeElement(
                  data: val,
                  type: e.type,
                  height: e.height,
                  width: e.width,
                  align: e.align,
                  textPosition: e.textPosition,
                  font: e.font,
                )
                as T,
          );
        }),
        _buildDropdown<KoiTextAlign>(
          '对齐方式 (Align)',
          e.align,
          KoiTextAlign.values,
          (a) => a.name,
          (val) {
            if (val != null) {
              widget.onChanged(
                KoiBarcodeElement(
                      data: e.data,
                      type: e.type,
                      height: e.height,
                      width: e.width,
                      align: val,
                      textPosition: e.textPosition,
                      font: e.font,
                    )
                    as T,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildQrEditor(KoiQrCodeElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTextField('QR数据 (Data)', _dataController, (val) {
          widget.onChanged(
            KoiQrCodeElement(
                  data: val,
                  size: e.size,
                  align: e.align,
                  correction: e.correction,
                )
                as T,
          );
        }),
        _buildDropdown<KoiTextAlign>(
          '对齐方式 (Align)',
          e.align,
          KoiTextAlign.values,
          (a) => a.name,
          (val) {
            if (val != null) {
              widget.onChanged(
                KoiQrCodeElement(
                      data: e.data,
                      size: e.size,
                      align: val,
                      correction: e.correction,
                    )
                    as T,
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPosTextEditor(KoiPositionedTextElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('X', _xController, (val) {
                widget.onChanged(
                  KoiPositionedTextElement(
                        x: _parseInt(val, e.x),
                        y: e.y,
                        text: e.text,
                        fontSize: e.fontSize,
                        font: e.font,
                        rotation: e.rotation,
                        xScale: e.xScale,
                        yScale: e.yScale,
                        bold: e.bold,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Y', _yController, (val) {
                widget.onChanged(
                  KoiPositionedTextElement(
                        x: e.x,
                        y: _parseInt(val, e.y),
                        text: e.text,
                        fontSize: e.fontSize,
                        font: e.font,
                        rotation: e.rotation,
                        xScale: e.xScale,
                        yScale: e.yScale,
                        bold: e.bold,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
          ],
        ),
        _buildTextField('文本内容 (Text)', _textController, (val) {
          widget.onChanged(
            KoiPositionedTextElement(
                  x: e.x,
                  y: e.y,
                  text: val,
                  fontSize: e.fontSize,
                  font: e.font,
                  rotation: e.rotation,
                  xScale: e.xScale,
                  yScale: e.yScale,
                  bold: e.bold,
                )
                as T,
          );
        }),
        _buildSwitch('加粗 (Bold)', e.bold, (val) {
          widget.onChanged(
            KoiPositionedTextElement(
                  x: e.x,
                  y: e.y,
                  text: e.text,
                  fontSize: e.fontSize,
                  font: e.font,
                  rotation: e.rotation,
                  xScale: e.xScale,
                  yScale: e.yScale,
                  bold: val,
                )
                as T,
          );
        }),
      ],
    );
  }

  Widget _buildPosBarcodeEditor(KoiPositionedBarcodeElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('X', _xController, (val) {
                widget.onChanged(
                  KoiPositionedBarcodeElement(
                        x: _parseInt(val, e.x),
                        y: e.y,
                        data: e.data,
                        height: e.height,
                        type: e.type,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Y', _yController, (val) {
                widget.onChanged(
                  KoiPositionedBarcodeElement(
                        x: e.x,
                        y: _parseInt(val, e.y),
                        data: e.data,
                        height: e.height,
                        type: e.type,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
          ],
        ),
        _buildTextField('条码数据 (Data)', _dataController, (val) {
          widget.onChanged(
            KoiPositionedBarcodeElement(
                  x: e.x,
                  y: e.y,
                  data: val,
                  height: e.height,
                  type: e.type,
                )
                as T,
          );
        }),
      ],
    );
  }

  Widget _buildPosQrEditor(KoiPositionedQrCodeElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('X', _xController, (val) {
                widget.onChanged(
                  KoiPositionedQrCodeElement(
                        x: _parseInt(val, e.x),
                        y: e.y,
                        data: e.data,
                        cellSize: e.cellSize,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Y', _yController, (val) {
                widget.onChanged(
                  KoiPositionedQrCodeElement(
                        x: e.x,
                        y: _parseInt(val, e.y),
                        data: e.data,
                        cellSize: e.cellSize,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
          ],
        ),
        _buildTextField('QR数据 (Data)', _dataController, (val) {
          widget.onChanged(
            KoiPositionedQrCodeElement(
                  x: e.x,
                  y: e.y,
                  data: val,
                  cellSize: e.cellSize,
                )
                as T,
          );
        }),
      ],
    );
  }

  Widget _buildBoxEditor(KoiLabelBoxElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('X', _xController, (val) {
                widget.onChanged(
                  KoiLabelBoxElement(
                        x: _parseInt(val, e.x),
                        y: e.y,
                        width: e.width,
                        height: e.height,
                        thickness: e.thickness,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Y', _yController, (val) {
                widget.onChanged(
                  KoiLabelBoxElement(
                        x: e.x,
                        y: _parseInt(val, e.y),
                        width: e.width,
                        height: e.height,
                        thickness: e.thickness,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReverseEditor(KoiLabelReverseElement e) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField('X', _xController, (val) {
                widget.onChanged(
                  KoiLabelReverseElement(
                        x: _parseInt(val, e.x),
                        y: e.y,
                        width: e.width,
                        height: e.height,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTextField('Y', _yController, (val) {
                widget.onChanged(
                  KoiLabelReverseElement(
                        x: e.x,
                        y: _parseInt(val, e.y),
                        width: e.width,
                        height: e.height,
                      )
                      as T,
                );
              }, keyboardType: TextInputType.number),
            ),
          ],
        ),
      ],
    );
  }
}
