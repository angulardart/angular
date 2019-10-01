# Change Detection


Change detection is the performance bottleneck in most Angular apps. A component
with problematic change detection bindings can cause the entire app to slow to a
crawl. This best practices document will show you how to write components and
templates that maximize the performance of your app.

## Templates

### AVOID expensive bindings

Change detection is run on every tick for every component in the app. One
expensive template binding can bring the entire app to a crawl. Performing
expensive computations in your template bindings is always a bad idea.

**BAD**:

```html {.bad}
<child-component [input]="myExpensiveMethod()"></child-component>
```

Instead, make sure to always make template binding expressions fields or fast
getters. This will cause Angular to spend less time performing change detection
on your app.

**GOOD**:

```html {.good}
<child-component [input]="myField"></child-component>
```

### DO use final fields where possible

The Angular compiler has the ability to detect when a template binding
expression is a final field on the component class and avoid change detection
altogether in this case.

**BAD**:

```dart {.bad}
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

```dart {.good}
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

```dart {.bad}
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

```dart {.good}
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

```dart {.bad}
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

```dart {.good}
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

### AVOID using getters to generate function objects for the template

This is bad for performance, as Angular calls the getter during change detection
, which creates a new function object giving Angular illusion that the field has
been changed. In fact, this will become a runtime error in dev mode soon.

**BAD**

```dart
@Component(
  selector: 'foo',
  template: '<bar [foo]="fooName"></bar>',
)
class Foo {
  ItemRenderer get fooName => (foo) => foo.name;
}
```

**GOOD**

```dart
@Component(
  selector: 'foo',
  template: '<bar [foo]="fooName"></bar>'
)
class Foo {
  static final String fooName(foo) => foo.name;
}
```

### PREFER using the template to update children

Whenever possible, update children through the template. This allows Angular to
track changes to components and update them accordingly.

**BAD**

```dart
@Component(
  selector: 'expansion-panel',
  template: '''
    <ng-container *ngIf="isExpanded">
      <ng-content></ng-content>
    </ng-container>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExpansionPanelComponent {
  @Input()
  var isExpanded = false;
}

@Component(
  selector: 'parent',
  template: '''
    <expansion-panel>
      <div>Hello!</div>
    </expansion-panel>
  ''',
  directives: [ExpansionPanelComponent],
)
class ExampleComponent {
  @ViewChild(ExpansionPanelComponent)
  ExpansionPanelComponent expansionPanel;

  void expand() {
    expansionPanel.isExpanded = true;
  }
}
```

This example doesn't even work, because Angular can't see the change to
`isExpanded` and thus won't update `ExpansionPanelComponent` which uses
`ChangeDetectionStrategy.OnPush`.

**GOOD**

```dart
@Component(
  selector: 'expansion-panel',
  template: '''
    <ng-container *ngIf="isExpanded">
      <ng-content></ng-content>
    </ng-container>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExpansionPanelComponent {
  @Input()
  var isExpanded = false;
}

@Component(
  selector: 'parent',
  template: '''
    <expansion-panel [isExpanded]="isExpanded">
      <div>Hello!</div>
    </expansion-panel>
  ''',
  directives: [ExpansionPanelComponent],
)
class ExampleComponent {
  var isExpanded = false;

  void expand() {
    isExpanded = true;
  }
}
```

Angular can now observe the change to `isExpanded` and will update
`ExpansionPanelComponent` accordingly.

## Components

### AVOID order-dependent input setters

Several mentions were made above to "optimizations" the Angular compiler can
make on components. Many of these optimizations will change the order in which
the inputs on your component are set. For instance, the optimization on final
fields that forgoes change detection will cause inputs set to final fields to be
set before the other inputs on the component. Remember: the inputs on your
component can be set in **any order**.

**BAD**:

```dart {.bad}
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

```dart {.good}
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

### AVOID any asynchronous actions in `ngDoCheck`

The `DoCheck` interface and `ngDoCheck` lifecycle event may be used to disable
generated change detectors, and instead allow the component to determine state.
For example, `NgFor` uses the `DoCheck` interface to trigger updates when the
_contents_ of the passed `Iterable` or `List` changes, not just the identity.

However, `ngDoCheck` is _not_ meant to _process_ the changes, only determine
them. Adding asynchronous events (including implicitly, by making the method
`async`) may cause an infinite loop in your application.

**BAD**:

```dart {.bad}
@Component()
class MyComponent implements DoCheck {
  @override
  void ngDoCheck() async {
    // This may crash your app.
  }
}
```

**BAD**:

```dart {.bad}
@Component()
class MyComponent implements DoCheck {
  @override
  void ngDoCheck() {
    // Any of these may still cause async side-effects, crashing your app.
    scheduleMicrotask(() { ... });
    Timer.run(() { ... });
    someFunctionThatUsesAsync();
  }
}
```

To be safe, strictly make synchronous side-effect free checks in `ngDoCheck`:

**GOOD**:

```dart {.good}
@Component()
class MyComponent implements DoCheck {
  @Input()
  List<String> names;
  String _firstName;
  bool _firstNameUpdated = false;

  @override
  void ngDoCheck() {
    _firstNameUpdated = _firstName == names.first;
  }
}
```

