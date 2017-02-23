import 'package:angular2/src/source_gen/template_compiler/testing/component_extractor_generator.dart';
import 'package:build/build.dart';

const testFiles = 'test/source_gen/template_compiler/test_files';
const _extension = '.ng_summary.json';

Builder testComponentExtractor() => const TestComponentExtractor(_extension);
