import 'dart:io';

void fixTodos(Directory dir) {
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      if (content.contains('/// Documentation for this public member.')) {
        content = content.replaceAll(
          '/// Documentation for this public member.',
          '/// Documentation for this public member.',
        );
        entity.writeAsStringSync(content);
        print('Fixed todos in ${entity.path}');
      }
    }
  }
}

void main() {
  fixTodos(Directory('/Users/max/Workspace/SourceCode/mrkoi/koit_printer'));
}
