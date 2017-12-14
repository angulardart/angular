// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of angular_ast.src.exceptions;

/// Error codes used for exceptions that occur during the parsing.
/// The convention for this class is for the name of the error code
/// to indicate the problem that caused the error code to be generated
/// and for the error message to explain what is wrong, and when appropriate,
/// how the problem can be corrected.
///
const List<NgParserWarningCode> angularAstWarningCodes = const [
  NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE,
  NgParserWarningCode.DANGLING_CLOSE_ELEMENT,
  NgParserWarningCode.DUPLICATE_STAR_DIRECTIVE,
  NgParserWarningCode.DUPLICATE_SELECT_DECORATOR,
  NgParserWarningCode.ELEMENT_DECORATOR,
  NgParserWarningCode.ELEMENT_DECORATOR_AFTER_PREFIX,
  NgParserWarningCode.ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX,
  NgParserWarningCode.ELEMENT_DECORATOR_VALUE,
  NgParserWarningCode.ELEMENT_DECORATOR_VALUE_MISSING_QUOTES,
  NgParserWarningCode.ELEMENT_IDENTIFIER,
  NgParserWarningCode.EXPECTED_AFTER_ELEMENT_IDENTIFIER,
  NgParserWarningCode.EXPECTED_EQUAL_SIGN,
  NgParserWarningCode.EXPECTED_STANDALONE,
  NgParserWarningCode.EXPECTED_TAG_CLOSE,
  NgParserWarningCode.UNEXPECTED_TOKEN,
  NgParserWarningCode.EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR,
  NgParserWarningCode.EMPTY_INTERPOLATION,
  NgParserWarningCode.EVENT_NAME_TOO_MANY_FIXES,
  NgParserWarningCode.INVALID_DECORATOR_IN_NGCONTENT,
  NgParserWarningCode.INVALID_DECORATOR_IN_TEMPLATE,
  NgParserWarningCode.INVALID_LET_BINDING_IN_NONTEMPLATE,
  NgParserWarningCode.INVALID_MICRO_EXPRESSION,
  NgParserWarningCode.NONVOID_ELEMENT_USING_VOID_END,
  NgParserWarningCode.NGCONTENT_MUST_CLOSE_IMMEDIATELY,
  NgParserWarningCode.PIPE_INVALID_IDENTIFIER,
  NgParserWarningCode.PROPERTY_NAME_TOO_MANY_FIXES,
  NgParserWarningCode.SUFFIX_BANANA,
  NgParserWarningCode.SUFFIX_EVENT,
  NgParserWarningCode.SUFFIX_PROPERTY,
  NgParserWarningCode.UNCLOSED_QUOTE,
  NgParserWarningCode.UNOPENED_MUSTACHE,
  NgParserWarningCode.UNTERMINATED_COMMENT,
  NgParserWarningCode.UNTERMINATED_MUSTACHE,
  NgParserWarningCode.VOID_ELEMENT_IN_CLOSE_TAG,
  NgParserWarningCode.VOID_CLOSE_IN_CLOSE_TAG,
  NgParserWarningCode.WRONG_VISITOR,
];

class NgParserWarningCode extends ErrorCode {
  static const NgParserWarningCode CANNOT_FIND_MATCHING_CLOSE =
      const NgParserWarningCode(
    'CANNOT_FIND_MATCHING_CLOSE',
    'Cannot find matching close element to this',
  );

  static const NgParserWarningCode DANGLING_CLOSE_ELEMENT =
      const NgParserWarningCode(
    'DANGLING_CLOSE_ELEMENT',
    'Closing tag is dangling and no matching open tag can be found',
  );

  static const NgParserWarningCode DANGLING_DECORATOR_SUFFIX =
      const NgParserWarningCode('DANGING_DECORATOR_SUFFIX',
          'Decorator suffix needs a matching prefix');

  static const NgParserWarningCode DUPLICATE_STAR_DIRECTIVE =
      const NgParserWarningCode(
    'DUPLICATE_STAR_DIRECTIVE',
    'Already found a *-directive, limit 1 per element.',
  );

