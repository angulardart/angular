# angular_ast

<!-- Badges -->

[![Pub
Package](https://img.shields.io/pub/v/angular_ast.svg)](https://pub.dartlang.org/packages/angular_ast)

Parser and utilities for [AngularDart][gh_angular_dart] templates.

[gh_angular_dart]: https://github.com/dart-lang/angular

<!-- Badges will go here -->

This package is _platform agnostic_ (no HTML or Dart VM dependencies).

## Usage

*Currently in development* and **not stable**.

```dart
import 'package:angular_ast/angular_ast.dart';

main() {
  // Create an AST tree by parsing an AngularDart template.
  var tree = parse('<button [title]="someTitle">Hello</button>');

  // Print to console.
  print(tree);

  // Output:
  // [
  //    ElementAst <button> {
  //      properties=
  //        PropertyAst {
  //          title="ExpressionAst {someTitle}"}
  //          childNodes=TextAst {Hello}
  //      }
  //    }
  // ]
}
```

Additional flags can be passed to change the behavior of the parser: `String
sourceUrl: String describing the path of the HTML string. bool desugar:
(Default: true) Enabled desugaring of banana-syntax, star syntax, and pipes.
bool parseExpressions: (Default: true) Parses Dart expressions raises exceptions
if occurred. ExceptionHandler exceptionHandler: (Default:
ThrowingExceptionHandler) Switch to 'new RecoveringExceptionHandler()' to enable
error recovery.`

When using RecoveringExceptionHandler, the accumulated exceptions can be
accessed through the RecoveringExceptionHandler object. Refer to the following
example: `void parse(String content, String sourceUrl) { var exceptionHandler =
new RecoveringExceptionHandler(); var asts = parse( content, sourceUrl:
sourceUrl, desugar: false, parseExpressions: false, exceptionHandler:
exceptionHandler, ); for (AngularParserException e in
exceptionHandler.exceptions) { // Do something with exception. } }`
