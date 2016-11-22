@TestOn('vm')
import 'dart:async';
import 'package:test/test.dart';
import 'compare_to_golden.dart' as golden;

const String summaryExtension = '.ng_component';
const String goldenExtension = '.ng_component.golden';

main() {
  group('Test Components', () {
    test('test_foo', () async {
      await compareSummaryFileToGolden('test_foo.dart');
    });

    test('has_directives', () async {
      await compareSummaryFileToGolden('has_directives.dart');
    });

    test('change_detection', () async {
      await compareSummaryFileToGolden('change_detection.dart');
    });

    test('view_encapuslation', () async {
      await compareSummaryFileToGolden('view_encapsulation.dart');
    });

    test('export_as', () async {
      await compareSummaryFileToGolden('export_as.dart');
    });

    test('directives', () async {
      await compareSummaryFileToGolden('directives/base_component.dart');
    });

    test('has_template_file', () async {
      await compareSummaryFileToGolden('templates/has_template_file.dart');
    });
  });
}

Future compareSummaryFileToGolden(String dartFile) =>
    golden.compareSummaryFileToGolden(dartFile,
        summaryExtension: summaryExtension, goldenExtension: goldenExtension);
