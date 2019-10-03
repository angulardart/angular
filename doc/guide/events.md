# Custom Events with `@Output`


A `@Directive` or `@Component` may define _custom_ events, or _outputs_, that
may be observed using the [event listening syntax][cheat-sheet] (similar to
native DOM events). Outputs are the recommended way to propagate most data
upwards, and automatically handle change detection and more.

[cheat-sheet]: ../cheat-sheet.md#template-syntax

## Defining an `@Output`

AngularDart uses Dart's [`Stream`][dart-streams] interface to emit events:

```dart
class OkCancelPanel {
  /// Fires an event when the user presses a button in the panel.
  @Output()
  Stream<OkCancelState> get onPressed => throw UnimplementedError('TODO');
}
```

[dart-streams]: https://www.dartlang.org/tutorials/language/streams

To implement a `Stream`, you would normally use a `StreamController`, which
builds a `Stream` for you and allows you to continuously add new events to the
stream:

```dart
import 'dart:async';

import 'package:angular/angular.dart';

@Component(
  selector: 'ok-cancel-panel',
  template: '''
    <button (click)="onOk">OK</button>
    <button (click)="onCancel">Cancel</button>
  ''',
)
class OkCancelPanel {
  final _onPressed = StreamController<OkCancelState>.broadcast();

  void onOk() {
    _onPressed.add(OkCancelState.ok);
  }

  void onCancel() {
    _onPressed.add(OkCancelState.cancel);
  }

  @Output()
  Stream<OkCancelState> get onPressed => _onPressed.stream;
}

enum OkCancelState {
  ok,
  cancel,
}
```

Using `OkCancelPanel` is quite simple:

```dart
@Component(
  selector: 'example-view',
  directives: [
    OkCancelButton,
  ],
  template: '''
    <ok-cancel-button (onPressed)="onPressed"></ok-cancel-button>
  ''',
)
class ExampleView {
  void onPressed(OkCancelState state) {
    // TODO: Implement.
  }
}
```

## FAQ

### Only create broadcast Streams

While not obvious, `StreamController<Type>.broadcast()` should **always** be
used over the default constructor (`StreamController<Type>()`). A non-broadcast
stream is meant to be used for I/O purposes, and has several contracts that are
either incompatible or can cause serious issues within AngularDart:

*   All events are buffered until the first subscriber (e.g. can leak memory).
*   Only a single subscriber is ever allowed (can prevent dynamic loading).

Future versions of AngularDart may refuse to execute code that uses anything but
a broadcast Stream to implement `@Output`.

### Avoid synchronous Streams

AngularDart assumes (and in many cases, requires) that all events occur
asynchronously (as part of our unidirectional data flow architecture). Using a
`StreamController.broadcast(sync: true)` stream may bypass this expectation,
which in turn can cause undefined behavior or runtime exceptions.

It _is_ possible to correctly use a synchronous `StreamController` as a "bridge"
to convert an already asynchronous event or callback into a `Stream`, but this
is quite advanced and an unnecessary optimization for most components:

```dart
@JS()
library advanced;

import 'package:angular/angular.dart';
import 'package:js/js.dart';

/// An example of a JavaScript callback that is invoked asynchronously.
@JS()
external void registerCallback(void Function(String) callWithName);

@JS()
external void removeCallback(void Function(String) callWithName);


@Component(
  selector: 'example-bridge',
  template: '',
)
class ExampleBridge {
  StreamController<String> _onName;

  @Output()
  Stream<String> get onName {
    if (_onName == null) {
      final onCallback = allowInterop((String name) {
        _onName.add(name);
      });
      _onName ??= StreamController<String>.broadcast(
        sync: true,
        onListen: () {
          registerCallback(onCallback);
        },
        onCancel: () {
          removeCallback(onCallback);
        },
      );
    }
    return _onName.stream;
  }
}
```

### Avoid closing StreamController

AngularDart (or Dart) does _not_ require you use the `ngOnDestroy()` or other
methods to `.close()` the underlying `StreamController`. When all listeners have
unsubscribed, the `StreamController` is automatically garbage collected by the
browser and does not require any developer intervention.
