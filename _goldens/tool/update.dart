import 'dart:io';

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
  final output = Directory.current.path;
  final input = '$output/packages/_goldens';
  copyPathSync(input, output);
}
