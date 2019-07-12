import 'package:analyzer/error/error.dart';
import 'package:angular_ast/angular_ast.dart';

/// Used by angularWarningCodeByUniqueName to create a map for fast lookup.
const _angularWarningCodeValues = <AngularWarningCode>[
  AngularWarningCode.ARGUMENT_SELECTOR_MISSING,
  AngularWarningCode.CANNOT_PARSE_SELECTOR,
  AngularWarningCode.REFERENCED_HTML_FILE_DOESNT_EXIST,
  AngularWarningCode.TEMPLATE_URL_AND_TEMPLATE_DEFINED,
  AngularWarningCode.NO_TEMPLATE_URL_OR_TEMPLATE_DEFINED,
  AngularWarningCode.EXPECTED_IDENTIFIER,
  AngularWarningCode.UNEXPECTED_HASH_IN_TEMPLATE,
  AngularWarningCode.STRING_VALUE_EXPECTED,
  AngularWarningCode.TYPE_LITERAL_EXPECTED,
  AngularWarningCode.TYPE_IS_NOT_A_DIRECTIVE,
  AngularWarningCode.FUNCTION_IS_NOT_A_DIRECTIVE,
  AngularWarningCode.UNRESOLVED_TAG,
  AngularWarningCode.UNTERMINATED_MUSTACHE,
  AngularWarningCode.UNOPENED_MUSTACHE,
  AngularWarningCode.NONEXIST_INPUT_BOUND,
  AngularWarningCode.NONEXIST_OUTPUT_BOUND,
  AngularWarningCode.EMPTY_BINDING,
  AngularWarningCode.NONEXIST_TWO_WAY_OUTPUT_BOUND,
  AngularWarningCode.TWO_WAY_BINDING_OUTPUT_TYPE_ERROR,
  AngularWarningCode.INPUT_BINDING_TYPE_ERROR,
  AngularWarningCode.ATTR_IF_BINDING_TYPE_ERROR,
  AngularWarningCode.UNMATCHED_ATTR_IF_BINDING,
  AngularWarningCode.TRAILING_EXPRESSION,
  AngularWarningCode.OUTPUT_MUST_BE_STREAM,
  AngularWarningCode.TWO_WAY_BINDING_NOT_ASSIGNABLE,
  AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
  AngularWarningCode.OUTPUT_ANNOTATION_PLACEMENT_INVALID,
  AngularWarningCode.INVALID_HTML_CLASSNAME,
  AngularWarningCode.CLASS_BINDING_NOT_BOOLEAN,
  AngularWarningCode.CSS_UNIT_BINDING_NOT_NUMBER,
  AngularWarningCode.INVALID_CSS_UNIT_NAME,
  AngularWarningCode.INVALID_CSS_PROPERTY_NAME,
  AngularWarningCode.INVALID_BINDING_NAME,
  AngularWarningCode.STRUCTURAL_DIRECTIVES_REQUIRE_TEMPLATE,
  AngularWarningCode.CUSTOM_DIRECTIVE_MAY_REQUIRE_TEMPLATE,
  AngularWarningCode.TEMPLATE_ATTR_NOT_USED,
  AngularWarningCode.NO_DIRECTIVE_EXPORTED_BY_SPECIFIED_NAME,
  AngularWarningCode.CONTENT_NOT_TRANSCLUDED,
  AngularWarningCode.OUTPUT_STATEMENT_REQUIRES_EXPRESSION_STATEMENT,
  AngularWarningCode.DISALLOWED_EXPRESSION,
  AngularWarningCode.ATTRIBUTE_PARAMETER_MUST_BE_STRING,
  AngularWarningCode.STRING_STYLE_INPUT_BINDING_INVALID,
  AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
  AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE,
  AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
  AngularWarningCode.CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST,
  AngularWarningCode.MATCHED_LET_BINDING_HAS_WRONG_TYPE,
  AngularWarningCode.EXPORTS_MUST_BE_PLAIN_IDENTIFIERS,
  AngularWarningCode.DUPLICATE_EXPORT,
  AngularWarningCode.IDENTIFIER_NOT_EXPORTED,
  AngularWarningCode.COMPONENTS_CANT_EXPORT_THEMSELVES,
  AngularWarningCode.PIPE_SINGLE_NAME_REQUIRED,
  AngularWarningCode.TYPE_IS_NOT_A_PIPE,
  AngularWarningCode.PIPE_CANNOT_BE_ABSTRACT,
  AngularWarningCode.PIPE_REQUIRES_PIPETRANSFORM,
  AngularWarningCode.PIPE_REQUIRES_TRANSFORM_METHOD,
  AngularWarningCode.PIPE_TRANSFORM_NO_NAMED_ARGS,
  AngularWarningCode.PIPE_TRANSFORM_REQ_ONE_ARG,
  AngularWarningCode.PIPE_NOT_FOUND,
  AngularWarningCode.AMBIGUOUS_PIPE,
  AngularWarningCode.UNSAFE_BINDING,
  AngularWarningCode.EVENT_REDUCTION_NOT_ALLOWED,
  AngularWarningCode.FUNCTIONAL_DIRECTIVES_CANT_BE_EXPORTED,
  AngularHintCode.OFFSETS_CANNOT_BE_CREATED,
];

