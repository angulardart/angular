`QueryList` is currently soft deprecated (will be formerly deprecated soon).

Bug: https://github.com/dart-lang/angular/issues/688

This API was more aspirational than functional and provided an `Iterable<T>`
interface with a `Stream<Iterable<T>> get changes` additional field that fired
whenever the contents of the iterable changed. This led to APIs like the
following:

```dart
@Component(
  selector: 'comp',
  template: '<child></child><child></child>',
  directives: const [Child],
)
class Comp {
  @ViewChildren(Child)
  QueryList<Child> children;
}
```

Or to observe changes:

```dart
class Comp {
  set children(QueryList<Child> children) {
    // Initial values.
    _onChange(children);

    // Subsequent values.
    children.changes.listen((_) => _onChange(children));
  }

  void _onChange(Iterable<Child> children) {
    // ...
  }
}
```

Or to observe changes using a lifecycle hook instead:

```dart
class Comp implements AfterViewInit {
  @ViewChildren(Child)
  QueryList<Child> children;

  @override
  void ngAfterViewInit() {
    // Initial values.
    _onChange(children);

    // Subsequent values.
    children.changes.listen((_) => _onChange(children));
  }

  void _onChange(Iterable<Child> children) {
    // ...
  }
}
```

## Strong-mode issues

Unfortunately, `QueryList<T>` is _always_ typed as `QueryList<dynamic>`, an
error that DDC currently ignores, but will not in the near future as they
enable checks for `uses_dynamic_as_bottom` - i.e. right now this is _not_ an
error:

```dart
main() {
  List<String> names;
  List<dynamic> anything = [];
  names = anything;
}
```

The way `QueryList` is implemented, its very difficult to properly type it as
the data is added asynchronously, and type inference in Dart is based on the
construction of the object. One way to get around this would be to support a
new synchronous API - such as just a `List<T>`.

## Migration guide

AngularDart now supports typing a field or setter as a plain `List<T>` instead
of `QueryList<T>`, and uses this typing as a heuristic to run the newer
simplified code branch:

```dart
@Component(
  selector: 'comp',
  template: '<child></child><child></child>',
  directives: const [Child],
)
class Comp {
  @ViewChildren(Child)
  List<Child> children;
}
```

Or to observe changes:

```dart
class Comp {
  set children(List<Child> children) {
    // Initial values *and* subsequent changes.
    _onChange(children);
  }

  void _onChange(Iterable<Child> children) {
    // ...
  }
}
```

Basically, the field (or setter) is now called whenever initial or new values
are present. This is similar to how `@Input`s work and other parts of
AngularDart. The `List<T>` class is also represented as a lightweight `JSArray`
in most cases instead of a heavy wrapped object `QueryList`.
