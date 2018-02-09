import 'package:path/path.dart' as p;
import 'package:io/io.dart';

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
  copyPathSync(input, output);
}
