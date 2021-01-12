// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should ignore on unrecognized import URLs', () async {
    await compilesNormally("""
      import 'dart:badpackage/bad.dart';
    """);
  });

  test('should ignore on unrecognized export URLs', () async {
    await compilesNormally("""
      export 'dart:badpackage/bad.dart';
    """);
  });

  test('should ignore on unrecognized part URLs', () async {
    await compilesNormally("""
      part 'dart:badpackage/bad.dart';
    """);
  });
}
