# Syntactic Model

The syntactic model can be thought of as the AST of Angular declarations (as
opposed to templates). Since that is defined in Dart, the meaning can quickly
change semantically, and it contains a lot of information that's unnecessary to
Angular analysis itself (such as method bodies).

As such, it does not contain any actual type information, but only references
to names that can be resolved against the Dart element model. It should be
primarily strings and source ranges.

## Performance

This is largely an optimization. The syntactic model is summarizable; we can
store it and reload it from a flatbuffer file. That is much faster than
reparsing every Dart file and walking it.

Any time any Dart file is changed, it can have cascading semantic effects on
other Dart files:

```dart
// a.dart
@Component(...)
class A {
  ...
}
```

```dart
// b.dart
import 'a.dart';
@Component(
  ...
  directives: [A],
  ...
)
class ...
```

Here, if class `A` is renamed to `ComponentA`, moved to a different file,
removed, etc, then `b.dart` should produce new errors. This means we need to
re-resolve every Dart file[1], which is O(n), so that parse time adds up very
quickly. We also cannot rely on resolved ASTs to do analysis because that is
the slowest operation the Dart analyzer can perform.

For this reason, the syntactic model should not contain any information or be
built based on any information that can change in this way. That means no
references to any types or elements from the Dart analyzer library.

As long as we correctly follow those guidelines, we can cache the syntactic
model against the hash of a Dart file's contents, and our parse time becomes
O(1) for any edit of a Dart file (only that one file will be reparsed).

Ideally, the syntactic model would be able to be built completely based on an
unresolved Dart AST, however, we currently require a resolved AST in order to,
for instance, identify @Component declarations. This makes first ever run of a
project slower, and slightly slows iterative analysis, so there's room for
improvement here.

[1] Currently the analyzer does not expose a means of hooking into its
FileTracker which would allow us to only reanalyze downstream files. However,
the downstream files may be all other project files, so the worst case is still
O(n).

## References (in `reference.dart`)

A particular subtlety that's important is that there are two classes
representing directives in the syntactic model. One is where a directive is
declared, defined in `directive.dart`, and type is where a directive is
referenced:

```dart
@Directive(
  ...
)
class MyDirective { // this is a Directive
  ...
}

@Component(
  ...
  directives: [ MyDirective ] // this is a directive reference
  ...
)
class MyComponent { ...
  ...
}
```

There are also `pipe.dart`'s `Pipe`, which can be referenced in this way, and
exports which are always `Reference`s (to Dart terms, there's no corresponding
Angular declaration).

References also have an interesting quirk in that they may at times be list
literals, ie, `directives: [A, B, C]`, or they may be some other arbitrary
expression (normally a simple identifier `foo`). In this case, `A`, `B`, `C`,
and `foo` are all `Reference`s. However, the list literal itself is not. For
this reason, there's a class `ListOrReference` which has an array of internal
`Reference`s to handle this case.

Other const operations are currently unsupported such as `directives: x[y]`.
However, most const operations except identifiers and list literals cannot
produce lists.

There was another option here, which would be to use the annotation's computed
value. That would inherently support all constant expressions which is a good
thing. The problem here is reverse engineering the offsets for error reporting.
Take this example, in a future version of Dart where we have the spread
operator:

```dart
const listOne = [ValidDirective, 'not a directive']
const listTwo = [AnotherDirective];
...
  // Constant value is `[ValidDirective, 'not a directive', AnotherDirective]`.
  directives: [...listOne, ...listTwo],
```

The only way we can know whether `'not a directive'` comes from `...listOne` or
`...listTwo` (so we can highlight that range in the user's editor) is to track
and resolve `listOne` and `listTwo` ourselves.

## NgContents (in `ng_content.dart`)

Another subtlety is the way that ng-contents are *partially* syntactic. If a
component has an inline template, that component's ng-contents cannot change
until the Dart file itself is changed:

```dart
@Component(
    template: r'''
<ng-content></ng-content>
<ng-content selector="..."></ng-content>
''',
    ...
)
class ...
```

These `ng-content`s are purely syntactic and should be represented on the
`Component` class in the syntactic model.

However, external ng-contents are not syntactic *relative to the component*:

```dart
@Component(
    templateUrl: 'template-with-ng-contents.html',
    ...
)
class ...
```

Here, the component's `ng-content`s can change either when the Dart file changes
to reference a different `templateUrl`, _or_ when the _html_ file changes.

Therefore, `ng-content`s themselves are syntactic, and inline `ng-content`s are
part of the syntactic component model, but external `ng-content`s are not
included. This is why the getter is named `inlineNgContents` and not simply
`ngContents`, and there are comments referencing this document in relevant
areas.
