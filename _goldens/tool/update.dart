import 'dart:io';

import 'package:path/path.dart' as p;

/// Updates the golden files in _goldens/test_files based on builder outputs.
///
/// Before running, execute the following:
/// ```
/// pub run build_runner -o build
/// ```
///
/// Then:
/// ```
/// dart tool/goldens.dart
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
  new Directory(to).createSync(recursive: true);
  for (final file in new Directory(from).listSync(recursive: true)) {
    final copyTo = p.join(to, p.relative(file.path, from: from));
    if (file is Directory) {
      new Directory(copyTo).createSync(recursive: true);
    } else if (file is File) {
      new File(copyTo.replaceFirst('.check', '.golden')).writeAsStringSync(
        new File(file.path).readAsStringSync(),
      );
    } else if (file is Link) {
      new Link(copyTo).createSync(file.targetSync(), recursive: true);
    }
  }
}
