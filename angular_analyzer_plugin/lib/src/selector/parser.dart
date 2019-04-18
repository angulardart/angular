import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_contains_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_starts_with_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/attribute_value_regex_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/class_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/contains_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/name.dart';
import 'package:angular_analyzer_plugin/src/selector/not_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/or_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/parse_error.dart';
import 'package:angular_analyzer_plugin/src/selector/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/tokenizer.dart';

/// A parser for CSS [Selector]s.
class SelectorParser with ReportParseErrors {
  Tokenizer tokenizer;
  int lastOffset = 0;
  final int fileOffset;
  @override
  final String str;
  final Source source;
  SelectorParser(this.source, this.fileOffset, this.str)
      : tokenizer = Tokenizer(str, fileOffset);

  /// Try to parse a [Selector], throwing [SelectorParseError] on error.
  ///
  /// Also may return [null] if the provided string is null.
  Selector parse() {
    if (str == null) {
      return null;
    }
    final selector = _parseNested();

    // Report dangling end tokens
    if (tokenizer.current != null) {
      unexpected(tokenizer.current.lexeme, tokenizer.current.offset);
    }

    return selector
      ..originalString = str
      ..offset = fileOffset;
  }

  Selector _andSelectors(List<Selector> selectors) {
    if (selectors.length == 1) {
      return selectors.single;
    }
    return AndSelector(selectors);
  }

  Selector _parseAttributeSelector() {
    final nameOffset = tokenizer.current.offset + '['.length;
    final operator = tokenizer.currentOperator;
    final value = tokenizer.currentValue;

    if (operator != null && value.lexeme.isEmpty) {
      expected('a value after ${operator.lexeme}',
          actual: ']', offset: tokenizer.current.endOffset - 1);
    }

    final name = tokenizer.current.lexeme;
    tokenizer.advance();

    return _tryParseAttributeValueRegexSelector(
            name, nameOffset, operator?.lexeme, value) ??
        _tryParseAttributeContainsSelector(
            name, nameOffset, operator?.lexeme, value) ??
        _tryParseAttributeStartsWithSelector(
            name, nameOffset, operator?.lexeme, value) ??
        AttributeSelector(
            SelectorName(name, SourceRange(nameOffset, name.length), source),
            value?.lexeme);
  }

  ClassSelector _parseClassSelector() {
    final nameOffset = tokenizer.current.offset + 1;
    final name = tokenizer.current.lexeme;
    tokenizer.advance();
    return ClassSelector(
        SelectorName(name, SourceRange(nameOffset, name.length), source));
  }

  ContainsSelector _parseContainsSelector() {
    final containsString = tokenizer.currentContainsString.lexeme;
    tokenizer.advance();
    return ContainsSelector(containsString);
  }

  ElementNameSelector _parseElementNameSelector() {
    final nameOffset = tokenizer.current.offset;
    final name = tokenizer.current.lexeme;
    tokenizer.advance();
    return ElementNameSelector(
        SelectorName(name, SourceRange(nameOffset, name.length), source));
  }

  Selector _parseNested() {
    final selectors = <Selector>[];
    while (tokenizer.current != null) {
      if (tokenizer.current.type == TokenType.NotEnd) {
        // don't advance, just know we're at the end of this.
        break;
      }

      if (tokenizer.current.type == TokenType.Comma) {
        // [selectors] is the lhs of the OR. [_parseOrSelector] will parse the
        // rhs, so return its result without continuing the loop.
        return _parseOrSelector(selectors);
      } else if (tokenizer.current.type == TokenType.NotStart) {
        selectors.add(_parseNotSelector());
      } else if (tokenizer.current.type == TokenType.Tag) {
        selectors.add(_parseElementNameSelector());
      } else if (tokenizer.current.type == TokenType.Class) {
        selectors.add(_parseClassSelector());
      } else if (tokenizer.current.type == TokenType.Attribute) {
        selectors.add(_parseAttributeSelector());
      } else if (tokenizer.current.type == TokenType.Contains) {
        selectors.add(_parseContainsSelector());
      } else {
        break;
      }
    }

    // final result
    return _andSelectors(selectors);
  }

  NotSelector _parseNotSelector() {
    tokenizer.advance();
    final condition = _parseNested();
    if (tokenizer.current.type != TokenType.NotEnd) {
      unexpected(
          tokenizer.current.lexeme, tokenizer?.current?.offset ?? lastOffset);
    }
    tokenizer.advance();
    return NotSelector(condition);
  }

  OrSelector _parseOrSelector(List<Selector> selectors) {
    tokenizer.advance();
    final rhs = _parseNested();
    if (rhs is OrSelector) {
      // flatten "a, b, c, d" from (a, (b, (c, d))) into (a, b, c, d)
      return OrSelector(
          <Selector>[_andSelectors(selectors)]..addAll(rhs.selectors));
    }

    return OrSelector(<Selector>[_andSelectors(selectors), rhs]);
  }

  AttributeContainsSelector _tryParseAttributeContainsSelector(
      String originalName, int nameOffset, String operator, Token value) {
    if (operator == '*=') {
      final name = originalName.replaceAll('*', '');
      return AttributeContainsSelector(
          SelectorName(name, SourceRange(nameOffset, name.length), source),
          value.lexeme);
    }
    return null;
  }

  AttributeStartsWithSelector _tryParseAttributeStartsWithSelector(
      String name, int nameOffset, String operator, Token value) {
    if (operator == '^=') {
      return AttributeStartsWithSelector(
          SelectorName(name, SourceRange(nameOffset, name.length), source),
          value.lexeme);
    }
    return null;
  }

  AttributeValueRegexSelector _tryParseAttributeValueRegexSelector(
      String name, int nameOffset, String operator, Token value) {
    if (name == '*' &&
        value != null &&
        value.lexeme.startsWith('/') &&
        value.lexeme.endsWith('/')) {
      if (operator != '=') {
        unexpected(operator, nameOffset + name.length);
      }
      final valueOffset = nameOffset + name.length + '='.length;
      final regex = value.lexeme.substring(1, value.lexeme.length - 1);
      return AttributeValueRegexSelector(
          SelectorName(regex, SourceRange(valueOffset, regex.length), source));
    }
    return null;
  }
}
