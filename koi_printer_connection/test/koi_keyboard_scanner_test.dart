// ignore_for_file: lines_longer_than_80_chars // rationale: long strings in tests
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_connection/src/scanner/koi_keyboard_scanner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KoiKeyboardScanner', () {
    late KoiKeyboardScanner scanner;

    setUp(() {
      scanner = KoiKeyboardScanner(timeout: const Duration(milliseconds: 100));
    });

    tearDown(() {
      scanner.dispose();
    });

    KeyDownEvent createEvent(LogicalKeyboardKey key, {String? character}) {
      return KeyDownEvent(
        logicalKey: key,
        physicalKey: PhysicalKeyboardKey.keyA,
        timeStamp: Duration.zero,
        character: character,
      );
    }

    test('captures barcode followed by enter', () async {
      final results = <String>[];
      final sub = scanner.scanStream.listen(results.add);

      scanner
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.keyA, character: 'A'))
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.keyB, character: 'B'))
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.keyC, character: 'C'))
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.enter));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(results, ['ABC']);

      await sub.cancel();
    });

    test('clears buffer on timeout', () async {
      final results = <String>[];
      final sub = scanner.scanStream.listen(results.add);

      scanner.handleKeyEvent(
        createEvent(LogicalKeyboardKey.keyA, character: 'A'),
      );

      // Wait longer than timeout
      await Future<void>.delayed(const Duration(milliseconds: 150));

      scanner
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.keyB, character: 'B'))
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.enter));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(results, ['B']);

      await sub.cancel();
    });

    test('ignores enter if buffer empty', () async {
      final results = <String>[];
      final sub = scanner.scanStream.listen(results.add);

      scanner.handleKeyEvent(createEvent(LogicalKeyboardKey.enter));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(results, isEmpty);

      await sub.cancel();
    });

    test('handles non-character keys', () async {
      final results = <String>[];
      final sub = scanner.scanStream.listen(results.add);

      // logicalKey doesn't match enter, and character is null/empty
      scanner
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.shift))
        ..handleKeyEvent(createEvent(LogicalKeyboardKey.enter));

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(results, isEmpty);

      await sub.cancel();
    });
  });
}
