part of 'exception_handler.dart';

@sealed
class ParserErrorCode {
  static const CANNOT_FIND_MATCHING_CLOSE = ParserErrorCode._(
    'CANNOT_FIND_MATCHING_CLOSE',
    'Cannot find matching close element to this',
  );

  static const DANGLING_CLOSE_ELEMENT = ParserErrorCode._(
    'DANGLING_CLOSE_ELEMENT',
    'Closing tag is dangling and no matching open tag can be found',
  );

  static const DUPLICATE_STAR_DIRECTIVE = ParserErrorCode._(
    'DUPLICATE_STAR_DIRECTIVE',
    'Already found a *-directive, limit 1 per element.',
  );

  static const DUPLICATE_SELECT_DECORATOR = ParserErrorCode._(
    'DUPLICATE_SELECT_DECORATOR',
    "Only 1 'select' decorator can exist in <ng-content>, found duplicate",
  );

  static const DUPLICATE_PROJECT_AS_DECORATOR = ParserErrorCode._(
    'DUPLICATE_PROJECT_AS_DECORATOR',
    "Only 1 'ngProjectAs' decorator can exist in <ng-content>, found duplicate",
  );

  static const DUPLICATE_REFERENCE_DECORATOR = ParserErrorCode._(
    'DUPLICATE_REFERENCE_DECORATOR',
    'Only 1 reference decorator can exist in <ng-content>, found duplicate',
  );

  static const ELEMENT_DECORATOR = ParserErrorCode._(
    'ELEMENT_DECORATOR',
    'Expected element decorator after whitespace',
  );

  static const ELEMENT_DECORATOR_AFTER_PREFIX = ParserErrorCode._(
    'ELEMENT_DECORATOR_AFTER_PREFIX',
    'Expected element decorator identifier after prefix',
  );

  static const ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX = ParserErrorCode._(
    'ELEMENT_DECORATOR',
    'Found special decorator suffix before prefix',
  );

  static const ELEMENT_DECORATOR_VALUE = ParserErrorCode._(
    'ELEMENT_DECORATOR_VALUE',
    "Expected quoted value following '='",
  );

  static const ELEMENT_DECORATOR_VALUE_MISSING_QUOTES = ParserErrorCode._(
    'ELEMENT_DECORATOR_VALUE_MISSING_QUOTES',
    'Decorator values must contain quotes',
  );

  static const ELEMENT_IDENTIFIER = ParserErrorCode._(
    'ELEMENT_IDENTIFIER',
    'Expected element tag name',
  );

  static const EXPECTED_AFTER_ELEMENT_IDENTIFIER = ParserErrorCode._(
    'EXPECTED_AFTER_ELEMENT_IDENTIFIER',
    'Expected either whitespace or close tag end after element identifier',
  );

  static const EXPECTED_EQUAL_SIGN = ParserErrorCode._(
    'EXPECTED_EQUAL_SIGN',
    "Expected '=' between decorator and value",
  );

  static const EXPECTED_STANDALONE = ParserErrorCode._(
    'EXPECTING_STANDALONE',
    'Expected standalone token',
  );

  static const EXPECTED_TAG_CLOSE = ParserErrorCode._(
    'EXPECTED_TAG_CLOSE',
    'Expected tag close.',
  );

  // 'Catch-all' error code.
  static const UNEXPECTED_TOKEN = ParserErrorCode._(
    'UNEXPECTED_TOKEN',
    'Unexpected token',
  );

  static const EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR = ParserErrorCode._(
    'EXPECTED_WHITESPACE_BEFORE_DECORATOR',
    'Expected whitespace before a new decorator',
  );

  static const EMPTY_INTERPOLATION = ParserErrorCode._(
    'EMPTY_INTERPOLATION',
    'Interpolation expression cannot be empty',
  );

  static const INVALID_DECORATOR_IN_NGCONTAINER = ParserErrorCode._(
    'INVALID_DECORATOR_IN_NGCONTAINER',
    "Only '*' bindings are supported on <ng-container>",
  );

  static const INVALID_DECORATOR_IN_NGCONTENT = ParserErrorCode._(
    'INVALID_DECORATOR_IN_NGCONTENT',
    "Only 'select' is a valid attribute/decorate in <ng-content>",
  );

  static const INVALID_DECORATOR_IN_TEMPLATE = ParserErrorCode._(
    'INVALID_DECORATOR_IN_TEMPLATE',
    "Invalid decorator in 'template' element",
  );

  static const INVALID_LET_BINDING_IN_NONTEMPLATE = ParserErrorCode._(
    'INVALID_LET_BINDING_IN_NONTEMPLATE',
    "'let-' binding can only be used in 'template' element",
  );

  static const INVALID_MICRO_EXPRESSION = ParserErrorCode._(
    'INVALID_MICRO_EXPRESSION',
    'Failed parsing micro expression',
  );

  static const NONVOID_ELEMENT_USING_VOID_END = ParserErrorCode._(
    'NONVOID_ELEMENT_USING_VOID_END',
    'Element is not a void-element',
  );

  static const NGCONTENT_MUST_CLOSE_IMMEDIATELY = ParserErrorCode._(
    'NGCONTENT_MUST_CLOSE_IMMEDIATElY',
    "'<ng-content ...>' must be followed immediately by close '</ng-content>'",
  );

  static const PROPERTY_NAME_TOO_MANY_FIXES = ParserErrorCode._(
    'PROPERTY_NAME_TOO_MANY_FIXES',
    "Property name can only be in format: 'name[.postfix[.unit]]",
  );

  static const REFERENCE_IDENTIFIER_FOUND = ParserErrorCode._(
    'REFERENCE_IDENTIFIER_FOUND',
    'Reference decorator only supports #<variable> on <ng-content>',
  );

  static const SUFFIX_BANANA = ParserErrorCode._(
    'SUFFIX_BANANA',
    "Expected closing banana ')]'",
  );

  static const SUFFIX_EVENT = ParserErrorCode._(
    'SUFFIX_EVENT',
    "Expected closing parenthesis ')'",
  );

  static const SUFFIX_PROPERTY = ParserErrorCode._(
    'SUFFIX_PROPERTY',
    "Expected closing bracket ']'",
  );

  static const UNCLOSED_QUOTE = ParserErrorCode._(
    'UNCLOSED_QUOTE',
    'Expected close quote for element decorator value',
  );

  static const UNOPENED_MUSTACHE = ParserErrorCode._(
    'UNOPENED_MUSTACHE',
    'Unopened mustache',
  );

  static const UNTERMINATED_COMMENT = ParserErrorCode._(
    'UNTERMINATED COMMENT',
    'Unterminated comment',
  );

  static const UNTERMINATED_MUSTACHE = ParserErrorCode._(
    'UNTERMINATED_MUSTACHE',
    'Unterminated mustache',
  );

  static const VOID_ELEMENT_IN_CLOSE_TAG = ParserErrorCode._(
    'VOID_ELEMENT_IN_CLOSE_TAG',
    'Void element identifiers cannot be used in close element tag',
  );

  static const VOID_CLOSE_IN_CLOSE_TAG = ParserErrorCode._(
    'VOID_CLOSE_IN_CLOSE_TAG',
    "Void close '/>' cannot be used in a close element",
  );

  final String name;

  final String message;

  /// Initialize a newly created erorr code to have the given [name].
  /// The message associated with the error will be created from the
  /// given [message] template. The correction associated with the error
  /// will be created from the given [correction] template.
  const ParserErrorCode._(
    this.name,
    this.message,
  );
}
