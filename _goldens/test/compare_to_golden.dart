library compare_to_golden;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future compareSummaryFileToGolden(String dartFileName,
    {String summaryExtension, String goldenExtension}) async {
  var input = getFile(dartFileName, summaryExtension);
  var golden = getFile(dartFileName, goldenExtension);

  final formattedInput = _formatter.format(await input.readAsString());
  final formattedGolden = _formatter.format(await golden.readAsString());
  expect(formattedInput, formattedGolden);
}

File getFile(String dartFileName, String extension) =>
    _getFile('${p.withoutExtension(dartFileName)}$extension');

File _getFile(String filename) {
  Uri fileUri = new Uri.file(p.join(_testFilesDir, filename));
  return new File.fromUri(fileUri);
}

final String _testFilesDir = p.join(_scriptDir(), '../test_files');

String _scriptDir() =>
    p.dirname(currentMirrorSystem().findLibrary(#compare_to_golden).uri.path);

final _formatter = new DartFormatter();