/// The lazy initialized map from [AngularWarningCode.uniqueName] to the
/// [AngularWarningCode] instance.
Map<String, ErrorCode> _uniqueNameToCodeMap;

/// Return the [AngularWarningCode] with the given [uniqueName], or `null` if
/// not found.
ErrorCode angularWarningCodeByUniqueName(String uniqueName) {
  if (_uniqueNameToCodeMap == null) {
    _generateErrorCodeMap();
  }
  return _uniqueNameToCodeMap[uniqueName];
}

/// Map [_angularWarningCodeValues] by error id into [_uniqueNameToCodeMap].
void _generateErrorCodeMap() {
  _uniqueNameToCodeMap = {};
  for (final angularCode in _angularWarningCodeValues) {
    _uniqueNameToCodeMap[angularCode.uniqueName] = angularCode;
  }
  for (final angularAstCode in angularAstWarningCodes) {
    _uniqueNameToCodeMap[angularAstCode.uniqueName] = angularAstCode;
  }
}

class AngularHintCode extends AngularWarningCode {
  /// Error code indicating a complex const expression is used as a template.
  ///
  /// When a user does for instance `template: 'foo$bar$baz`, we cannot analyze
  /// the template because we cannot easily map errors to code offsets.
  static const OFFSETS_CANNOT_BE_CREATED = AngularHintCode(
      'OFFSETS_CANNOT_BE_CREATED',
      'Errors cannot be tracked for the constant expression because it is too'
          ' complex for errors to be mapped to locations in the file');

  /// Initialize a newly created error code to have the given [name].
  ///
  /// The message associated with the error will be created from the given
  /// [message] template. The correction associated with the error will be
  /// created from the given [correction] template.
  const AngularHintCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.INFO;

  @override
  ErrorType get type => ErrorType.HINT;
}

/// The error codes used for Angular warnings.
///
/// The convention for this class is for the name of the error code to indicate
/// the problem that caused the error to be generated and for the error message
/// to explain what is wrong and, when appropriate, how the problem can be
/// corrected.
class AngularWarningCode extends ErrorCode {
  /// An error for when a directive does not define a "selector".
  static const ARGUMENT_SELECTOR_MISSING = AngularWarningCode(
      'ARGUMENT_SELECTOR_MISSING', 'Argument "selector" missing');

  /// An error for when the provided selector cannot be parsed.
  static const CANNOT_PARSE_SELECTOR = AngularWarningCode(
      'CANNOT_PARSE_SELECTOR', 'Cannot parse the given selector ({0})');

  /// An error for when a template points to a missing html file.
  static const REFERENCED_HTML_FILE_DOESNT_EXIST = AngularWarningCode(
      'REFERENCED_HTML_FILE_DOESNT_EXIST',
      'The referenced HTML file doesn\'t exist');

