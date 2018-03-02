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
  String path;
  if (_isBazel) {
    path = p.join(
      p.current,
      const String.fromEnvironment('BAZEL_ROOT_PATH'),
    );
    if (path == null) {
      // Bazel specific: Use an environment variable to define the root path.
      throw new ArgumentError('BAZEL_ROOT_PATH not defined (via -D)');
    }
    if (!new Directory(path).existsSync()) {
      throw new StateError(
        'Directory not found: $path (in ${Directory.current})',
      );
    }
    findFiles = new Glob(p.join(path, _inputFiles));
  } else {
    // TODO(https://github.com/dart-lang/build/issues/1079):
    // Use a similar approach to Bazel to avoid special configuration for tests.
    path = 'build';
    if (!new File(p.join(path, 'test', '.packages')).existsSync()) {
      // Build runner specific: We require --precompiled=build.
      throw new StateError('Test must be executed via --precompiled=build');
    }
    findFiles = new Glob(p.join(path, _inputFiles));
  }
  final inputDartFiles = findFiles.listSync();
  if (inputDartFiles.isEmpty) {
    throw new StateError('Expected 1 or more tests, got 0 from $findFiles');
  }
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
