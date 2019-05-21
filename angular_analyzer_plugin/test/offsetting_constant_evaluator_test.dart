import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' as utils;
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/source/source_resource.dart' show FileSource;
import 'package:angular_analyzer_plugin/src/offsetting_constant_evaluator.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(OffsettingConstantValueVisitorTest);
  });
}

@reflectiveTest
class OffsettingConstantValueVisitorTest {
  // ignore: non_constant_identifier_names
  void assertCaretOffsetIsPreserved(String code) {
    final pos = code.indexOf('^');
    expect(pos, greaterThan(-1), reason: 'the code should contain a caret');

    final expression = _parseDartExpression(code);

    final evaluator = OffsettingConstantEvaluator();
    final value = expression.accept(evaluator);

    if (value is String) {
      expect(value.indexOf('^'), equals(pos),
          reason: "```$value``` moved the caret");
    } else {
      fail("Expected string, got $value");
    }
  }

  // ignore: non_constant_identifier_names
  void assertNotOffsettable(String code, {String at}) {
    final expression = _parseDartExpression(code);
    final pos = code.indexOf(at);
    final length = at.length;
    expect(pos, greaterThan(-1),
        reason: "```$code```` doesn't contain ```$at```");

    final evaluator = OffsettingConstantEvaluator();
    expression.accept(evaluator);
    expect(evaluator.offsetsAreValid, isFalse);
    expect(evaluator.lastUnoffsettableNode, isNotNull);
    expect(evaluator.lastUnoffsettableNode.offset, equals(pos),
        reason: "The snippet didn't match the suspect node");
    expect(evaluator.lastUnoffsettableNode.length, equals(length),
        reason: "The snippet didn't match the suspect node");
  }

  // ignore: non_constant_identifier_names
  void test_adjacentStrings() {
    assertCaretOffsetIsPreserved("'my template^' 'which continues'");
    assertCaretOffsetIsPreserved("'my template' 'which continues ^'");
    assertCaretOffsetIsPreserved("r'my template'    r'which continues ^'");
    assertCaretOffsetIsPreserved("'my template'\n       'which continues ^'");
    assertCaretOffsetIsPreserved("'no gap''then continue ^'");
    assertCaretOffsetIsPreserved("'' 'after empty string ^'");
    assertCaretOffsetIsPreserved(
        "'my template'\n\n       'which continues' ' and continues ^'");
  }

  // ignore: non_constant_identifier_names
  void test_computedStringsLookRight() {
    final expression =
        _parseDartExpression("('my template'\n) + 'which continues^'");
    final value = expression.accept(OffsettingConstantEvaluator());
    expect(value, equals("  my template       which continues^ "));
  }

  // ignore: non_constant_identifier_names
  void test_concatenatedAfterParenthesis() {
    assertCaretOffsetIsPreserved("('my template^') + 'which continues'");
    assertCaretOffsetIsPreserved("('my template') + 'which continues^'");
    assertCaretOffsetIsPreserved("('my template'  ) + 'which continues^'");
    assertCaretOffsetIsPreserved("('my template'\n) + 'which continues^'");
  }

  // ignore: non_constant_identifier_names
  void test_concatenatedStrings() {
    assertCaretOffsetIsPreserved("'my template^' + 'which continues'");
    assertCaretOffsetIsPreserved("'my template' + 'which continues ^'");
    assertCaretOffsetIsPreserved("r'my template' +    r'which continues ^'");
    assertCaretOffsetIsPreserved("'my template' +\n       'which continues ^'");
    assertCaretOffsetIsPreserved("'no gap'+'then continue ^'");
    assertCaretOffsetIsPreserved("'' + 'after empty string ^'");
    assertCaretOffsetIsPreserved(
        "'my template' +\n\n       'which continues' + ' and continues ^'");
  }

  // ignore: non_constant_identifier_names
  void test_error() {
    final expression = _parseDartExpression("1 + 'hello'");
    final value = expression.accept(OffsettingConstantEvaluator());
    expect(value, equals(utils.ConstantEvaluator.NOT_A_CONSTANT));
  }

  // ignore: non_constant_identifier_names
  void test_notOffsettableGetter() {
    assertNotOffsettable(r"'hello' + world ", at: 'world');
  }

  // ignore: non_constant_identifier_names
  void test_notOffsettableInterp() {
    assertNotOffsettable(r"'hello $world'", at: 'world');
  }

  // ignore: non_constant_identifier_names
  void test_notOffsettableInterpExpr() {
    assertNotOffsettable(r"'hello ${world}'", at: 'world');
  }

  // ignore: non_constant_identifier_names
  void test_notOffsettableMethod() {
    assertNotOffsettable(r"'hello' + method() ", at: 'method()');
  }

  // ignore: non_constant_identifier_names
  void test_notOffsettablePrefixedIdent() {
    assertNotOffsettable(r"'hello' + prefixed.identifier ",
        at: 'prefixed.identifier');
  }

  // ignore: non_constant_identifier_names
  void test_notStringComputation() {
    final expression = _parseDartExpression("1 + 2");
    final value = expression.accept(OffsettingConstantEvaluator());
    expect(value, equals(3));
  }

  // ignore: non_constant_identifier_names
  void test_parenthesizedString() {
    assertCaretOffsetIsPreserved("('my template^')");
    assertCaretOffsetIsPreserved("( 'my template^')");
    assertCaretOffsetIsPreserved("(  'my template^')");
    assertCaretOffsetIsPreserved("(\n'my template^')");
  }

  // ignore: non_constant_identifier_names
  void test_simpleString() {
    assertCaretOffsetIsPreserved("'my template^'");
    assertCaretOffsetIsPreserved("r'my template^'");
    assertCaretOffsetIsPreserved('"my template^"');
    assertCaretOffsetIsPreserved('r"my template^"');
    assertCaretOffsetIsPreserved("'''my template^'''");
    assertCaretOffsetIsPreserved("r'''my template^'''");
  }

  Expression _parseDartExpression(String code) {
    final featureSet = FeatureSet.forTesting();
    final token = _scanDartCode(code);
    final parser =
        Parser(_MockSource(), BooleanErrorListener(), featureSet: featureSet);
    return parser.parseExpression(token);
  }

  Token _scanDartCode(String code) {
    final reader = CharSequenceReader(code);
    final scanner = Scanner(null, reader, null);
    return scanner.tokenize();
  }
}

class _MockSource extends Mock implements FileSource {}
