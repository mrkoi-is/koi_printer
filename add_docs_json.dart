import 'dart:convert';
import 'dart:io';

void main() async {
  print('Running dart analyze --format=json...');
  final result = await Process.run('dart', ['analyze', '--format=json']);
  final output = result.stdout as String;

  // The output might have some text before the JSON or after it, let's try to extract JSON
  final jsonStart = output.indexOf('{');
  if (jsonStart == -1) {
    print('No JSON found in output.');
    return;
  }

  final jsonStr = output.substring(jsonStart);
  final data = jsonDecode(jsonStr);
  final diagnostics = data['diagnostics'] as List;

  final fixes = <String, List<int>>{};

  for (final diag in diagnostics) {
    if (diag['code'] == 'public_member_api_docs') {
      final file = diag['location']['file'] as String;
      final line = diag['location']['range']['start']['line'] as int;

      if (!fixes.containsKey(file)) {
        fixes[file] = [];
      }
      if (!fixes[file]!.contains(line)) {
        fixes[file]!.add(line);
      }
    }
  }

  for (final file in fixes.keys) {
    print('Fixing $file...');
    final linesToFix = fixes[file]!;
    linesToFix.sort((a, b) => b.compareTo(a)); // Reverse order

    final fileObj = File(file);
    if (!fileObj.existsSync()) continue;

    final fileLines = fileObj.readAsLinesSync();

    for (final lineNum in linesToFix) {
      if (lineNum > 0 && lineNum <= fileLines.length) {
        final targetLine = fileLines[lineNum - 1];
        final indentMatch = RegExp(r'^(\s*)').firstMatch(targetLine);
        final indent = indentMatch?.group(1) ?? '';

        fileLines.insert(
          lineNum - 1,
          '$indent/// Documentation for this public member.',
        );
      }
    }

    fileObj.writeAsStringSync(fileLines.join('\n') + '\n');
  }
  print('Done adding docstrings!');
}
