@TestOn('vm')
@Tags(const ['failing_i302'])
import 'dart:async';

import 'package:test/test.dart';

import 'compare_to_golden.dart' as golden;

String summaryExtension(String codegenMode) => '.template_$codegenMode.dart';
String goldenExtension(String codegenMode) => '.template_$codegenMode.golden';

/// To update the golden files, in the root angular2 directory, run
/// `pub get` and then
/// `dart test/source_gen/template_compiler/generate.dart --update-goldens`
main() {
  for (String codegenMode in ['release', 'debug']) {
    group('Test Components in $codegenMode', () {
      test('test_foo', () async {
        await compareSummaryFileToGolden('test_foo.dart', codegenMode);
      });

      test('has_directives', () async {
        await compareSummaryFileToGolden('has_directives.dart', codegenMode);
      });

      test('core_directives', () async {
        await compareSummaryFileToGolden('core_directives.dart', codegenMode);
      });

      test('change_detection', () async {
        await compareSummaryFileToGolden('change_detection.dart', codegenMode);
      });

      test('view_annotation', () async {
        await compareSummaryFileToGolden('view_annotation.dart', codegenMode);
      });

      test('view_encapsulation', () async {
        await compareSummaryFileToGolden(
            'view_encapsulation.dart', codegenMode);
      });

      test('export_as', () async {
        await compareSummaryFileToGolden('export_as.dart', codegenMode);
      });

      test('injectables', () async {
        await compareSummaryFileToGolden('injectables.dart', codegenMode);
      });

      test('providers', () async {
        await compareSummaryFileToGolden('providers.dart', codegenMode);
      });

      test('directives/base_component', () async {
        await compareSummaryFileToGolden(
            'directives/base_component.dart', codegenMode);
      });

      test('directives/directives', () async {
        await compareSummaryFileToGolden(
            'directives/directives.dart', codegenMode);
      });

      test('has_template_file', () async {
        await compareSummaryFileToGolden(
            'templates/has_template_file.dart', codegenMode);
      });
    });
  }
}

Future compareSummaryFileToGolden(String dartFile, String codegenMode) =>
    golden.compareSummaryFileToGolden(dartFile,
        summaryExtension: summaryExtension(codegenMode),
        goldenExtension: goldenExtension(codegenMode));
