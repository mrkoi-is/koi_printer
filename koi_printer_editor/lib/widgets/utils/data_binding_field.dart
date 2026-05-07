import 'package:flutter/material.dart';
import 'package:koi_printer_editor/state/editor_state.dart';
import 'package:provider/provider.dart';

class DataBindingField extends StatefulWidget {
  const DataBindingField({
    super.key,
    required this.text,
    required this.onUpdate,
    this.allowExpression = true,
  });

  final String text;
  final ValueChanged<String> onUpdate;
  final bool allowExpression;

  @override
  State<DataBindingField> createState() => _DataBindingFieldState();
}

class _DataBindingFieldState extends State<DataBindingField> {
  int _modeIndex = 0;

  @override
  void initState() {
    super.initState();
    _determineInitialMode();
  }

  @override
  void didUpdateWidget(covariant DataBindingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _determineInitialMode();
    }
  }

  void _determineInitialMode() {
    final text = widget.text;
    final isExactVariable = RegExp(
      r'^\{\{([a-zA-Z0-9_.]+)\}\}$',
    ).hasMatch(text);
    final hasVariables = text.contains('{{') && text.contains('}}');

    if (isExactVariable) {
      _modeIndex = 1;
    } else if (hasVariables && widget.allowExpression) {
      _modeIndex = 2;
    } else {
      _modeIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = context.watch<EditorState>().schema;
    final text = widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<int>(
          segments: [
            const ButtonSegment(
              value: 0,
              label: Text('静态', style: TextStyle(fontSize: 12)),
            ),
            const ButtonSegment(
              value: 1,
              label: Text('单变量', style: TextStyle(fontSize: 12)),
            ),
            if (widget.allowExpression)
              const ButtonSegment(
                value: 2,
                label: Text('表达式', style: TextStyle(fontSize: 12)),
              ),
          ],
          selected: {_modeIndex},
          onSelectionChanged: (set) {
            setState(() {
              _modeIndex = set.first;
            });
            if (_modeIndex == 1) {
              if (!RegExp(r'^\{\{([a-zA-Z0-9_.]+)\}\}$').hasMatch(text) &&
                  fields.isNotEmpty) {
                widget.onUpdate('{{${fields.first.key}}}');
              }
            } else if (_modeIndex == 0) {
              widget.onUpdate(text.replaceAll(RegExp(r'\{\{|\}\}'), ''));
            }
          },
        ),
        const SizedBox(height: 12),
        if (_modeIndex == 0) ...[
          TextFormField(
            key: ValueKey('static_$text'),
            initialValue: text,
            decoration: const InputDecoration(
              labelText: '静态内容',
              border: OutlineInputBorder(),
            ),
            maxLines: widget.allowExpression ? 3 : 1,
            onChanged: widget.onUpdate,
          ),
        ] else if (_modeIndex == 1) ...[
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: RegExp(
              r'^\{\{([a-zA-Z0-9_.]+)\}\}$',
            ).firstMatch(text)?.group(1),
            decoration: const InputDecoration(
              labelText: '绑定业务字段',
              border: OutlineInputBorder(),
            ),
            items: fields
                .map(
                  (f) => DropdownMenuItem(
                    value: f.key,
                    child: Text(
                      '${f.label} (${f.key})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val != null) widget.onUpdate('{{$val}}');
            },
          ),
        ] else if (widget.allowExpression) ...[
          TextFormField(
            key: ValueKey('expr_$text'),
            initialValue: text,
            decoration: const InputDecoration(
              labelText: '模板表达式',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: widget.onUpdate,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: fields
                .map(
                  (f) => ActionChip(
                    label: Text(f.label, style: const TextStyle(fontSize: 10)),
                    onPressed: () => widget.onUpdate('$text{{${f.key}}}'),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}
