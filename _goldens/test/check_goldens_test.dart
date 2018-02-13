@TestOn('vm')
import 'dart:io' show Directory, File, Platform;

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'src/compare_to_golden.dart';

final _outputModes = ['release', 'debug', 'outline'];
final _inputFiles = p.join('test', '_files', '**.dart');
final _isBazel = Platform.environment['RUNFILES'] != null;

void main() {
  Glob findFiles;
  if (_isBazel) {
    final path = p.join(
      p.current,
      const String.fromEnvironment('BAZEL_ROOT_PATH'),
    );
    if (path == null) {
      // Bazel specific: Use an environment variable to define the root path.
      throw new ArgumentError('BAZEL_ROOT_PATH not defined (via -D)');
    }
    if (!new Directory(path).existsSync()) {
      throw new ArgumentError(
        'Directory not found: $path (in ${Directory.current})',
      );
    }
    findFiles = new Glob(p.join(path, _inputFiles));
  } else {
    final path = 'build';
    if (!new File(p.join(path, 'test', '.packages')).existsSync()) {
      // Build runner specific: We require --precompiled=build.
      throw new ArgumentError('Test must be executed via --precompiled=build');
    }
    findFiles = new Glob(p.join(path, _inputFiles));
  }
  final inputDartFiles = findFiles.listSync();
  for (final mode in _outputModes) {
    group('Goldens for "$mode" should be updated in', () {
      for (final file in inputDartFiles) {
        test(file.path, () {
          compareCheckFileToGolden(
            file.path,
            checkExtension: '.template_$mode.check',
            goldenExtension: '.template_$mode.golden',
          );
        });
      }
    });
  }
}