  /// An error for when a @Component has both a template and a templateUrl
  /// defined at once.
  static const TEMPLATE_URL_AND_TEMPLATE_DEFINED = AngularWarningCode(
      'TEMPLATE_URL_AND_TEMPLATE_DEFINED',
      'Cannot define both template and templateUrl. Remove one');

  /// An error for when a @Component does not have a template or a templateUrl.
  static const NO_TEMPLATE_URL_OR_TEMPLATE_DEFINED = AngularWarningCode(
      'NO_TEMPLATE_URL_OR_TEMPLATE_DEFINED',
      'Either a template or templateUrl is required');

  /// An error for when an identifier was expected, but not found.
  static const EXPECTED_IDENTIFIER =
      AngularWarningCode('EXPECTED_IDENTIFIER', 'Expected identifier');

  /// An error for when a hash was unexpected in template.
  static const UNEXPECTED_HASH_IN_TEMPLATE = AngularWarningCode(
      'UNEXPECTED_HASH_IN_TEMPLATE', "Did you mean 'let' instead?");

  /// An error for when the value of an expression is not a string.
  static const STRING_VALUE_EXPECTED =
      AngularWarningCode('STRING_VALUE_EXPECTED', 'A string value expected');

  /// An error for when the value of an expression is not a type literal.
  static const TYPE_LITERAL_EXPECTED =
      AngularWarningCode('TYPE_LITERAL_EXPECTED', 'A type literal expected');

  /// An error for when the value of an expression is not a directive.
  static const TYPE_IS_NOT_A_DIRECTIVE = AngularWarningCode(
      'TYPE_IS_NOT_A_DIRECTIVE',
      'The type "{0}" is included in the directives list, but is not a'
          ' directive');

  /// An error for when a non-@Directive function was used as one.
  static const FUNCTION_IS_NOT_A_DIRECTIVE = AngularWarningCode(
      'FUNCTION_IS_NOT_A_DIRECTIVE',
      'The function "{0}" is included in the directives list, but is not a'
          ' functional directive');

  /// An error for when a type which is not a Pipe is used as one.
  static const TYPE_IS_NOT_A_PIPE = AngularWarningCode('TYPE_IS_NOT_A_PIPE',
      'The type "{0}" is included in the pipes list, but is not a pipe');

  /// An error for when a tag name cannot be resolved.
  static const UNRESOLVED_TAG =
      AngularWarningCode('UNRESOLVED_TAG', 'Unresolved tag "{0}"');

  /// An error for when an embedded expression is not terminated.
  static const UNTERMINATED_MUSTACHE =
      AngularWarningCode('UNTERMINATED_MUSTACHE', 'Unterminated mustache');

  /// An error for when a mustache ending was found, with no opening.
  static const UNOPENED_MUSTACHE = AngularWarningCode(
      'UNOPENED_MUSTACHE', 'Mustache terminator with no opening');

  /// An error for when a nonexist input was bound.
  static const NONEXIST_INPUT_BOUND = AngularWarningCode('NONEXIST_INPUT_BOUND',
      'The bound input {0} does not exist on any directives or on the element');

  /// An error for when a nonexist output was bound.
  static const NONEXIST_OUTPUT_BOUND = AngularWarningCode(
      'NONEXIST_OUTPUT_BOUND',
      'The bound output {0} does not exist on any directives or on the'
          ' element');

  /// An error for when a binding doesn't include a value.
  static const EMPTY_BINDING = AngularWarningCode(
      'EMPTY_BINDING', 'The binding {0} does not have a value specified');

  /// An error for when a nonexist output was bound in a two-way binding.
  ///
  /// The nonexist bound output is implicit, so give its own error.
  static const NONEXIST_TWO_WAY_OUTPUT_BOUND = AngularWarningCode(
      'NONEXIST_TWO_WAY_OUTPUT_BOUND',
      'The two-way binding {0} requires a bindable output of name {1}');

