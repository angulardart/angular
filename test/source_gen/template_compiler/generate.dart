import 'dart:async';
import 'package:angular2/src/source_gen/template_compiler/generator.dart';
import 'package:angular2/src/source_gen/template_compiler/testing/component_extractor_generator.dart';
import 'package:args/args.dart';
import 'package:build_runner/build_runner.dart';
import 'package:source_gen/source_gen.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';

const _updateGoldens = 'update-goldens';

/// This script runs the source_gen test generators. This is requried before the
/// tests can run, since they check the output of these generators against
/// golden files.
///
/// To update the golden files, in the root angular2 directory, run
/// `pub get` and then
/// `dart test/source_gen/template_compiler/generate.dart --update-goldens`
Future main(List<String> args) async {
  var parser = new ArgParser()..addFlag(_updateGoldens, defaultsTo: false);
  var results = parser.parse(args);
  var updateGoldens = results[_updateGoldens];
  var inputs =
      new InputSet('angular2', ['$testFiles/*.dart', '$testFiles/**/*.dart']);
  var phaseGroup = new PhaseGroup()
    ..addPhase(new Phase()
      ..addAction(
          new GeneratorBuilder([new TestComponentExtractor()],
              generatedExtension:
                  updateGoldens ? '.ng_component.golden' : '.ng_component',
              isStandalone: true),
          inputs)
      ..addAction(
          new GeneratorBuilder([new TemplateGenerator()],
              generatedExtension:
                  updateGoldens ? '.template.golden' : '.template.dart',
              isStandalone: true),
          inputs));
  await build(phaseGroup, deleteFilesByDefault: updateGoldens);
}
