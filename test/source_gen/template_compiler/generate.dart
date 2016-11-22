import 'dart:async';
import 'package:angular2/src/source_gen/template_compiler/testing/component_extractor_generator.dart';
import 'package:args/args.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';

const updateGoldens = 'update-goldens';

/// This script runs the source_gen test generators. This is requried before the
/// tests can run, since they check the output of these generators against
/// golden files.
///
/// To update the golden files, in the root angular2 directory, run
/// `pub get` and then
/// `dart test/source_gen/template_compiler/generate.dart --update-goldens`
Future main(List<String> args) async {
  var parser = new ArgParser()..addFlag(updateGoldens, defaultsTo: false);
  var results = parser.parse(args);
  var extension = results[updateGoldens] ? '.golden' : '.dart';
  var inputs =
      new InputSet('angular2', ['$testFiles/*.dart', '$testFiles/**/*.dart']);
  var phaseGroup = new PhaseGroup()
    ..addPhase(new Phase()
      ..addAction(
          new GeneratorBuilder([new TestComponentExtractor()],
              generatedExtension: '.ng_component$extension',
              isStandalone: true),
          inputs));
  await build(phaseGroup, deleteFilesByDefault: results[updateGoldens]);
}
