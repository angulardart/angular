# Effective Angular: Change Detection

> **NOTE**: This is a work-in-progress, and not yet final. Some of the links may
> be substituted with `(...)`, and some TODOs or missing parts may be in the
> documentation.

Change detection is the performance bottleneck in most Angular apps. A component
with problematic change detection bindings can cause the entire app to slow to a
crawl. This best practices document will show you how to write components and
templates that maximize the performance of your app.

*   [Introduction](#introduction)
    * [Overview of change detection](#overview-of-change-detection)
    * [Change detection of a single component](#change-detection-of-a-single-component)
    * ["Expression has changed after it was checked" error](#expression-has-changed-after-it-was-checked-error)
*   [Templates](#templates)
    *   [AVOID expensive bindings](#avoid-expensive-bindings)
    *   [DO use final fields where possible](#do-use-final-fields-where-possible)
    *   [DO use `exports` for static bindings](#do-use-exports-for-static-bindings)
    *   [PREFER 0- or 1-argument event handlers](#prefer-0--or-1-argument-event-handlers)
*   [Components](#components)
    *   [AVOID order-dependent input setters](#avoid-order-dependent-input-setters)
    *   [PREFER `ngAfterChanges` to `ngOnChanges`](#prefer-implementing-afterchanges-to-onchanges)
    *   [PREFER `bool` setters to using `getBool`](#prefer-bool-setters-to-using-getbool)
    *   [PREFER using `OnPush` where possible](#prefer-using-onpush-where-possible)

## Introduction

Having a basic understanding of how Angular's change detection works can help
you write your app in such a way to work well with it.

### Overview of change detection

The default change detection strategy in Angular is quite simple. Angular
runs a change detection loop throughout the lifetime of your app.
On each iteration of the loop, Angular performs change detection of the root
element of the component tree. Once every expression in the root element has
been checked, change detection is recursively called for all children of the
element, all the way down to the leaf elements.

### Change detection of a single component

So, we've seen that Angular recursively change detects each component and
directive in the tree, but how is each individual component change detected?

For each component, the Angular Compiler generates a method that detects
changes for each expression in its template. If the expression has changed
since the last check, it will execute code to update the value the expression
is bound to. It's important to remember that components don't change detect
their own inputs, they run change detection on the expressions in their own
template, and will - for example - set an input on a child component only if
the expression it's bound to has changed.

For example, given a component with the following template:

```html
<div>{{message}}</div>
<child-component [input]="someExpression"></child-component>
```

The Angular Compiler will generate a change detection method for this
component that checks two things: `message` and `someExpression` on every
change detection loop.

**IMPORTANT NOTE**: An expression has "changed" if its value in this iteration
is not `identical` to its previous value. This means that it's possible for an
expression to change, and not have that change reflected in Angular. This is
common with collection types such as `List` because when you change the
elements of the list, it is still `identical` because it is the same `List`
instance. If you want to reflect a change in a collection type, you must pass
a new collection instance.

### "Expression has changed after it was checked" error

As we have seen, every expression in every template is checked in each change
detection loop, and code is run to update bindings only if the expression has
changed since the last change detection loop. Clearly, this can be expensive
for expressions that change on _every_ change detection loop.

To help users guard against this, Angular does additional verification when
an app is built in debug mode. In debug mode, Angular will run change
detection on every component and directive **twice**, and if any expressions
have changed between the first and second run, this is an indication of
misbehaving code. In this case, Angular will throw an exception saying
"Expression has changed after it was checked."

Often, in this case, the expression is a getter that returns a new instance
every time it is accessed. This is very bad behavior for Angular and will
cause this exception to throw. Always make sure that if an expression hasn't
changed it's value, that it stays `identical` to the previous value.

## Templates

### AVOID expensive bindings

Change detection is run on every tick for every component in the app. One 
expensive template binding can bring the entire app to a crawl. Performing
expensive computations in your template bindings is always a bad idea.

**BAD**:

```html
<child-component [input]="myExpensiveMethod()"></child-component>
```

Instead, make sure to always make template binding expressions fields or fast
getters. This will cause Angular to spend less time performing change detection
on your app.

**GOOD**:

```html
<child-component [input]="myField"></child-component>
```

### DO use final fields where possible

The Angular compiler has the ability to detect when a template binding
expression is a final field on the component class and avoid change detection
altogether in this case.

**BAD**:

```dart
@Component(
  selector: 'my-component',
  template: '<h1>{{message}}</h1>',
)
class MyComponent {
  String get message => 'Hello, World!';
}
```

The above example uses a getter where a final field would do. Since Angular
compiler can't tell the `message` getter will always return the same value, it
can't optimize it. However, Angular compiler **can** detect final fields and
optimize.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
  template: '<h1>{{message}}</h1>',
)
class MyComponent {
  final String message = 'Hello, World!';
}
```

### DO use `exports` for static bindings

There are times when you want to bind static data in your template. In older
versions of Angular, the common way to do this was to create a field or getter
on your component class that referenced the static data.

**BAD**:

```dart
const String hello = 'Hello, World!';

@Component(
  selector: 'my-component',
  template: '<h1>{{message}}</h1>'
)
class MyComponent {
  String get message => hello;
}
```

This pattern is now discouraged. To bind static data in your template, you
should use `exports` on your component class. In addition to not having to write
a redundant getter or field in your class, this pattern can be optimized by the
compiler since it knows that every `export` is immutable.

**GOOD**:

```dart
const String hello = 'Hello, World!';

@Component(
  selector: 'my-component',
  exports: const [hello],
  template: '<h1>{{hello}}</h1>'
)
class MyComponent {}
```

### PREFER 0- or 1-argument event handlers

Event handlers with 0 or 1 arguments are so common that they are optimized by
the Angular compiler. However, 1-argument event handlers are only optimized if
their one argument is the special `$event` argument.

**BAD**:

```dart
@Component(
  selector: 'my-component',
  template: '<div (click)="handleClick(false)"'
            '     (dblclick)="handleClick(true)"></div>'
)
class MyComponent {
  void handleClick(bool isDoubleClick) { ... }
}
```

Sometimes it's simple enough to refactor event handlers with arguments into
event handlers without arguments. This will allow the Angular compiler to
generate better code for your component.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
  template: '<div (click)="handleSingleClick()"'
            '     (dblclick)="handleDoubleClick()"></div>'
)
class MyComponent {
  void _handleClick(bool isDoubleClick) { ... }
  void handleSingleClick() => _handleClick(false);
  void handleDoubleClick() => _handleClick(true);
}
```

## Components

### AVOID order-dependent input setters

Several mentions were made above to "optimizations" the Angular compiler can
make on components. Many of these optimizations will change the order in which
the inputs on your component are set. For instance, the optimization on final
fields that forgoes change detection will cause inputs set to final fields to be
set before the other inputs on the component. Remember: the inputs on your
component can be set in **any order**.

**BAD**:

```dart
@Component(
  selector: 'my-component',
)
class MyComponent {

  @Input()
  Model model;

  @Input()
  set foo(String newFoo) {
    model.foo = newFoo; // BAD! Will crash if `model` isn't set
  }
}
```

The example above will crash if the `foo` setter is called before the `model`
input has been set. We need to make the inputs order-independent to avoid the
bug.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
)
class MyComponent {
  Model _model;
  @Input()
  set model(Model newModel) {
    if (_cachedFoo != null) {
      newModel.foo = _cachedFoo;
    }
    _model = newModel;
  }

  String _cachedFoo;
  @Input()
  set foo(String newFoo) {
    _cachedFoo = newFoo;
    _model?.foo = newFoo;
  }
}
```

Unfortunately our "good" example adds a substantial amount of boilerplate in
order to make the inputs order-agnostic. However, this is required because the
inputs are interdependent and either can change at any time.

### PREFER implementing `AfterChanges` to `OnChanges`

Implementing `OnChanges` gives your component the ability to handle multiple
inputs at once. However, the Angular compiler must generate more complex
boilerplate code to handle collecting all of the changed inputs in a change
detection tick for that component. Using `OnChanges` bloats the generated code
_everywhere your component is used_.

Sometimes you need to implement `OnChanges` for your component to have the
desired behavior, but in some cases you don't care how the inputs changed
specifically, you only care that some input has changed. In this case, you
should use the much cheaper `AfterChanges` class.

**BAD**:

```dart
@Component(
  selector: 'my-component',
)
class MyComponent implements OnChanges {
  void ngOnChanges(Map changes) {
    // `changes` is ignored
  }
}
```

The component above ignores the `changes` parameter, but Angular compiler still
generated code to create that parameter. If we don't care about the parameter,
use `AfterChanges`.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
)
class MyComponent implements AfterChanges {
  void ngAfterChanges() {
    // much better!
  }
}
```

Even in cases where you only care about a handful of inputs out of many, you
should consider using `ngAfterChanges` and checking just the few inputs you
care about. The tradeoff you are making is that you have to write your own
change detection code for the few inputs you care about, but you are avoiding
creating a Map in the change detection loop and adding entries for every input
that changed, even if you don't care about them.

### PREFER `bool` setters to using `getBool`

Many components have a boolean flag input that affects its behavior. Authors of
these components would like to give clients a nice API where they can write the
flag directly like this:

```html
<my-component useCoolFlag></my-component>
```

which looks much nicer than

```html
<my-component [useCoolFlag]="true"></my-component>
```

In old versions of Angular, using the former syntax would pass the empty string
to the input setter. The problem is obvious: Strings aren't booleans! To get
around this, authors would coerce the String to a bool and make the input
dynamic.

**BAD**:

```dart
bool getBool(dynamic x) {
  if (x == '') return true;
  if (x is bool) return x;
  throw 'not a bool or empty string!';
}
@Component(
  selector: 'my-component',
)
class MyComponent {
  bool _useCoolFlag = false;
  @Input()
  set useCoolFlag(x) {
    _useCoolFlag = getBool(x);
  }
}
```

This workaround is discouraged in current versions of Angular. Now, if an input
is declared with a `bool` type, the default value will be `true` if no value is
given in the template.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
)
class MyComponent {
  @Input()
  bool useCoolFlag = false;
}
```

### PREFER using `OnPush` where possible

In many cases, components only need change detection run on them if one of their
inputs has changed. Angular supports this use case with
`ChangeDetectionStrategy.OnPush`. There are some considerations to make before
just switching to `OnPush`, however. You cannot use `OnPush` on the root
component of your app. Also, if your component may change due to something other
than a changing input - for instance, an event handler changing your component's
state - then you either shouldn't use `OnPush` or implement change detection
manually (see below for an example).

**GOOD**:

```dart
@Component(
  selector: 'my-component',
  template: '<div>{{message}}</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class MyComponent {
  @Input()
  String message = 'Hello, World!';
}
```

The above component only needs to run change detection when the `message`
changes, so it's a perfect candidate for using `OnPush`. It won't waste cycles
running change detection when it knows the message field hasn't changed. But
what if an event handler could change the component? In that case, you can
inject a `ChangeDetectorRef` and call `markForCheck()` to manually mark the
component to be checked in the next change detection cycle. If you opt for this
approach, you must make sure that `markForCheck()` is called inside the
Angular zone.

**IMPORTANT NOTE**: It is a misconception that one should use
`ChangeDetectorRef#detectChanges()` to do manual change detection. Please note
that `detectChanges()` **will not work** with `OnPush` components. The correct
way is to call `markForCheck()`.

**GOOD**:

```dart
@Component(
  selector: 'my-component',
  template: '<div>{{message}}</div><div (click)="flipGreeting()">Click Me!</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class MyComponent {
  bool greeting = true;
  String get message => greeting ? 'Hello' : 'Goodbye';

  final ChangeDetectorRef _cdRef;
  MyComponent(this._cdRef);

  void flipGreeting() {
    greeting = !greeting;
    _cdRef.markForCheck();
  }
}
```