  /// An error for when the output event in a two-way binding doesn't match the
  /// input.
  static const TWO_WAY_BINDING_OUTPUT_TYPE_ERROR = AngularWarningCode(
      'TWO_WAY_BINDING_OUTPUT_TYPE_ERROR',
      'Output event in two-way binding (of type {0}) is not assignable to'
          ' component input (of type {1})');

  /// An error for when an input was bound with a incorrectly typed expression.
  static const INPUT_BINDING_TYPE_ERROR = AngularWarningCode(
      'INPUT_BINDING_TYPE_ERROR',
      'Attribute value expression (of type {0}) is not assignable to component'
          ' input (of type {1})');

  /// An error for when an `[attr.foo.if]` binding was bound to an expression
  /// that was not of type bool.
  static const ATTR_IF_BINDING_TYPE_ERROR = AngularWarningCode(
      'ATTR_IF_BINDING_TYPE_ERROR',
      'Attribute value expression (of type {0}) must be of type bool');

  /// An error for when an `[attr.foo.if]` binding was used, but no `[attr.foo]`
  /// binding simultaneously occured.
  static const UNMATCHED_ATTR_IF_BINDING = AngularWarningCode(
      'UNMATCHED_ATTR_IF_BINDING',
      'attr-if binding for attr {0} does not have a corresponding'
          ' [attr.{0}] binding for it to affect');

  /// An error for trailing characters after parsing an expression.
  ///
  /// This occurs because the Dart parser expects expressions to occur in a
  /// larger context (a Dart file). It stops parsing on certain conditions such
  /// as semi-colons. We must report the excess, ie, `{{foo;}}`.
  static const TRAILING_EXPRESSION = AngularWarningCode(
      'TRAILING_EXPRESSION', 'Unexpected expression contents');

  /// An error for when an `@Output` is not an Stream.
  static const OUTPUT_MUST_BE_STREAM = AngularWarningCode(
      'OUTPUT_MUST_BE_STREAM', 'Output (of name {0}) must return a Stream');

  /// An error for when a two-way binding expression is not assignable.
  static const TWO_WAY_BINDING_NOT_ASSIGNABLE = AngularWarningCode(
      'TWO_WAY_BINDING_NOT_ASSIGNABLE',
      'Only assignable expressions can be two-way bound');

  /// An error for when an `@Input` annotation was used in the wrong place.
  static const INPUT_ANNOTATION_PLACEMENT_INVALID = AngularWarningCode(
      'INPUT_ANNOTATION_PLACEMENT_INVALID',
      'The @Input() annotation can only be put on properties and setters');

  /// An error for when an `@Output` annotation was used in the wrong place.
  static const OUTPUT_ANNOTATION_PLACEMENT_INVALID = AngularWarningCode(
      'OUTPUT_ANNOTATION_PLACEMENT_INVALID',
      'The @Output() annotation can only be put on properties and getters');

  /// An error for when a classname binding is invalid.
  ///
  /// Occurs when [class.classname]="x" is used where classname is not a css
  /// identifier.
  ///
  /// https://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
  static const INVALID_HTML_CLASSNAME = AngularWarningCode(
      'INVALID_HTML_CLASSNAME',
      'The html classname {0} is not a valid classname');

  /// An error for binding a classname via a non-boolean in the form
  /// `[class.classname]="x"`.
  static const CLASS_BINDING_NOT_BOOLEAN = AngularWarningCode(
      'CLASS_BINDING_NOT_BOOLEAN', 'Binding to a classname requires a boolean');

  /// An error for binding a css property with a unit that is not a number with
  /// the form `[style.property.unit]="x"`.
  static const CSS_UNIT_BINDING_NOT_NUMBER = AngularWarningCode(
      'CSS_UNIT_BINDING_NOT_NUMBER',
      'Binding to a css property with a unit requires a number');

  /// An error for binding a css property with a unit which is not a valid css
  /// identifier in the form `[style.property.unit]="x"`.
  ///
  /// https://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
  static const INVALID_CSS_UNIT_NAME = AngularWarningCode(
      'INVALID_CSS_UNIT_NAME',
      'The css unit {0} is not a valid css identifier');

