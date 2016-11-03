import 'package:angular2/src/source_gen/template_compiler/testing/component_extractor_generator.dart';
import 'package:source_gen/source_gen.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';

GeneratorBuilder testComponentExtractor({String extension: '.ng_summary'}) =>
    new GeneratorBuilder([new TestComponentExtractor()],
        generatedExtension: extension, isStandalone: true);
