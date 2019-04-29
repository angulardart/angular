# Angular Template Resolver

This directory contains the bulk of true template resolution code. This runs
after directive definitions have been parsed, linked, and their ASTs have been
parsed with `angular_ast` and converted into our own AST.

Errors are produced, click-through navigation sites are discovered, and the
resolved data is stored in the AST for autocompletion later.

## Visitors / overall process

Resolution begins with `TemplateResolver`, which runs the other visitors in the
proper order.

There are two visitors which are *not* template visitors but rather Dart
expression visitors. See the section "special Dart visitors."

### Single pass visitors

There are two single-pass visitors which run at the very beginning. These are
`DirectiveResolver` and `ComponentContentResolver`. The former matches tags to
directives, and directives within directives to content child fields. The latter
finds transcluded elements and reports unknown tag errors, since that is when we
have ruled out all possible usages of a tag (component reference or ng-content
selector match).

### Scoped visitors

At that point we collect scopes via `NextTemplateElementsSearch` and process
them individually in `TemplateResolver._resolveScope`.

The most important visitor to understand here is `AngularScopeVisitor` which
abstracts the way scopes work inside an angular template, which is driven
through template attributes, template tags, and star attributes. There are some
interesting quirks here to observe:

```html
<div> <!-- root of scope -->

  <!-- the click handler "foo()" is in the new scope -->
  <!-- the ngIf binding "bar" is in the original scope -->
  <div
      (click)="foo()"
      *ngIf="bar"
    >
    <!-- new scope -->
  </div>
</div>
```

Each scope shares `let-` and `#`-bound variables, the latter of which can be
used before they are defined, akin to class fields

```html
{{foo.bar}}
<my-component #foo>
```

Note as well that `let-` bound variables are special because they affect the
inner scope rather than the current scope:

```html
<!-- `item` is _defined_ in the `template` tag's scope, but the variable `item`
     is actually _usable_ in the _inner_ scope. -->
<template ngFor let-item [ngForOf]="items">
  <!-- ... inner scope ... -->
</div>
```

`AngularScopeVisitor` abstracts and has additional documentation on this.

The visitors that run on these scopes are two different preparation steps
(`PrepareScopeVisitor` and `PrepareEventScopeVisitor`) and then a principle
resolving visitor `SingleScopeResolver`.

#### PrepareScopeVisitor

`PrepareScopeVisitor` creates an "exportAs scope" for each variable containing
the matched directives and components and their exported names (if any). It also
defines "internal variables" as created by `NgFor`, such as `even`, `odd`, and
`$implicit` which references the `NgFor` variable itself.

It then looks at attributes within the scope like `#foo` and `let-x="y"` (and
`let x ; let odd: odd` in `*ngFor*`) and resolves the types of those internal
variables through the "exportAs scope" or "internal variables" scope. Those
types and names are then used to create a `LocalVariableElement` that will be
understood by the Dart analyzer APIs with the help of the `DartVariableManager`.

These variables are stored on the nodes, and passed into lower scopes as they
are resolved later.

#### PrepareEventScopeVisitor

Output bindings have the same scope as the node in which they are contained,
however, they also have a unique `$event` variable.

For this reason, `PrepareEventScopeVisitor` runs after the main scope variables
have all been resolved.

In order to find the type of `$event` variables, the output has to be resolved
by name against the standard and directive/component-specific outputs available
to that node. If an unrecognized output is used, it is flagged.

A scope consisting of the outer scope plus the `$event` variable is then stored
in the attribute's scope.

#### SingleScopeResolver

`SingleScopeResolver` then resolves everything else:

- Dart expressions & statements are resolved & typechecked, using a special Dart
  expression resolver `AngularResolverVisitor` which handles pipe expressions.
- non-AngularDart expressions (such as `new`, `throw`, and referencing
  un`export`ed terms) are flagged by `AngularSubsetVisitor`.
- input bindings by name, assignability
- special bindings like class bindings, style bindings are resolved
- Angular navigation ranges are recorded via `template.addRange`
- Dart expression navigation ranges are recorded via`DartReferencesRecorder`

### Recurse

After this point, `NextTemplateElementsSearch` finds the next scope and the
process recurses.

### Special Dart visitors

There are two visitors which are *not* template visitors but rather Dart
expression visitors.

These two visitors are `AngularResolverVisitor` and `AngularSubsetVisitor`.

`AngularResolverVisitor` is a subclass of `package:analyzer`'s `ResolverVisitor`
which adds support for pipes.

`AngularSubsetVisitor` finds non-AngularDart expressions (such as `new`,
`throw`, and referencing un`export`ed terms) and flags them.
