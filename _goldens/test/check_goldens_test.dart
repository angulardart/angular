@TestOn('vm')
import 'dart:io' show Directory, File, Platform;

import 'package:glob/glob.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'src/compare_to_golden.dart';

final _outputModes = ['template', 'outline'];
final _inputFiles = p.join('test', '_files', '**.dart');
final _isBazel = Platform.environment['RUNFILES'] != null;

void main() {
  Glob findFiles;
  String path;
  if (_isBazel) {
    path = p.join(
      p.current,
      Platform.environment['BAZEL_ROOT_PATH'],
    );
    if (path == null) {
      // Bazel specific: Use an environment variable to define the root path.
      throw ArgumentError('BAZEL_ROOT_PATH not defined (via -D)');
    }
    if (!Directory(path).existsSync()) {
      throw StateError(
        'Directory not found: $path (in ${Directory.current})',
      );
    }
    findFiles = Glob(p.join(path, _inputFiles));
  } else {
    // TODO(https://github.com/dart-lang/build/issues/1079):
    // Use a similar approach to Bazel to avoid special configuration for tests.
    path = 'build';
    if (!File(p.join(path, '.build.manifest')).existsSync()) {
      // Build runner specific: We require --precompiled=build.
      throw StateError('Test must be executed via --precompiled=build');
    }
    findFiles = Glob(p.join(path, _inputFiles));
  }
  final inputDartFiles = findFiles.listSync();
  if (inputDartFiles.isEmpty) {
    throw StateError('Expected 1 or more tests, got 0 from $findFiles');
  }
  for (final mode in _outputModes) {
    group('Goldens for "$mode" should be updated in', () {
      for (final file in inputDartFiles) {
        test(file.path, () {
          compareCheckFileToGolden(
            file.path,
            checkExtension: '.$mode.check',
            goldenExtension: '.$mode.golden',
          );
        });
      }
    });
  }

  if (_isBazel) {
    test('Dart2JS', () {
      compareCheckFileToGolden(
        p.join(path, 'test', '_files', 'dart2js', 'dart2js_golden.dart'),
        formatDart: false,
        checkExtension: '.check',
        goldenExtension: '.golden',
      );
    });
  }
}