You can always use the `AfterChanges` event to process changes/do async things:

**GOOD**:

```dart {.good}
@Component()
class MyComponent implements AfterChanges {
  @Input()
  String name;

  void ngAfterChanges() async {
    await fetchUserDetails(name);
  }
}
```

Remember, `DoCheck` is _meant_ to be verbose, It is for the rare(r) cases where the default change detection strategy (identity-based) is not appropriate for a component, and you'd like to implement change detection _yourself_.

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

```dart {.bad}
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

```dart {.good}
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
should consider using `ngAfterChanges` and checking just the few inputs you care
about. The trade-off you are making is that you have to write your own change
detection code for the few inputs you care about, but you are avoiding creating
a Map in the change detection loop and adding entries for every input that
changed, even if you don't care about them.

### PREFER setters to `ngAfterXChecked`

While it is possible to use `AfterViewChecked` and `AfterContentChecked` to be
updated when a `@ViewChildren`, `@ContentChildren`, `@ViewChild`, or
`@ContentChild`-annotated value has been updated, these methods are _always_
invoked, regardless if the queries have _actually_ changed.

**BAD**:

```dart {.bad}
class MyComponent implements AfterViewChecked {
  @ViewChildren(ChildDirective)
  List<ChildDirective> children;

  @override
  void ngAfterViewChecked() {
    for (final child in children) {
      // ...
    }
  }
}
```

**GOOD**:

```dart {.good}
class MyComponent {
  @ViewChildren(ChildDirective)
  set children(List<ChildDirective> children) {
    for (final child in children) {
      // ...
    }
  }
}
```

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

```dart {.bad}
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

```dart {.good}
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
inputs has changed or event handlers has been triggered. Angular supports this
use case with `ChangeDetectionStrategy.OnPush`. There are some considerations to
make before just switching to `OnPush`, however.

**GOOD**:

```dart {.good}
@Component(
  selector: 'my-component',
  template: '''
    <div>{{message}}</div>
    <button (click)="flipGreeting()">Click me!</button>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class MyComponent {
  @Input()
  var name = 'world';
  var _isArriving = true;

  String get message => _isArriving ? 'Hello, $name!' : 'Goodbye, $name!';

  void flipGreeting() {
    _isArriving = !_isArriving;
  }
}
```

The above component only needs to run change detection when the `name` changes
or the button is clicked, so it's a perfect candidate for using `OnPush`. It
won't waste cycles running change detection when it knows the name field hasn't
changed or the button hasn't been clicked.

But what if an injected service or subscription could change the component? In
that case, you can inject a `ChangeDetectorRef` and call `markForCheck()` to
manually mark the component to be checked in the next change detection cycle.

**IMPORTANT NOTE**: It is a misconception that one should use
`ChangeDetectorRef#detectChanges()` to do manual change detection. Please note
that `detectChanges()` **will not work** with `OnPush` components. The correct
way is to call `markForCheck()`.

**GOOD**:

```dart {.good}
@Component(
  selector: 'my-component',
  template: '<div>{{message}}</div',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class MyComponent implements OnInit {
  MyComponent(this._changeDetectorRef, this._service);

  final ChangeDetectorRef _changeDetectorRef;
  final MyService _service;

  String _message = '';
  String get message => _message;

  @override
  void ngOnInit() {
    _service.fetchMessage().then((value) {
      _message = value;
      _changeDetectorRef.markForCheck();
    });
  }
}
```

To learn more, see the [OnPush change detection][on-push-docs] guide.

### Prefer `NgZone.runAfterChangesObserved` to timers or microtasks

It is sometimes seemingly necessary to _wait_ an arbtitrary amount of time for
change detection to be executed before executing other dependent code. **This is
sometimes a sign of another bug or design flaw** in an app model.

To make it more clear the code you are using might have any issue, and the
microtasks and/or timers are not an explicit part of your design, use the method
`runAfterChangesObserved` by injecting `NgZone`.

**BAD**: Using `scheduleMicrotask`.

```dart {.bad}
class MyComponent {
  var someField = false;
  void someFunction() {
    someField = true;
    scheduleMicrotask(() {
      // Observe some side-effect of "someField" being true.
    });
  }
}
```

**BAD**: Using `Timer.run` (or any other `Timer` or `Future` method).

```dart {.bad}
class MyComponent {
  var someField = false;
  void someFunction() {
    someField = true;
    Timer.run(() {
      // Observe some side-effect of "someField" being true.
    });
  }
}
```

**GOOD**: Using `NgZone#runAfterChangesObserved`.

```dart {.good}
class MyComponent {
  final NgZone _ngZone;
  MyComponent(this._ngZone);
  var someField = false;
  void someFunction() {
    someField = true;
    // TODO(...bug...): This should not be necessary.
    _ngZone.runAfterChangesObserved(() {
      // Observe some side-effect of "someField" being true.
    });
  }
}
```

As an added bonus, the AngularDart team and other knowledgeable folks will be
much better prepared to help diagnose bugs or issues when they see this method
being used than arbitrary timing.

[on-push-docs]: https://github.com/dart-lang/angular/blob/master/doc/advanced/on-push.md

