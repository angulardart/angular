## 0.5.11

*   Maintenance release to support Dart 2.5 dev.

## 0.5.10

*   New `ThrowingTemplateAstVisitor` which throws by default in each visit
    method.

## 0.5.9

*   Errors caused by parsing an invalid micro expression (i.e. `*ngFor`) are now
    reported to the registered `ExceptionHandler` rather than thrown.

## 0.5.8

*   Fixed a type error that occurred when recovering from a missing closing
    banana ')]'.

## 0.5.7
*   Annotations may now have compound names (for example `@foo.bar`).

*   It is now an error to use `@deferred` on a `<template>` tag or combined with
    a structural (i.e. `*ngIf`) directive.

*   Ignores right-trailing spaces when parsing micro expression let-assignments.

*   When parsing a failed micro expression (i.e. `*ngFor`), avoids a type error.

*   `vellip` is now a recognized char.

*   Whitespace inside preformatted text (`<pre>` tags) is now always preserved.

## 0.5.6

*   Maintenance release to support Dart 2.0 stable.

## 0.5.5

*   Maintenance release for `-dev.68`.

## 0.5.4

*   Add `CloseElementAst` complement into `ContainerAst`.
*   Added support for annotations on `<template>`.
*   The whitespace transformer now understands `@preserveWhitespace`.

## 0.5.3+3

*   Maintenance release for `-dev.60`.

## 0.5.3+2

*   Maintenance release for `-dev.56`.

## 0.5.3+1

*   Fixed source span range of `AttributeAst` which would extend past EOF when
    recovering from a value with an unclosed quote.

## 0.5.3

*   Exported `ParsedAnnotationAst`.

*   Added `ContainerAst`.

*   Annotations may now be assigned values.

*   Added support for annotations on `ContainerAst`.

*   The `*` micro-syntax now supports leading whitespace.

*   Whitespace between `<ng-content>` and `</ng-content>` will no longer yield a
    parsing error.

## 0.5.2

*   The `*` micro-syntax now supports newlines after an identifier.

## 0.5.1

*   The minimum SDK version is now `sdk: ">=2.0.0-dev.46.0 <2.0.0"`.

*   The `*` micro-syntax now supports binding to the primary input when followed
    by additional input or `let` bindings. Previously the micro-syntax supported
    binding to the primary input only in isolation.

    Example usage enabled by this change.

    **Before:**

    ```html
    <template [foo]="expr1" [fooContext]="expr2">
      <div></div>
    </template>
    ```

    **After:**

    ```html
    <div *foo="expr1; context: expr2"></div>
    ```

## 0.5.0

*   **BREAKING CHANGE**: We no longer support parsing Dart expressions as part
    of parsing the template AST. We hope to re-add some support for this by
    migrating the existing parser in `package:angular`, but we are likely not to
    have a stable API for some time.

*   **BREAKING CHANGE**: Deleted `ExpressionParserVisitor` (related to above).

## 0.4.4

*   Added `MinimizeWhitespaceVisitor`.

## 0.4.3+1

*   Maintenance release, supporting newer package versions.

## 0.4.3

*   Maintenance release, supporting newer package versions.

## 0.4.2

*   Supports the latest version of `quiver`.

## 0.4.1

### Bug fixes

*   Un-escape HTML characters, such as `&lt;`, `&#8721;`, or `&#x2211;`, when
    they appear in text. Note, we do _not_ do any un-escaping when these
    characters appear inside elements.

## 0.4.0

First stable release in a while! Going forward we'll be versioning this package
normally as needed to support the AngularDart template compiler and analyzer
plugin.

### New features

*   Add `RecursiveTemplateAstVisitor`, which will visit all AST nodes accessible
    from the given node.
*   Support `ngProjectAs` decorator on `<ng-content>`.

### Bug fixes

*   `DesugarVisitor` now desugars AST nodes which were the (indirect) children
    of `EmbeddedTemplateAst` nodes.

## 0.4.0-alpha.1

*   Update version from `0.4.0-alpha+2` to make it come after `0.4.0-alpha.0`
    which was published in August 2017.

## 0.4.0-alpha+2

*   Requires `analyzer: ^0.31.0-alpha.1`.

### New Features

*   Now supports `AnnotationAst`s, like `@deferred`.
*   Parse SVG tags as either void or non-void with no error.

### Bug fixes

*   Fixed `sourceSpan` calculation to not include the space *before* the start
    of an element decorator.
*   Sets the origin in all synthetic nodes. Previously, we were missing a few
    cases.
*   Fixed a NPE in `DesugarVisitor`.

## 0.4.0-alpha+1

*   New code location! angular_ast is now part of the angular mono-repo on
    https://github.com/dart-lang/angular.

### Bug fix

*   Fixed event name for banana syntax `[(name)]` from `nameChanged` to
    `nameChange`.

## 0.2.0

*   Add an experimental flag to `NgParser` (`toolFriendlyAstOrigin`) which wraps
    de-sugared AST origins in another synthetic AST that represents the
    intermediate value (i.e. `BananaAst` or `StarAst`)
*   Add support for parsing expressions, including de-sugaring pipes. When
    parsing templates, expression AST objects automatically use the Dart
    expression parser.

```dart
new ExpressionAst.parse('some + dart + expression')
```

*   One exception: The `|` operator is not respected, as it is used for pipes in
    AngularDart. Instead, this operator is converted into a special
    `PipeExpression`.
*   Added `TemplateAstVisitor` and two examples:
    *   `HumanizingTemplateAstVisitor`
    *   `IdentityTemplateAstVisitor`
*   De-sugars the `*ngFor`-style micro expressions; see `micro/*_test.dart`.
    *   Added `attributes` as a valid property of `EmbeddedTemplateAst`

## 0.1.0

*   Initial commit
