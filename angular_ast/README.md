# angular_ast

<!-- Badges -->

[![Pub
Package](https://img.shields.io/pub/v/angular_ast.svg)](https://pub.dev/packages/angular_ast)

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

Additional flags can be passed to change the behavior of the parser: 

| Data type | Name | Description | Default Value |
|------------|------------|--------------|---------------|
| `String` | _sourceUrl_ | String describing the path of the HTML string. |  |
| `bool` | _desugar_ | Enabled desugaring of banana-syntax, star syntax, and pipes. | true |
| `bool` | _parseExpressions_ | Parses Dart expressions raises exceptions if occurred. | true |
| `ExceptionHandler` | _exceptionHandler_ | Switch to 'new RecoveringExceptionHandler()' to enable error recovery. | ThrowingExceptionHandler |

When using RecoveringExceptionHandler, the accumulated exceptions can be
accessed through the RecoveringExceptionHandler object. Refer to the following
example: 
```dart
void parse(String content, String sourceUrl) {
  var exceptionHandler = new RecoveringExceptionHandler();
  var asts = parse(
    content,
    sourceUrl: sourceUrl,
    desugar: false,
    parseExpressions: false,
    exceptionHandler: exceptionHandler,
  );
  for (AngularParserException e in exceptionHandler.exceptions) {
    // Do something with exception.
  }
}
```
