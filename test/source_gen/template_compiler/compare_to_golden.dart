library compare_to_golden;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

Future compareSummaryFileToGolden(String dartFileName,
    {String summaryExtension, String goldenExtension}) async {
  var input = getFile(dartFileName, summaryExtension);
  var golden = getFile(dartFileName, goldenExtension);

  var inputFile = new _CompareFile(await input.readAsString());
  var goldenFile = new _CompareFile(await golden.readAsString());

  // the file should match exactly, except for imports/exports
  expect(inputFile.sourceWithoutPorts, goldenFile.sourceWithoutPorts);

  // the imports/exports should match, but without caring about order
  expect(inputFile.ports, unorderedEquals(goldenFile.ports));
}

File getFile(String dartFileName, String extension) =>
    _getFile('${p.withoutExtension(dartFileName)}${extension}');

File _getFile(String filename) {
  Uri fileUri = new Uri.file(p.join(_testFilesDir, filename));
  return new File.fromUri(fileUri);
}

final String _testFilesDir = p.join(_scriptDir(), 'test_files');

String _scriptDir() =>
    p.dirname(currentMirrorSystem().findLibrary(#compare_to_golden).uri.path);

class _CompareFile {
  static final RegExp _portMatch = new RegExp("^(?:im|ex)port *");

  final String sourceWithoutPorts;
  final List<String> ports;

  _CompareFile._(this.sourceWithoutPorts, this.ports);

  factory _CompareFile(String source) {
    var buffer = new StringBuffer();
    var ports = <String>[];

    // might be null!
    bool doingPorts;

    for (var line in LineSplitter.split(source)) {
      // only do import/exports "once"
      if (_portMatch.hasMatch(line) && doingPorts != false) {
        if (doingPorts == null) {
          doingPorts = true;
        }

        ports.add(line);
      } else {
        if (doingPorts == true) {
          doingPorts = false;
        }
        buffer.writeln(line);
      }
    }

    return new _CompareFile._(buffer.toString(), ports);
  }
}