  static const NgParserWarningCode DUPLICATE_SELECT_DECORATOR =
      const NgParserWarningCode(
    'DUPLICATE_SELECT_DECORATOR',
    "Only 1 'select' decorator can exist in <ng-content>, found duplicate",
  );

  static const NgParserWarningCode DUPLICATE_PROJECT_AS_DECORATOR =
      const NgParserWarningCode(
    'DUPLICATE_PROJECT_AS_DECORATOR',
    "Only 1 'ngProjectAs' decorator can exist in <ng-content>, found duplicate",
  );

  static const NgParserWarningCode ELEMENT_DECORATOR =
      const NgParserWarningCode(
    'ELEMENT_DECORATOR',
    'Expected element decorator after whitespace',
  );

  static const NgParserWarningCode ELEMENT_DECORATOR_AFTER_PREFIX =
      const NgParserWarningCode(
    'ELEMENT_DECORATOR_AFTER_PREFIX',
    'Expected element decorator identifier after prefix',
  );

  static const NgParserWarningCode ELEMENT_DECORATOR_SUFFIX_BEFORE_PREFIX =
      const NgParserWarningCode(
    'ELEMENT_DECORATOR',
    'Found special decorator suffix before prefix',
  );

  static const NgParserWarningCode ELEMENT_DECORATOR_VALUE =
      const NgParserWarningCode(
    'ELEMENT_DECORATOR_VALUE',
    "Expected quoted value following '='",
  );

  static const NgParserWarningCode ELEMENT_DECORATOR_VALUE_MISSING_QUOTES =
      const NgParserWarningCode(
    'ELEMENT_DECORATOR_VALUE_MISSING_QUOTES',
    'Decorator values must contain quotes',
  );

  static const NgParserWarningCode ELEMENT_IDENTIFIER =
      const NgParserWarningCode(
    'ELEMENT_IDENTIFIER',
    'Expected element tag name',
  );

  static const NgParserWarningCode EXPECTED_AFTER_ELEMENT_IDENTIFIER =
      const NgParserWarningCode(
    'EXPECTED_AFTER_ELEMENT_IDENTIFIER',
    'Expected either whitespace or close tag end after element identifier',
  );

  static const NgParserWarningCode EXPECTED_EQUAL_SIGN =
      const NgParserWarningCode(
    'EXPECTED_EQUAL_SIGN',
    "Expected '=' between decorator and value",
  );

  static const NgParserWarningCode EXPECTED_STANDALONE =
      const NgParserWarningCode(
    'EXPECTING_STANDALONE',
    'Expected standalone token',
  );

  static const NgParserWarningCode EXPECTED_TAG_CLOSE =
      const NgParserWarningCode(
    'EXPECTED_TAG_CLOSE',
    "Expected tag close.",
  );

  // 'Catch-all' error code.
  static const NgParserWarningCode UNEXPECTED_TOKEN = const NgParserWarningCode(
    'UNEXPECTED_TOKEN',
    'Unexpected token',
  );

  static const NgParserWarningCode EXPECTED_WHITESPACE_BEFORE_NEW_DECORATOR =
      const NgParserWarningCode(
    'EXPECTED_WHITESPACE_BEFORE_DECORATOR',
    'Expected whitespace before a new decorator',
  );

  static const NgParserWarningCode EMPTY_INTERPOLATION =
      const NgParserWarningCode(
    'EMPTY_INTERPOLATION',
    'Interpolation expression cannot be empty',
  );

  static const NgParserWarningCode EVENT_NAME_TOO_MANY_FIXES =
      const NgParserWarningCode(
    'EVENT_NAME_TOO_MANY_FIXES',
    "Event name can only be in format: 'name[.postfix]",
  );

  static const NgParserWarningCode INVALID_DECORATOR_IN_NGCONTENT =
      const NgParserWarningCode(
    'INVALID_DECORATOR_IN_NGCONTENT',
    "Only 'select' is a valid attribute/decorate in <ng-content>",
  );

  static const NgParserWarningCode INVALID_DECORATOR_IN_TEMPLATE =
      const NgParserWarningCode('INVALID_DECORATOR_IN_TEMPLATE',
          "Invalid decorator in 'template' element");

