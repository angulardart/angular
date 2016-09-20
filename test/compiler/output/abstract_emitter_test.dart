library angular2.test.compiler.output.abstract_emitter_test;

import "package:angular2/src/compiler/output/abstract_emitter.dart"
    show escapeSingleQuoteString;
import "package:test/test.dart";

void main() {
  group("AbstractEmitter", () {
    group("escapeSingleQuoteString", () {
      test("should escape single quotes", () {
        expect(escapeSingleQuoteString("'", false), "\'\\\'\'");
      });
      test("should escape backslash", () {
        expect(escapeSingleQuoteString("\\", false), "\'\\\\\'");
      });
      test("should escape newlines", () {
        expect(escapeSingleQuoteString("\n", false), "\'\\n\'");
      });
      test("should escape carriage returns", () {
        expect(escapeSingleQuoteString("\r", false), "\'\\r\'");
      });
      test("should escape \$", () {
        expect(escapeSingleQuoteString("\$", true), "'\\\$'");
      });
      test("should not escape \$", () {
        expect(escapeSingleQuoteString("\$", false), "'\$'");
      });
    });
  });
}
