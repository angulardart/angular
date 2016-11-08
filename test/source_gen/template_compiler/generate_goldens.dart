import 'package:angular2/src/source_gen/template_compiler/testing/component_extractor_generator.dart';
import 'package:angular2/src/source_gen/template_compiler/testing/injectable_module_extractor_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';

main() async {
  var inputs =
      new InputSet('angular2', ['$testFiles/*.dart', '$testFiles/**/*.dart']);
  var phaseGroup = new PhaseGroup()
    ..addPhase(new Phase()
      ..addAction(
          new GeneratorBuilder([new TestComponentExtractor()],
              generatedExtension: '.ng_component.golden', isStandalone: true),
          inputs)
      ..addAction(
          new GeneratorBuilder([new TestInjectableExtractor()],
              generatedExtension: '.ng_injectable.golden', isStandalone: true),
          inputs));

  await build(phaseGroup);
}
