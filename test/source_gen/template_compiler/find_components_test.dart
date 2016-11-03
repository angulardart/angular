@TestOn('vm')
library template_compiler_test;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const String summaryExtension = '.ng_summary';
const String goldenExtension = '.golden';

main() {
  group('Test Components', () {
    test('test_foo', () async {
      await compareSummaryFileToGolden('test_foo.dart');
    });

    test('has_directives', () async {
      await compareSummaryFileToGolden('has_directives.dart');
    });

    test('change_detection', () async {
      await compareSummaryFileToGolden('change_detection.dart');
    });

    test('view_encapuslation', () async {
      await compareSummaryFileToGolden('view_encapsulation.dart');
    });

    test('export_as', () async {
      await compareSummaryFileToGolden('export_as.dart');
    });

    test('directives', () async {
      await compareSummaryFileToGolden('directives/base_component.dart');
    });

    test('has_template_file', () async {
      await compareSummaryFileToGolden('templates/has_template_file.dart');
    });
  });
}

Future compareSummaryFileToGolden(String dartFileName) async {
  var input = getFile(dartFileName, summaryExtension);
  var golden = getFile(dartFileName, goldenExtension);

  expect(await input.readAsString(), await golden.readAsString());
}

File getFile(String dartFileName, String extension) =>
    _getFile('${p.withoutExtension(dartFileName)}${extension}');

File _getFile(String filename) {
  Uri fileUri = new Uri.file(p.join(_testFilesDir, filename));
  return new File.fromUri(fileUri);
}

final String _testFilesDir = p.join(_scriptDir(), 'test_files');

String _scriptDir() => p.dirname(
    currentMirrorSystem().findLibrary(#template_compiler_test).uri.path);