  /// An error for binding a css property with a name which is not a valid css
  /// identifier in the form `[style.property]="x"`.
  ///
  /// https://www.w3.org/TR/CSS21/syndata.html#value-def-identifier
  static const INVALID_CSS_PROPERTY_NAME = AngularWarningCode(
      'INVALID_CSS_PROPERTY_NAME',
      'The css property {0} is not a valid css identifier');

  /// An error for when a binding was not a valid dart or angular identifier.
  ///
  /// Bindings must be one of: a dart identifer, `[class.classname]`,
  /// `[attr.attrname]`, `[style.property]`, or `[style.property.unit]`.
  static const INVALID_BINDING_NAME = AngularWarningCode(
      'INVALID_BINDING_NAME',
      'The binding {} is not a valid dart identifer, attribute, style, or class'
          ' binding');

  /// An error for when `ngIf` or `ngFor` were used without a template.
  static const STRUCTURAL_DIRECTIVES_REQUIRE_TEMPLATE = AngularWarningCode(
      'STRUCTURAL_DIRECTIVES_REQUIRE_TEMPLATE',
      'Structural directive {0} requires a template. Did you mean'
          ' *{0}="..." or template="{0} ..." or <template {0} ...>?');

  /// An error for when `x` is not an exported name in `#y="x"`.
  static const NO_DIRECTIVE_EXPORTED_BY_SPECIFIED_NAME = AngularWarningCode(
      'NO_DIRECTIVE_EXPORTED_BY_SPECIFIED_NAME',
      'No directives matching this element are exported by the name {0}');

  /// An error for when an export is ambiguous.
  ///
  /// This occurs in in `<div dir1 dir2 #y="x">`. `x` is then ambigious when
  /// both directives dir1 and dir2 have same `exportAs` name "x".
  static const DIRECTIVE_EXPORTED_BY_AMBIGIOUS = AngularWarningCode(
      'DIRECTIVE_EXPORTED_BY_AMBIGIOUS',
      "More than one directive's exportAs value matches '{0}'.");

  /// An error for when a custom component appears to require a star.
  static const AngularWarningCode CUSTOM_DIRECTIVE_MAY_REQUIRE_TEMPLATE =
      AngularWarningCode(
          'CUSTOM_DIRECTIVE_MAY_REQUIRE_TEMPLATE',
          'The directive {0} accepts a TemplateRef in its constructor, so it'
              ' may require a *-style-attr to work correctly.');

  /// An error for when a template or star-attr doesn't match any directives.
  static const AngularWarningCode TEMPLATE_ATTR_NOT_USED = AngularWarningCode(
      'TEMPLATE_ATTR_NOT_USED',
      'This template attr does not match any directives that use the'
          ' resulting hidden template. Check that all directives are being'
          ' imported and used correctly.');

  /// An error for when an output-binding is not an [ExpressionStatement].
  static const OUTPUT_STATEMENT_REQUIRES_EXPRESSION_STATEMENT =
      AngularWarningCode('OUTPUT_STATEMENT_REQUIRES_EXPRESSION_STATEMENT',
          "Syntax Error: unexpected {0}");

  /// An error for when a dart expression in a template uses unsupported dart
  /// syntax.
  ///
  /// Unsupported syntax includes expressions such as 'as' expressions and
  /// constructors.
  static const DISALLOWED_EXPRESSION = AngularWarningCode(
      'DISALLOWED_EXPRESSION', "{0} not allowed in angular templates");

  /// An error for when dom inside a component won't be transcluded.
  static const CONTENT_NOT_TRANSCLUDED = AngularWarningCode(
      'CONTENT_NOT_TRANSCLUDED',
      'The content does not match any transclusion selectors of the surrounding'
          ' component');

  /// An error for when an <ng-content> tag had content, which is not allowed.
  static const NG_CONTENT_MUST_BE_EMPTY = AngularWarningCode(
      'NG_CONTENT_MUST_BE_EMPTY',
      'Nothing is allowed inside an <ng-content> tag, as it will be replaced');

