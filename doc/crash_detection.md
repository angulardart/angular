# Crash Safety for AngularDart

[TOC]


## Overview

The following bit of code causes infinite work to be scheduled in an application:


```dart
@Component(
  selector: 'root',
  template: r'''
    <first></first>
    <second></second>
  ''',
  directives: const [FirstComponent, SecondComponent,],
)
class RootComponent {}

@Component(
  selector: 'first',
  template: 'First',
)
class FirstComponent implements OnInit {
  @override
  void ngOnInit() {
    scheduleMicrotask(() {
      print('ngOnInit in $FirstComponent is being called. What if I was an RPC?');
    });
  }
}

@Component(
  selector: 'second',
  template: 'Hello Second: {{firstVariable}}',
)
class SecondComponent {
  List<int> variables;

  int get firstVariable => variables.first; // NPE, which causes CD to fail.
}
```


This is due to the way the change detection traversal happens:

![drawing](https://user-images.githubusercontent.com/168174/27608333-f7a36566-5b3b-11e7-92b4-a0f8daf93249.png)

In order to prevent this in production, we *could* wrap every change detection
call in a `try { … } catch { … }` but this means the overhead of generating
those calls (when most of the time they do not catch anything) - and it means
that V8 may not be able to inline or optimize the function bodies, causing
performance regressions - specifically in large applications:


```dart
// Imagine this code generated everywhere ngOnInit is used in a child component.
void detectChanges() {
  try {
    child3.ngOnInit();
  } catch (e) {
    setCrashed(comp0);
    rethrow;
  }
  try {
    child4.ngOnInit();
  } catch (e) {
    setCrashed(comp1);
    rethrow;
  }
}
```


In **dev-mode** today (i.e. not deployed to production), we retain a
*ChangeDetectionState* enum of *Errored*, which is assigned when something like
this happens, to disable change detection for subsequent invocation. *However*,
this is not what is deployed (see performance implications above):


```dart
void detectChanges() {
  _resetDebug();
  try {
    super.detectChanges();
  } catch (e) {
    if (e is! ExpressionChangedAfterItHasBeenCheckedException) {
      cdState = ChangeDetectorState.Errored;
    }
    rethrow;
  }
}
```



## Design

We can make a small modification to Angular, for production usage as well, that
will allow catastrophic failures to be caught, and badly behaving components to
be disabled, not causing infinite loops or other damage. We'll introduce a new
global state, *lastGuardedView*, which will default to *null*:


```dart
class ApplicationRef {
  /// This is ~ the root detectChanges call.
  void tick() {
    try {
      _tick();
    } catch (_) {
      lastGuardedView = topLevelView;
      _tick();
    } finally {
      // Exit slow/guarded mode.
    lastGuardedView = null;
  }
}
```



```dart
@visibleForTesting
AppView? lastGuardedView;

void detectChanges() {
  if (lastGuardedView != null) {
    // Run slow-mode CD.
    _detectCrash();
    return;
  }
  // Run fast-mode CD (existing impl).
  detectChangesInternal();
}

void _detectCrash() {
   try {
    detectChangesInternal();
  } catch (e, s) {
    lastGuardedView = this;
    // Store the exception and stack so we can log to ExceptionHandler.
    caughtException = e;
    caughtStack = s;
  }
}
```
