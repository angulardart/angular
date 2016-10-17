@TestOn('vm')
library angular2.test.transform.common.options_reader_test;

import 'dart:io';

import 'package:test/test.dart';

void main() {
  group("options_reader", () {
    test("parseBarbackSettings reports invalid entry_points", () {
      var processResult = Process.runSync('dart', [
        './test/transform/common/print_invalid_entry_points.dart',
      ]);
      var stdErrOutput = processResult.stderr;
      expect(stdErrOutput, contains('- non_existing1'));
      expect(stdErrOutput, contains('- non_existing2/with_sub_directory'));
      expect(stdErrOutput, isNot(contains('print_invalid_entry_points')));
    });
  });
}
