/// Magical regex-based values for tokenizing CSS selectors.
///
/// Dependence on regex is not necessarily a good thing but this file intends to
/// do regex in the "best" way possible.
///
/// The intention of this file is to keep all magical values in one place,
/// reducing risk of them being changed in ways that subtly break their
/// inter-dependence.
///
/// The tokenizer is one regex which is assembled in const strings such as
/// [_attribute], [_attributeQuotedValue], etc. Breaking it up reduces density
/// and enables commenting.
///
/// The groups produced by the regex indicate the token type and/or potentially
/// include subgroups for correlated lexemes, such as attributes which have both
/// a name and a value. Most match IDs correspond to a [TokenType], and the ones
/// that don't are subgroups. Those group IDs are stored in the "subToken" IDs
/// such as [subTokenUnquotedValue] and [subTokenOperator].
import 'package:angular_analyzer_plugin/src/selector/tokenizer.dart';

const Map<int, TokenType> matchIndexToToken = <int, TokenType>{
  1: TokenType.NotStart,
  2: TokenType.Tag,
  3: TokenType.Class,
  4: TokenType.Attribute, // no quotes
  // 5 is part of Attribute. Not a match type. See [subTokenOperator].
  // 6 is part of Attribute. Not a match type. See [subTokenUnquotedValue].
  // 7 is part of Attribute. Not a match type. See [subTokenSingleQuotedValue].
  // 8 is part of Attribute. Not a match type. See [subTokenDoubleQuotedValue].
  9: TokenType.NotEnd,
  10: TokenType.Comma,
  11: TokenType.Contains,
  // 12 is a part of Contains. Not a match type. See [subTokenContainsStr].
};

const subTokenContainsStr = 12;
const subTokenDoubleQuotedValue = 8;
const subTokenOperator = 5;
const subTokenSingleQuotedValue = 7;
const subTokenUnquotedValue = 6;

const _attribute = // comment here for formatting:
    r'\[' // begins with '['
    '($_attributeName)' // capture the attribute name
    '(?:$_attributeEqualsValue)?' // non-capturing optional value
    r'\]' // ends with ']'
    ;

const _attributeEqualsValue =
    // capture which type of '=' operator as [subTokenOperator].
    r'(\^=|\*=|=)'
    // include values. Don't capture here, they contain captures themselves.
    '(?:$_attributeNoQuoteValue|$_attributeQuotedValue)';

const _attributeName =
    r'[-\w]+|\*' // chars with dash, may end with or be just '*'.
    ;

const _attributeNoQuoteValue =
    // Capture anything but ']' or a quote as [subTokenUnquotedValue].
    r'''([^\]'"]*)''';

const _attributeQuotedValue =
    // Capture a single quoted string with contents [subTokenSingleQuotedValue].
    r"'([^\]']*)'"
    r'|' // or
    // Capture a double quoted string with contents [subTokenDoubleQuotedValue].
    r'"([^\]"]*)"' // Capture the contents of a double quoted string
    ;

/// The regex that ultimately tokenizes css.
///
/// Note: This must be carefully matched to [matchIndexToToken].
final RegExp tokenizer = RegExp(r'(\:not\()|'
    r'([-\w]+)|' // Tag
    r'(?:\.([-\w]+))|' // Class
    '(?:$_attribute)|' // Attribute, in a non-capturing group.
    r'(\))|' // Not-end
    r'(\s*,\s*)|' // Comma
    r'(^\:contains\(\/(.+)\/\)$)'); // Contains
