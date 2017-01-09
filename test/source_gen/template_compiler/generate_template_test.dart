@TestOn('vm')
import 'dart:async';
import 'package:test/test.dart';
import 'compare_to_golden.dart' as golden;

const String summaryExtension = '.template.dart';
const String goldenExtension = '.template.golden';

/// To update the golden files, in the root angular2 directory, run
/// `pub get` and then
/// `dart test/source_gen/template_compiler/generate.dart --update-goldens`
main() {
  group('Test Components', () {
    test('test_foo', () async {
      await compareSummaryFileToGolden('test_foo.dart');
    });

    test('has_directives', () async {
      await compareSummaryFileToGolden('has_directives.dart');
    });

    test('core_directives', () async {
      await compareSummaryFileToGolden('core_directives.dart');
    });

    test('change_detection', () async {
      await compareSummaryFileToGolden('change_detection.dart');
    });

    test('view_annotation', () async {
      await compareSummaryFileToGolden('view_annotation.dart');
    });

    test('view_encapuslation', () async {
      await compareSummaryFileToGolden('view_encapsulation.dart');
    });

    test('export_as', () async {
      await compareSummaryFileToGolden('export_as.dart');
    });

    test('injectables', () async {
      await compareSummaryFileToGolden('injectables.dart');
    });

    test('directives/base_component', () async {
      await compareSummaryFileToGolden('directives/base_component.dart');
    });

    test('directives/directives', () async {
      await compareSummaryFileToGolden('directives/directives.dart');
    });

    test('has_template_file', () async {
      await compareSummaryFileToGolden('templates/has_template_file.dart');
    });
  });
}

Future compareSummaryFileToGolden(String dartFile) =>
    golden.compareSummaryFileToGolden(dartFile,
        summaryExtension: summaryExtension, goldenExtension: goldenExtension);