  /// An error for constructor parameters marked with `@Attribute` that aren't
  /// of type String.
  static const ATTRIBUTE_PARAMETER_MUST_BE_STRING = AngularWarningCode(
      'ATTRIBUTE_PARAMETER_MUST_BE_STRING',
      'Parameters marked with @Attribute must be of type String');

  /// An error for binding a non-string input in string format.
  ///
  /// For instance, using `x="y"` rather than `[x]="y"`, where input `x` is not
  /// a string input.
  static const STRING_STYLE_INPUT_BINDING_INVALID = AngularWarningCode(
      'STRING_STYLE_INPUT_BINDING_INVALID',
      'Input {0} is not a string input, but is not bound with [bracket] syntax.'
          ' This binds the String attribute value directly, resulting  in a type '
          'error.');

  /// An error for type mismatches in the definition of `@ContentChild` and
  /// `@ContentChildren`.
  ///
  /// For example: `@ContentChild(TemplateRef) ElementRef foo`.
  static const INVALID_TYPE_FOR_CHILD_QUERY = AngularWarningCode(
      'INVALID_TYPE_FOR_CHILD_QUERY',
      'The field {0} marked with @{1} referencing type {2} expects a member'
          ' referencing type {2}, but got a {3}');

  /// An error for when a `@ContentChild` or `@ContentChildren` had an
  /// unexpected value.
  static const UNKNOWN_CHILD_QUERY_TYPE = AngularWarningCode(
      'UNKNOWN_CHILD_QUERY_TYPE',
      'The field {0} marked with @{1} must reference a directive, a string'
          ' let-binding name, TemplateRef, or ElementRef');

  /// An error for when a @ContentChild or @ContentChildren field must specify
  /// a `read` value.
  static const CHILD_QUERY_TYPE_REQUIRES_READ = AngularWarningCode(
      'CHILD_QUERY_TYPE_REQUIRES_READ',
      'The field {0} marked with @{1} cannot reference type {2} unless the @{1}'
          ' annotation includes `read: {2}`');

  /// An error for when `@ContentChildren` or `@ViewChildren` was declared
  /// on a non-`List`.
  static const CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST = AngularWarningCode(
      'CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST',
      'The field {0} marked with @{1} expects a member of type List,'
          ' but got {2}');

  /// An error for when a let-bound @ContentChild or @ViewChild was matched but
  /// isn't assignable.
  ///
  /// For example, `<div #foo>` given `@ContentChild('foo') TemplateRef foo`.
  static const MATCHED_LET_BINDING_HAS_WRONG_TYPE = AngularWarningCode(
      'MATCHED_LET_BINDING_HAS_WRONG_TYPE',
      'Marking this with #{0} here expects the element to be of type {1}, (but'
          ' is of type {2}) because an enclosing element marks {0} as a content'
          ' child field of type {1}.');

  /// An error for when a `@ContentChild` was matched multiple times.
  ///
  /// TODO(b/129880606): Support `@ViewChild` analysis as well.
  static const SINGULAR_CHILD_QUERY_MATCHED_MULTIPLE_TIMES = AngularWarningCode(
      'SINGULAR_CHILD_QUERY_MATCHED_MULTIPLE_TIMES',
      'A containing {0} expects a single child matching {1}, but this is'
          ' not the first match. Use (Content or View)Children to allow'
          ' multiple matches.');

  /// An error for when the exports array got a non-identifier.
  static const EXPORTS_MUST_BE_PLAIN_IDENTIFIERS = AngularWarningCode(
      'EXPORTS_MUST_BE_PLAIN_IDENTIFIERS', 'Exports must be plain identifiers');

  /// An error for when an identifier was exported multiple times.
  static const DUPLICATE_EXPORT = AngularWarningCode(
      'DUPLICATE_EXPORT', 'Duplicate export of identifier {0}');

