### New features

- Add `RecursiveTemplateAstVisitor`, which will visit all AST nodes accessible
  from the given node.
- Support `ngProjectAs` decorator on `<ng-content>`.

### Bug fixes
- `DesugarVisitor` now desugars AST nodes which were the (indirect) children of
  `EmbeddedTemplateAst` nodes.

## 0.4.0-alpha.1

- Update version from `0.4.0-alpha+2` to make it come after `0.4.0-alpha.0`
  which was published in August 2017.

## 0.4.0-alpha+2

- Requires `analyzer: ^0.31.0-alpha.1`.

### New Features
- Now supports `AnnotationAst`s, like `@deferred`.
- Parse SVG tags as either void or non-void with no error.

### Bug fixes
- Fixed `sourceSpan` calculation to not include the space *before* the start of
  an element decorator.
- Sets the origin in all synthetic nodes. Previously, we were missing a few cases.
- Fixed a NPE in `DesugarVisitor`.

## 0.4.0-alpha+1

- New code location! angular_ast is now part of the angular mono-repo on
  https://github.com/dart-lang/angular.

### Bug fix

- Fixed event name for banana syntax `[(name)]` from `nameChanged` to
  `nameChange`.

## 0.2.0

- Add an experimental flag to `NgParser` (`toolFriendlyAstOrigin`) which
  wraps de-sugared AST origins in another synthetic AST that represents
  the intermediate value (i.e. `BananaAst` or `StarAst`)
- Add support for parsing expressions, including de-sugaring pipes. When
  parsing templates, expression AST objects automatically use the Dart
  expression parser.

```dart
new ExpressionAst.parse('some + dart + expression')
```

- One exception: The `|` operator is not respected, as it is used for
  pipes in AngularDart. Instead, this operator is converted into a
  special `PipeExpression`.
- Added `TemplateAstVisitor` and two examples:
    - `HumanizingTemplateAstVisitor`
    - `IdentityTemplateAstVisitor`
- De-sugars the `*ngFor`-style micro expressions; see `micro/*_test.dart`.
    - Added `attributes` as a valid property of `EmbeddedTemplateAst`

## 0.1.0

- Initial commit
