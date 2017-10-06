# Changelog

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
