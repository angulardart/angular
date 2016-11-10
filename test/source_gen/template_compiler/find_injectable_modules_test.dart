@Skip("TODO extra build step")
import 'dart:async';
import 'package:test/test.dart';
import 'compare_to_golden.dart' as golden;

const String summaryExtension = '.ng_injectable';
const String goldenExtension = '.ng_injectable.golden';

main() {
  group('Test Injectable Modules', () {
    test('test_foo', () async {
      await compareSummaryFileToGolden(
          'injectable_module/injectable_module.dart');
    });
  });
}

Future compareSummaryFileToGolden(String dartFile) =>
    golden.compareSummaryFileToGolden(dartFile,
        summaryExtension: summaryExtension, goldenExtension: goldenExtension);
