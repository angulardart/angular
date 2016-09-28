@TestOn('vm')
library template_compiler_test;

import 'dart:async';
import 'dart:io';
import 'dart:mirrors';

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

import 'component_extractor_generator.dart';

const String summaryExtension = '.ng_summary';

main() {
  group('Test Components', () {
    GeneratorBuilder testBuilder;
    setUp(() {
      testBuilder = testComponentExtractor(extension: summaryExtension);
    });

    test('test_foo', () async {
      await testCodeGen('test_foo.dart', testBuilder);
    });

    test('has_directives', () async {
      await testCodeGen('has_directives.dart', testBuilder);
    });

    test('change_detection', () async {
      await testCodeGen('change_detection.dart', testBuilder);
    });

    test('view_encapuslation', () async {
      await testCodeGen('view_encapsulation.dart', testBuilder);
    });

    test('export_as', () async {
      await testCodeGen('export_as.dart', testBuilder);
    });

    test('has_template_file', () async {
      await testCodeGen('templates/has_template_file.dart', testBuilder);
    });
  });
}

Future testCodeGen(String dartFileName, Builder testBuilder) async {
  var relativeDartPath = p.join(testFiles, dartFileName);
  var phase = new PhaseGroup.singleAction(
      testBuilder, new InputSet('angular2', [relativeDartPath]));

  var result = await build(phase, writer: new InMemoryAssetWriter());

  var outputId = new AssetId('angular2', relativeDartPath)
      .changeExtension(summaryExtension);
  var goldenPath = '${p.withoutExtension(dartFileName)}.golden';
  var golden = await _getFile(goldenPath).readAsString();
  checkOutputs({outputId.toString(): golden}, result);
}

final String testFilesDir = p.join(_scriptDir(), 'test_files');

File _getFile(String filename) {
  Uri fileUri = new Uri.file(p.join(testFilesDir, filename));
  return new File.fromUri(fileUri);
}

String _scriptDir() => p.dirname(
    currentMirrorSystem().findLibrary(#template_compiler_test).uri.path);
