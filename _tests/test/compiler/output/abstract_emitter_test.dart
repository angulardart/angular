@TestOn('vm')
import 'package:test/test.dart';
import 'package:angular/src/compiler/output/abstract_emitter.dart'
    show escapeSingleQuoteString;

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
