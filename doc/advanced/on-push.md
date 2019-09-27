# OnPush Change Detection


WARNING: This document is still a work in progress and subject to change.

## Terminology

*   __Default component__: A component that uses
    `ChangeDetectionStrategy.Default`.

    ```dart
    @Component(
      selector: 'example',
      template: 'example_component.html',
    )
    class ExampleComponent {}
    ```

*   __OnPush component__: A component that uses
    `ChangeDetectionStrategy.OnPush`.

    ```dart
    @Component(
      selector: 'example',
      template: 'example_component.html',
      changeDetection: ChangeDetectionStrategy.OnPush,
    )
    class ExampleComponent {}
    ```

## Why use it?

By default, change detection reevaluates every bound expression in every
component on each pass. This is the magic that keeps your data and view in sync,
but it isn't without cost. As the size of your application grows, default change
detection may begin to negatively impact performance. Any asynchronous activity
requires checking your entire app for changes; this doesn't scale well.

OnPush change detection reduces unnecessary work by only checking components
that may have changes. It offers better performance than default change
detection, but requires more thoughtful state management on behalf of the
developer.

TIP: Use OnPush from the start when developing large apps or views.

Because default change detection checks everything, there's no requirement to
track how state propagates through your app. This can unknowingly encourage
patterns that are incompatible with OnPush, making a later migration to OnPush
challenging. It's advised to start with OnPush when developing an app or view
that is expected to be large or performance-sensitive.

## How it works

Coming soon...

## Compatibility with Default change detection

Mixing Default and OnPush components in the same app is supported so long as the
following rule is observed:

IMPORTANT: A Default component should never be used in the template of an OnPush
component.

In other words, the descendants of an OnPush component should also be OnPush.
The compiler warns when this rule is violated. The same rule also applies for
imperatively loaded components, with one important caveat for [component
reuse](#component-reuse). Unfortunately, this case isn't enforced by the
compiler.

NOTE: A Default component can be projected into an OnPush component with
`<ng-content>`.

## Sharing state

**BAD**:

Avoid deeply mutable state that can be changed externally without notice.

```dart {.bad}
class MutableModel {
  String label;
}

@Component(
  selector: 'example',
  template: '''
    <div>{{model.label}}</div>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExampleComponent {
  @Input()
  MutableModel model;
}
```

**GOOD**:

Use a deeply immutable model. Changing any state requires rebuilding the entire
model. This works well with inputs, which are change detected based on identity.
Prefer this approach when state is shared locally, such as directly between a
parent and child.

```dart {.good}
class ImmutableModel {
  ImmutableModel(this.label);

  final String label;
}


@Component(
  selector: 'example',
  template: '''
    <div>{{model.label}}</div>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExampleComponent {
  @Input()
  ImmutableModel model;
}
```

**GOOD**:

Use an observable mutable model. Prefer this approach when state is shared
non-locally, such as between disjoint subtrees or across multiple generations.

```dart {.good}
class ObservableModel {
  final _onChange = StreamController<void>.broadcast();

  Stream<void> get onChange => _onChange.stream;

  String _label;
  String get label => _label;
  set label(String value) {
    if (!identical(value, _label)) {
      _label = value;
      _onChange.add(null);
    }
  }
}

@Component(
  selector: 'example',
  template: '''
    <div>{{model.label}}</div>
  ''',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExampleComponent implements OnInit, OnDestroy {
  ExampleComponent(this.model, this._changeDetectorRef);

  final ObservableModel model;
  final ChangeDetectorRef _changeDetectorRef;

  StreamSubscription<void> _modelChangeSubscription;

  @override
  void ngOnInit() {
    _modelChangeSubscription = model.onChange.listen((_) {
      _changeDetectorRef.markForCheck();
    });
  }

  @override
  void ngOnDestroy() {
    _modelChangeSubscription.cancel();
  }
}
```

## Imperative updates

Coming soon...

## Component reuse

The hierarchical requirements described
[above](#compatibility-with-default-change-detection) pose a challenge for
component reuse.

If a component is to be used in an OnPush context, it must also be OnPush. This
in itself is fine, but becomes problematic if such a component takes a
`ComponentFactory` as input to render children.

In order to not violate the aforementioned requirements, the `ComponentFactory`
would be expected to create an OnPush component. However, it's undesirable to
force this requirement on users of a shared component whose own components may
entirely use Default change detection.

How to use `@changeDetectionLink` coming soon...