  /// An error for when an identifier was used in a template, but not exported
  /// in the component.
  static const IDENTIFIER_NOT_EXPORTED = AngularWarningCode(
      'IDENTIFIER_NOT_EXPORTED',
      'Identifier {0} was not exported by the component and therefore cannot be'
          ' used in its template. Add it to the exports property on the component'
          ' definition to use it here.');

  /// An error for when component `Foo` exports `Foo`, which is unnecessary.
  static const COMPONENTS_CANT_EXPORT_THEMSELVES = AngularWarningCode(
      'COMPONENTS_CANT_EXPORT_THEMSELVES',
      'Components export their class by default, and therefore should not be'
          ' specified in the exports list');

  /// An error for when a Pipe class is abstract.
  static const PIPE_CANNOT_BE_ABSTRACT = AngularWarningCode(
      'PIPE_CANNOT_BE_ABSTRACT', r'Pipe classes cannot be abstract');

  /// An error for when a Pipe annotation does not include a name.
  static const PIPE_SINGLE_NAME_REQUIRED = AngularWarningCode(
      'PIPE_NAME_MISSING',
      r'@Pipe declarations must contain exactly one'
          r' non-named argument of String type for pipe name');

  /// An error for when a declared Pipe does not extend [PipeTransform] class.
  static const PIPE_REQUIRES_PIPETRANSFORM = AngularWarningCode(
      'PIPE_REQUIRES_PIPETRANSFORM',
      "@Pipe declared classes need to extend 'PipeTransform'");

  /// An error for when a declared Pipe does not have a 'transform' method.
  static const PIPE_REQUIRES_TRANSFORM_METHOD = AngularWarningCode(
    'PIPE_REQUIRES_TRANSFORM_METHOD',
    "@Pipe declared classes must contain a 'transform' method",
  );

  /// An error for when a Pipe's 'transform' method has named arguments.
  static const PIPE_TRANSFORM_NO_NAMED_ARGS = AngularWarningCode(
      'PIPE_TRANSFORM_NO_NAMED_ARGS',
      "'transform' method for pipe should not have named arguments");

  /// An error for when a Pipe's 'transform' method does not have at least one
  /// argument.
  static const PIPE_TRANSFORM_REQ_ONE_ARG = AngularWarningCode(
      'PIPE_TRANSFORM_REQ_ONE_ARG',
      "'transform' method requires at least one argument");

  /// An error for when pipe syntax is used but does not match a pipe name.
  static const PIPE_NOT_FOUND = AngularWarningCode(
      'PIPE_NOT_FOUND',
      "Pipe by name of {0} not found. Did you reference it in your @Component"
          " configuration?");

  /// An error for when pipe syntax is used but the name matches multiple pipes.
  static const AMBIGUOUS_PIPE = AngularWarningCode(
      'AMBIGUOUS_PIPE',
      "Multiple pipes by name of {0} found. Check the `pipes` field of your "
          "@Component annotation for duplicates and/or conflicts.");

  /// An error for when a security exception will be thrown by an input binding.
  static const UNSAFE_BINDING = AngularWarningCode(
      'UNSAFE_BINDING',
      'A security exception will be thrown by this binding. You must use the '
          ' security service to get an instance of {0} and bind that result.');

  /// An error for when that a non-key event has reductions.
  ///
  /// Reductions are only allowed on keyup, keydown, etc., ie `(keyup.x)` or
  /// `(keydown.+)`.
  static const EVENT_REDUCTION_NOT_ALLOWED = AngularWarningCode(
      'EVENT_REDUCTION_NOT_ALLOWED',
      'Event reductions are only allowed on keyup and keydown events');

  /// An error for when that functional directve had a specified `exportAs`.
  static const FUNCTIONAL_DIRECTIVES_CANT_BE_EXPORTED = AngularWarningCode(
      'FUNCTIONAL_DIRECTIVES_CANT_BE_EXPORTED',
      'Function directives cannot have an exportAs setting, because they'
          " can't be exported");

  /// Initialize a newly created error code to have the given [name].
  ///
  /// The message associated with the error will be created from the given
  /// [message] template. The correction associated with the error will be
  /// created from the given [correction] template.
  const AngularWarningCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
