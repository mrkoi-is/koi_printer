import 'dart:async';

import 'package:flutter/services.dart';

/// 键盘输入扫描器 (外接扫码枪监听)。
/// Keyboard input scanner for HID Barcode/QR scanners.
///
/// 拦截硬件键盘事件，将连续快速输入的字符流组装成条码。
/// 常用于外接 USB/蓝牙 扫码枪的场景。
class KoiKeyboardScanner {
  /// 创建键盘扫码枪监听器。
  ///
  /// [timeout] 两次击键之间的最大间隔时间，超过则视为人工输入并清空缓冲区 (默认 50ms)。
  KoiKeyboardScanner({
    this.timeout = const Duration(milliseconds: 50),
    this.consumeEvents = false,
  }) {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// 两次击键之间的最大间隔时间。
  final Duration timeout;

  /// 是否拦截并消耗键盘事件 (阻止事件传递给下层组件)。
  final bool consumeEvents;

  final StreamController<String> _scanController =
      StreamController<String>.broadcast();

  final StringBuffer _buffer = StringBuffer();
  Timer? _timer;

  /// 扫码结果数据流。
  Stream<String> get scanStream => _scanController.stream;

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final key = event.logicalKey;

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        if (_buffer.isNotEmpty) {
          _scanController.add(_buffer.toString());
          _buffer.clear();
          _timer?.cancel();
          return consumeEvents;
        }
      }

      final char = event.character;
      if (char != null && char.isNotEmpty) {
        _buffer.write(char);

        _timer?.cancel();
        _timer = Timer(timeout, _buffer.clear);

        // 如果缓冲区积累了字符，视情况决定是否消耗该事件
        if (consumeEvents && _buffer.length > 1) {
          return true;
        }
      }
    }
    return false;
  }

  /// 释放资源并移除键盘监听。
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _timer?.cancel();
    _scanController.close();
  }
}
