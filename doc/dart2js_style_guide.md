# Dart2JS Style Guide

Below is a non-authoritative style guide for building
low-overhead/high-performance Dart applications, specifically when compiled to
dart2js. The AngularDart team follows these _additional_ restrictions on top of
the Dart style guide when _developing_ AngularDart's _runtime_ components (i.e.
code that is eventually compiled and run as JavaScript).

*   It's not a goal to replace 100% of all code to match this style guide.
*   Sometimes it makes sense to skip a rule (or two) on a case by case basis.
*   Clients may have their own priorities (i.e. code readability, scalability,
    large team dynamics), so this isn't a style guide for people _writing_
    AngularDart applications.

## Do not implement `hashCode` or `operator ==`

It's very hard for `dart2js` to tree-shake out these methods, because they are
practically used in every application (i.e. adding anything to a `{}` literal
will invoke both of these operators). It _can_ be nice for testing, so consider
either writing a `Matcher` or an `Equality` class to use instead.

It's also OK to implement `Comparable`, or something that is not always used.

**BAD**:

```dart
class Animal {
  final String name;

  Animal(this.name);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator==(Object o) => o is Animal && o.name == name;
}
```

**OK**:

```dart
import 'package:matcher/matcher.dart';

class AnimalMatcher extends Matcher {
  // ...
}
```

**OK**:

```dart
import 'package:collection/collection.dart';

class AnimalEquality extends Equality<Animal> {
  const AnimalEquality();

  // ...
}
```

**OK**:

```dart
class Animal implements Comparable<Animal> {
  @override
  int compareTo(Animal a, Animal b) => doCompare();
}
```

## Keep `toString` terse if `assertionsEnabled` is `false`

Developer prefer to see explained, actionable, and comprehensive error and
`toString()` messaging when developing an application. Nothing is worse than
getting an exception that says `"change detection failed"`.

However, just like `hashCode` and `operator==`, practically every `toString()`
method is _not_ tree-shaken from a typical application. If there is value to a
more verbose message for developers, use `assertionsEnabled()`:

**BAD**:

```dart
class Animal {
  String name;

  @override
  String toString() => 'An animal named $name.';
}
```

**OK**:

```dart
class Animal {
  String name;

  @override
  String toString() {
    if (assertionsEnabled()) {
      return 'An animal named $name.';
    }
    return super.toString();
  }
}
```

## Use _identity_ not _equality_ where possible

Using the standard `==` operator, or `new Map` (same as `{}`), or `new Set`
makes potentially expensive deep equality and hashcode operations. Sometimes
developers don't even know the objects they are passing around implement these
operators (such as generated protocol buffers).

It's _OK_ to use `==` or the standard collections if carefully documented.

**BAD**:

```dart
if (previousValue != newValue) {
  // ...
}
```

**BAD**:

```dart
final visited = new Set();

void visit(element) {
  if (visited.add(element)) { /* ... */ }
}
```

**OK**:

```dart
if (!identical(previousValue, newValue)) {
  // ...
}
```

**OK**:

```dart
final visited = new Set.identity();

void visit(element) {
  if (visited.add(element)) { /* ... */ }
}
```
