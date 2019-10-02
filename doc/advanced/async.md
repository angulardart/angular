# Async Updates


In most apps and components, it is not necessary to precisely know how
asynchronous events, as propagated through events, callbacks,
[`Future`s][futures], or [`Stream`s][streams] interact with AngularDart, as they
are handled automatically.

[futures]: https://www.dartlang.org/tutorials/language/futures
[streams]: https://www.dartlang.org/tutorials/language/streams

WARNING: The advice and recommendations in this article pertain to users of
_default_ change detection. Components that use `ChangeDetectionStrategy.OnPush`
should inject `ChangeDetectorRef` and call `markForCheck()` as a signal whenever
necessary.

In _some_ cases, you may want to inject [`NgZone`][ng-zone] (as a constructor
parameter) to control how AngularDart uses [zones][zones] to observe your
application. This can help with bugs such as _I updated my state, but my DOM
does not update until X happens_.

[ng-zone]: https://webdev.dartlang.org/api/angular/angular/NgZone-class
[zones]: https://www.dartlang.org/articles/libraries/zones

## Making Angular aware of async callbacks

When using [`Future`][futures], [`Stream`][streams], or event bindings in
templates, Angular is automatically aware when an event completes and will use
that as a signal to rerun change detection. In some cases, though, you may have
code that uses callbacks or JS-interop that is not aware of zones.

**NOTE**: Angular is not aware of DOM events, but reenters the Angular zone
automatically when handling them in templates. DOM event listeners registered in
Dart code must manually reenter the zone to trigger change detection as
demonstrated below.

Imagine you have the following code, perhaps in another shared library:

```dart
class AsyncNotifier {
  final _listeners = <void Function()>[];

  void registerListener(void Function() listener) {
    _listeners.add(listener);
  }

  void notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }
}
```

When using it inside an AngularDart component or service, this code does not
respect [Zone][zones] semantics, and AngularDart might not be aware of when
`notifyListeners` was invoked:

```dart
import 'package:angular/angular.dart';

@Component(
  selector: 'notify-listener',
  template: 'I was notified {{count}} times',
)
class NotifyListener {
  var count = 0;

  @Input()
  set notifier(AsyncNotifier notifier) {
    notifier.registerListener(() {
      count++;
      print('New count is $count');
    });
  }
}
```

For example, you might see `New count is 1` in your development console but in
the DOM observe `I was notified 0 times`. In cases like this, you want to ensure
your callback executes within the Angular observed zone, and you can use
`<NgZone>.run`:

```dart
import 'package:angular/angular.dart';

@Component(
  selector: 'notify-listener',
  template: 'I was notified {{count}} times',
)
class NotifyListener {
  final NgZone _ngZone;

  NotifyListener(this._ngZone);

  var count = 0;

  @Input()
  set notifier(AsyncNotifier notifier) {
    notifier.registerListener(() {
      _ngZone.run(() {
        count++;
        print('New count is $count');
      });
    });
  }
}
```

You should now see the DOM and the development console updated. This pattern is
also useful for JS-interop or any other library or API that involves registering
callbacks/closures that might not be aware of Angular.

**NOTE**: If you are using `ChangeDetectionStrategy.OnPush`, don't forget to
inject and use `<ChangeDetectorRef>.markForCheck` when reentering the `NgZone`:

```dart
import 'package:angular/angular.dart';

@Component(
  selector: 'notify-listener',
  template: 'I was notified {{count}} times',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class NotifyListener {
  final ChangeDetectorRef _changeDetector;
  final NgZone _ngZone;

  NotifyListener(this._changeDetector, this._ngZone);

  var count = 0;

  @Input()
  set notifier(AsyncNotifier notifier) {
    notifier.registerListener(() {
      _ngZone.run(() {
        count++;
        print('New count is $count');
        _changeDetector.markForCheck();
      });
    });
  }
}
```

## Ignoring or filtering async callbacks

In some cases, events might be fired at a high frequency that would negatively
effect performance if Angular reacted to each of them, and you want to
completely (or selectively) ignore events:

```dart
import 'dart:html';

import 'package:angular/angular.dart';

@Component(
  selector: 'custom-painter',
  template: '...',
)
class CustomPainter implements OnInit {
  final HtmlElement _element;

  CustomPainter(this._element);

  @override
  void ngOnInit() {
    _element.onMouseMove.listen((_) {
      // Do something
    });
  }
}
```

While this code works, _every time_ `.onMouseMove` fires AngularDart will
trigger an update (unless you are using `ChangeDetectionStrategy.OnPush`), so
you may use `<NgZone>.runOutsideAngular` to ignore these events:

```dart
import 'dart:html';

import 'package:angular/angular.dart';

@Component(
  selector: 'custom-painter',
  template: '...',
)
class CustomPainter implements OnInit {
  final HtmlElement _element;
  final NgZone _ngZone;

  CustomPainter(this._element, this._ngZone);

  @override
  void ngOnInit() {
    _ngZone.runOutsideAngular(() {
      _element.onMouseMove.listen((_) {
        // Do something
      });
    });
  }
}
```

You can combine with `<NgZone>.run` to selectively re-enter Angular:

```dart
@Component(
  selector: 'custom-painter',
  template: '...',
)
class CustomPainter implements OnInit {
  final HtmlElement _element;
  final NgZone _ngZone;

  CustomPainter(this._element, this._ngZone);

  @override
  void ngOnInit() {
    _ngZone.runOutsideAngular(() {
      _element.onMouseMove.listen((event) {
        if (event.clientX > 500) {
          _ngZone.run(() {
            // Do something
          });
        }
      });
    });
  }
}
```

## Waiting for state to propagate

You may run into scenarios where you want to wait for change detection to be
executed before continuing, and can use `<NgZone>.runAfterChangesObserved`:

```dart
import 'dart:html';

import 'package:angular/angular.dart';

@Component(
  selector: 'example-state',
  template: r'''
    <div [style.height]="height" #someDiv></div>
  ''',
)
class Example {
  final NgZone _ngZone;

  Example(this._ngZone);

  int height = 100;

  @ViewChild('someDiv')
  set someDiv(HtmlElement someDiv) {
    if (someCondition) {
      height = 200;
      _ngZone.runAfterChangesObserved(() {
        checkDimensionsOf(someDiv);
      });
    }
  }
}
```

**NOTE**: It might be tempting to use `scheduleMicrotask`, `await null`,
`Timer.run`, or other more nefarious API surfaces like
`<ChangeDetectorRef>.detectChanges()` to accomplish this, but resist the
temptation as these methods have negative implications for performance and
stability. See also [`Prefer NgZone.runAfterChangesObserved`][prefer] for
details.

[prefer]: ../effective/change-detection.md?#prefer-ngzonerunafterchangesobserved-to-timers-or-microtasks
