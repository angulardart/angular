# AngularDart Internal Style Guide


Below is a non-authoritative style guide for building
low-overhead/high-performance Dart applications, specifically when compiled to
Dart2JS. The AngularDart team follows these _additional_ restrictions on top of
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
  int compareTo(Animal other) => doCompare();
}
```

## Keep `toString` terse if `assertionsEnabled` is `false`

Developers prefer to see explained, actionable, and comprehensive error and
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
final visited = Set.identity();

void visit(element) {
  if (visited.add(element)) { /* ... */ }
}
```

## Use a traditional `for` loop over `for-in` and methods on `List` types

While nicer to look at, a `for (var x in items)` and `items.forEach(...)`
performs worse, and allocates more memory in both Dart2JS and DDC than using a
traditional `for` loop when the type of `items` has efficient length and
operator `[]` access (for example, a `List`).

**BAD**:

```dart
void checkProviders(List<Provider> providers) {
  for (var provider in providers) {
    _doCheck(provider);
  }
}
```

**BAD**:

```dart
void checkProviders(List<Provider> providers) {
  providers.forEach(_doCheck);
}
```

**OK**:

```dart
void checkProviders(List<Provider> providers) {
  for (var i = 0, l = providers.length; i < l; i++) {
    _doCheck(providers[i]);
  }
}
```

**OK**:

```dart
// OK: We don't know if providers is a List (might be a lazy Iterable).
void checkProviders(Iterable<Provider> providers) {
  for (var provider in providers) {
    _doCheck(provider);
  }
}
```

## Always _cast_ a `dynamic` or `Function` to a concrete type before using

In JIT-environments (like the standalone VM), dynamically invoked code can be
optimized into better performing "hot" code, particularly when the methods are
invoked monomorphically.

However, in AOT-environments (like Dart2JS or DDC), these optimizations are not
possible (though Dart2JS tries with global type inference) - and Dart's calling
conventions are too different from JavaScript to rely on JavaScript VM's to
optimize in all cases.

**BAD**:

```dart
void printName(/*dynamic*/ person) => print(person.name);
```

**BAD**:

```dart
void printLazyString(/*dynamic*/ getString) => print(getString());
```

```dart
void printLazyString(Function getString) => print(getString());
```

**OK**:

```dart
void printName(Person person) => print(person.name);
```

```dart
void printName(Object personOrPlace) {
  if (personOrPlace is Person) {
    print(personOrPlace.name);
  } else {
    print((personOrPlace as Place).name);
  }
}
```

**OK**:

```dart
void printLazyString(String Function() getString) => print(getString());
```

## Never access `.runtimeType`

Dart implements [reified types][what_are_reified_types], known in some languages
as RTTI, or run-time type information. Optimizing compilers like Dart2JS try to
eliminate RTTI when they can definitively tell retaining the type is not
significant to the program.

[what_are_reified_types]: http://beust.com/weblog/2011/07/29/erasure-vs-reification/

Howevever `.runtimeType`, especially on bottom types like `Object`, can cause
_all_ reified types to need to be retained to implement Dart semantics. In
Dart2JS's production mode all symbols are minified, so this information is not
too useful anyway.

**NOTE**: It also should **not** be used in `assertionsEnabled()`. As of
2017/10/12, Dart2JS determines what types are "active" in the program before
stripping out assertions.

**BAD**:

```dart
void findJob(Person person) {
  if (person.jobs.isEmpty) {
    throw 'UNSUPPORTED: ${person.runtimeType} does not have "jobs".';
  }
}
```

**BAD**:

```dart
void findJob(Person person) {
  if (person.jobs.isEmpty && assertionsEnabled()) {
    throw 'UNSUPPORTED: ${person.runtimeType} does not have "jobs".';
  }
}
```

**OK**:

```dart
void findJob(Person person) {
  if (person.jobs.isEmpty) {
    throw 'UNSUPPORTED.';
  }
}
```

_NOTE_, there is _also_ a (smaller) cost to using a class's own reified generics
at runtime, so it should be kept to an absolute minimum. Consider the following:

```dart
class Container<T> {
  Type get type => T;
}

void main() {
  var a = Container<String>();
  print(a.type);
}
```

Unless the `Type` is important to the production mode of the application,
consider adopting a different pattern or only supporting this feature in
development mode.

## Do not use the built-in `enum` type

It adds extra overhead on top of constant strings or integers that don't help
much for framework-internal code (nobody will use `switch`, for example).

## Do not use `async`, `async*`, `sync*`, or `await`

... unless absolutely necessary (i.e. there is no way to write similar code
using Futures/Streams/Iterables, or the code is extremely verbose and error
prone). All of these keywords generate complex state machines with entire
branches going unused in production code.

## Do not use `.cast`

The code behind `.cast` creates a forwarding wrapper (based on `sync*` and
`async*` in many cases) that adds a lot of overhead. It is preferrable to either
fix the typing _or_ use an alternative pattern to get the typing required.

## Avoid multiple returns when inlining of a method is desirable

See https://github.com/dart-lang/sdk/issues/35728, but Dart2JS is currently
unable to inline in cases where multiple `return` statements are present.

**BAD**:

```dart
import 'package:meta/dart2js.dart' as dart2js;

@dart2js.tryInline
String getLetter(int counter) {
  if (counter == 1) {
    return 'A';
  }
  if (counter == 2) {
    return 'B';
  }
  return null;
}
```

**OK**: Using a ternary statement to avoid multiple `return`s.

```dart
import 'package:meta/dart2js.dart' as dart2js;

@dart2js.tryInline
String getLetter(int counter) {
  return counter == 1 ? 'A' : counter == 2 ? 'B' : null;
}
```

**OK**: Using a `result` value.

```dart
import 'package:meta/dart2js.dart' as dart2js;

@dart2js.tryInline
String getLetter(int counter) {
  String result;
  if (counter == 1) {
    result = 'A';
  } else if (counter == 2) {
    result = 'B';
  }
  return result;
}
```