  static const NgParserWarningCode INVALID_LET_BINDING_IN_NONTEMPLATE =
      const NgParserWarningCode('INVALID_LET_BINDING_IN_NONTEMPLATE',
          "'let-' binding can only be used in 'template' element");

  // TODO: Max: Split this error into more smaller, detailed messages.
  static const NgParserWarningCode INVALID_MICRO_EXPRESSION =
      const NgParserWarningCode(
    'INVALID_MICRO_EXPRESSION',
    'Failed parsing micro expression',
  );

  static const NgParserWarningCode NONVOID_ELEMENT_USING_VOID_END =
      const NgParserWarningCode(
          'NONVOID_ELEMENT_USING_VOID_END', 'Element is not a void-element');

  static const NgParserWarningCode NGCONTENT_MUST_CLOSE_IMMEDIATELY =
      const NgParserWarningCode('NGCONTENT_MUST_CLOSE_IMMEDIATElY',
          "'<ng-content ...>' must be followed immediately by close '</ng-content>'");

  static const NgParserWarningCode PIPE_INVALID_IDENTIFIER =
      const NgParserWarningCode(
    'PIPE_INVALID_IDENTIFIER',
    'Pipe must be a valid identifier',
  );

  static const NgParserWarningCode PROPERTY_NAME_TOO_MANY_FIXES =
      const NgParserWarningCode(
    'PROPERTY_NAME_TOO_MANY_FIXES',
    "Property name can only be in format: 'name[.postfix[.unit]]",
  );

  static const NgParserWarningCode SUFFIX_BANANA = const NgParserWarningCode(
    'SUFFIX_BANANA',
    "Expected closing banana ')]'",
  );

  static const NgParserWarningCode SUFFIX_EVENT = const NgParserWarningCode(
    'SUFFIX_EVENT',
    "Expected closing parenthesis ')'",
  );

  static const NgParserWarningCode SUFFIX_PROPERTY = const NgParserWarningCode(
    'SUFFIX_PROPERTY',
    "Expected closing bracket ']'",
  );

  static const NgParserWarningCode UNCLOSED_QUOTE = const NgParserWarningCode(
    'UNCLOSED_QUOTE',
    'Expected close quote for element decorator value',
  );

  static const NgParserWarningCode UNOPENED_MUSTACHE =
      const NgParserWarningCode(
    'UNOPENED_MUSTACHE',
    'Unopened mustache',
  );

  static const NgParserWarningCode UNTERMINATED_COMMENT =
      const NgParserWarningCode(
    'UNTERMINATED COMMENT',
    'Unterminated comment',
  );

  static const NgParserWarningCode UNTERMINATED_MUSTACHE =
      const NgParserWarningCode(
    'UNTERMINATED_MUSTACHE',
    'Unterminated mustache',
  );

  static const NgParserWarningCode VOID_ELEMENT_IN_CLOSE_TAG =
      const NgParserWarningCode(
    'VOID_ELEMENT_IN_CLOSE_TAG',
    'Void element identifiers cannot be used in close element tag',
  );

  static const NgParserWarningCode VOID_CLOSE_IN_CLOSE_TAG =
      const NgParserWarningCode('VOID_CLOSE_IN_CLOSE_TAG',
          "Void close '/>' cannot be used in a close element");

  static const NgParserWarningCode WRONG_VISITOR = const NgParserWarningCode(
      'WRONG_VISITOR',
      'Pure-Dart visitor was used in Angular-based Expression node.');

  /// Initialize a newly created erorr code to have the given [name].
  /// The message associated with the error will be created from the
  /// given [message] template. The correction associated with the error
  /// will be created from the given [correction] template.
  const NgParserWarningCode(
    String name,
    String message, [
    String correction,
  ])
      : super(name, message, correction);

  NgParserWarningCode.DART_PARSER(
    String message, [
    String correction,
  ])
      : super('DART_PARSER', message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.ERROR;

  @override
  ErrorType get type => ErrorType.SYNTACTIC_ERROR;
}
