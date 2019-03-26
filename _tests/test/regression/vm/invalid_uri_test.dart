@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
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
