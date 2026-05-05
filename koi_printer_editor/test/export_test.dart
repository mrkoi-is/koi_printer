import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_editor/mock_templates.dart';

void main() {
  test('export mock templates to json files', () async {
    final dir = Directory('assets/templates');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    for (final m in templateManifests) {
      final file = File('${dir.path}/${m.id}.json');
      final jsonStr = m.toJsonString();
      await file.writeAsString(jsonStr);
      print('Exported ${m.id}.json');
    }
  });
}
