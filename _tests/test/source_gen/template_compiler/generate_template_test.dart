@TestOn('vm')
@Tags(const ['failing_i302'])
import 'dart:async';

import 'package:test/test.dart';

import 'compare_to_golden.dart' as golden;

String summaryExtension(String codegenMode) => '.template_$codegenMode.check';
String goldenExtension(String codegenMode) => '.template_$codegenMode.golden';

/// To update the golden files, in the root angular2 directory, run
/// `pub get` and then
/// `dart test/source_gen/template_compiler/generate.dart --update-goldens`
main() {
  for (String codegenMode in ['release', 'debug']) {
    group('Test Components in $codegenMode', () {
      for (String file in [
        'change_detection',
        'core_directives',
        'events',
        'export_as',
        'has_directives',
        'host',
        'inherited_lifecycle_hooks',
        'injectables',
        'interpolation',
        'lifecycle_hooks',
        'opaque_token',
        'pipes',
        'provider_modules',
        'providers',
        'queries',
        'test_foo',
        'view_encapsulation',
        'deferred/container_component',
        'deferred/deferred_component',
        'directives/base_component',
        'directives/components',
        'directives/directives',
        'templates/has_template_file',
      ]) {
        test(file, () async {
          await compareSummaryFileToGolden('$file.dart', codegenMode);
        });
      }
    });
  }
}

Future compareSummaryFileToGolden(String dartFile, String codegenMode) =>
    golden.compareSummaryFileToGolden(dartFile,
        summaryExtension: summaryExtension(codegenMode),
        goldenExtension: goldenExtension(codegenMode));
