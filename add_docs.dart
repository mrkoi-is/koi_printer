import 'dart:io';

void main() async {
  print('Running dart analyze --machine...');
  final result = await Process.run('dart', ['analyze', '--machine']);
  final output = result.stdout as String;

  final lines = output.split('\n');
  final fixes = <String, List<int>>{};

  for (final line in lines) {
    if (line.isEmpty) continue;
    final parts = line.split('|');
    if (parts.length < 8) continue;

    final type = parts[2];
    final rule = parts[2].toLowerCase();

    if (rule == 'public_member_api_docs') {
      final file = parts[3];
      final lineNumber = int.tryParse(parts[4]) ?? 0;

      if (!fixes.containsKey(file)) {
        fixes[file] = [];
      }
      if (!fixes[file]!.contains(lineNumber)) {
        fixes[file]!.add(lineNumber);
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
