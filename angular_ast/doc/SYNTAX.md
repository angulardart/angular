# Angular Dart Template Syntax

This syntax reference is a minimal lintroduction to:

- [Comments](#Comments)
- [Interpolation](#Interpolation)
- [Expressions](#Expressions)
- [Elements](#Elements)
- [Attributes](#Attributes)
- [Properties](#Properties)
- [Events](#Events)
- [Variables](#Variables)

## Comments

Comments are used to annotate the HTML to provide extra information for
developers or tools but are not rendered when the application is rendered
within the browser.

Comments may be removed in a production build.

### Grammar
```bnf
Comment ::= '<!--' CommentCharData? '-->'
```

### Examples
```html
<!-- A single or multi line comment -->
```

## Interpolation

Text nodes in a template can be augmented with expressions that are evaluated
against the context of the template (i.e. the component instance).

### Grammar
```bnf
Interpolation ::= '{{' Expression '}}'
```

### Examples
```dart
class Comp {
  String name = 'Joe User';
}
```

```html
Hello {{name}}!
```

Results in a rendered output of:

```html
Hello Joe User!
```

## Expressions

An expression is equivalent to a valid Dart expression evaluated against the
context of a component instance, with one exception: support for a "pipe" `|`
operator that evaluates an expression against a `Pipe` class.

### Grammar
```bnf
Expression ::= (DartExpression | DartExpression |? Pipe)
```

### Examples

Just Dart expressions:
```html
formatCurrency(microsUsd)
```

With pipes:
```html
microsUsd | currencyPipe
```

## Elements

### Grammar

```bnf
Element ::= '<' TagName * (WhiteSpace AttributeList) '>' Content '</' TagName '>'
```

### Examples

```html
<div>
  <span>Hello World</span>
</div>
```

## Attributes

### Grammar

TODO

### Examples

TODO

## Properties

### Grammar

TODO

### Examples

TODO

## Events

### Grammar

TODO

### Examples

TODO

## Variables

### Grammar

TODO

### Examples

TODO
