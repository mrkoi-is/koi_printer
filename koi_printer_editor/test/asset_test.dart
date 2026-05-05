import 'package:flutter_test/flutter_test.dart';
import 'package:koi_printer_editor/utils/template_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('can load templates from assets in tests', () async {
    final templates = await KoiTemplateLoader.loadAllTemplates();
    expect(templates, isNotEmpty);
  });
}
