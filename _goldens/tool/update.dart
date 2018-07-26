import 'dart:io';

import 'package:path/path.dart' as p;

/// Updates the golden files in _goldens/test_files based on builder outputs.
///
/// Before running, execute the following:
/// ```
/// pub run build_runner build -o build
/// ```
///
/// Then:
/// ```
/// dart tool/update.dart
/// ```
void main() {
  final output = p.join(p.current, 'test', '_files');
  final input = p.join(p.current, 'build', 'test', '_files');
  _copyPathSync(input, output);
}

/// Copies all of the files in the [from] directory to [to].
///
/// This is similar to `cp -R <from> <to>`:
/// * Symlinks are supported.
/// * Existing files are over-written, if any.
/// * If [to] is within [from], throws [ArgumentError] (an infinite operation).
/// * If [from] and [to] are canonically the same, no operation occurs.
///
/// This action is performed synchronously (blocking I/O).
void _copyPathSync(String from, String to) {
  Directory(to).createSync(recursive: true);
  for (final file in Directory(from).listSync(recursive: true)) {
    var copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      Directory(copyTo).createSync(recursive: true);
    } else if (file is File && p.extension(file.path) == '.check') {
      copyTo = copyTo.replaceFirst('.check', '.golden');
      stdout.writeln('Copying $copyTo...');
      File(copyTo).writeAsStringSync(
        File(file.path).readAsStringSync(),
      );
    } else if (file is Link) {
      Link(copyTo).createSync(file.targetSync(), recursive: true);
    }
  }
}
