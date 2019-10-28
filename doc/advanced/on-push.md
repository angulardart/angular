# OnPush Change Detection


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
but it isn't without cost. As the size of your app grows, default change
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

A change detection pass always begins at the root of an app and attempts to
recursively change detect every component. What happens when visiting a
component during change detection depends on its change detection strategy:

*   A Default component is unconditionally change detected before recursively
    visiting its children.

*   An OnPush component keeps track of whether it needs to be change detected.
    If marked for change detection, change detection proceeds as it would on a
    Default component, then the component is marked as checked. If already
    checked, the component is skipped along with its descendants.

All OnPush components begin marked for change detection. After being checked,
there are three ways an OnPush component can be marked for change detection
again:

1.  The *identity* of an expression bound to one of its inputs has changed since
    it was last checked during change detection. This allows changes to
    propagate down the component hierarchy through inputs.

2.  An event binding in the template of the component or a descendant is
    triggered. Since handling an event is likely to change a component, the
    framework automatically marks the component that bound the event handler and
    its ancestors for change detection.

3.  If, a directive on its host element, or a descendant injects
    `ChangeDetectorRef` and calls `markForCheck()`. This is used to mark a
    component for change detection after handling an asynchronous change.
    Examples include receiving data from the network or a stream subscription.

Note how the first two cases are handled automatically. Developer intervention
is only necessary when applying asynchronous updates that don't originate from
the template. The second case is just a specific instance of the third that the
framework handles automatically because it's compiled from the template.

Also note that calling `markForCheck()` will mark all OnPush components from the
caller to the root for change detection. This is necessary in order for the
caller to be visited during the next change detection pass. Otherwise an OnPush
ancestor could be skipped and the caller wouldn't be reached.

## Compatibility with default change detection

Mixing Default and OnPush components in the same app is supported so long as the
following rule is observed:

IMPORTANT: A Default component should never be used in the template of an OnPush
component.

In other words, the descendants of an OnPush component should also be OnPush.
The compiler warns when this rule is violated. The same rule also applies for
imperatively loaded components, with one important caveat for
[component reuse](#component-reuse). Unfortunately, this case isn't enforced by
the compiler.

NOTE: A Default component can be projected into an OnPush component with
`<ng-content>`.

A Default component shouldn't be used by an OnPush component for the same reason
that `markForCheck()` marks all ancestors to the root for change detection: an
OnPush ancestor could be skipped for change detection and the descendant would
never be reached. Skipping a Default component in this manner would be a
violation of its change detection strategy.

Historically the framework offered no advice on change detection strategy
compatibility; therefore, there are many cases of Default components working in
OnPush contexts. However, this pattern is error prone and likely to cause bugs
where the Default component won't properly update. For this reason, the compiler
now issues a warning, which will eventually be upgraded to an error.

If you encounter a warning during development

*   for a new component, convert it to OnPush. If it's composed of other Default
    components, see the next point.

*   for an existing component, migrate it to OnPush, beginning with its
    dependencies.

TIP: Migrate existing component trees from leaf to root.

In either case, the following sections may prove useful for overcoming common
challenges with OnPush components.

## Sharing state

OnPush imposes some restrictions on shared state to ensure that changes can
propagate between components. Patterns that work with Default components may not
work with OnPush components. Following these guidelines when sharing state
between OnPush components is advised.

BEST PRACTICE: Avoid deeply mutable state that can be changed without notice.

WARNING: Tear-offs and anonymous functions that close over mutable state *are*
deeply mutable state.

This component won't update when the `label` property is mutated by another
component because inputs are change detected by identity. This is an example of
a pattern that works fine for Default components, but not for OnPush components.

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

BEST PRACTICE: Use deeply immutable state.

Updating immutable state requires rebuilding it entirely, changing its identity.
This works well with inputs which are change detected based on identity. Prefer
this approach when state is shared locally, such as directly between a parent
and child.

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

BEST PRACTICE: Use observable mutable state.

Mutations should notify observers, which can then mark themselves for change
detection if necessary. Prefer this approach when state is shared non-locally,
such as between disjoint subtrees or across multiple generations.

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

## Updating query children

The framework is only aware of changes propagated through inputs and outputs.
When an OnPush component is mutated imperatively through any other means, it
must be manually marked for change detection. Imperatively updating OnPush query
children is particularly challenging due to their location in the component
hierarchy relative to the caller.

> NOTE: A query child is a reference obtained using one of the following
> annotations:
>
> *   `@ContentChild()`
> *   `@ContentChildren()`
> *   `@ViewChild()`
> *   `@ViewChildren()`

The component or directive that defines a query can't inject the
`ChangeDetectorRef` of the query target. Furthermore, calling `markForCheck()`
on its own `ChangeDetectorRef` won't mark the query target for change detection.

It's tempting to add defensive `markForCheck()` invocations to members of the
query target, but this approach should be avoided. Invoking `markForCheck()` in
a code path that's called during change detection (such as in an input) is
suboptimal, and sometimes outside the developer's control.

```dart {.bad}
@Component(
  selector: 'example',
  template: '<div>{{label}}</div>',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class ExampleComponent {
  ExampleComponent(this._changeDetectorRef);

  final ChangeDetectorRef _changeDetectorRef;

  String _label;
  String get label => _label;
  @Input()
  set label(String value) {
    _label = value;
    _changeDetectorRef.markForCheck();
  }
}
```

The `markChildForCheck()` method on `ChangeDetectorRef` provides a way to mark
an OnPush query child for change detection that doesn't require changing its
implementation.

BEST PRACTICE: Use the template to propagate changes whenever possible.

For more details, see the `markChildForCheck()`
[documentation][mark-child-for-check-docs].

## Component reuse

The [restrictions](#compatibility-with-default-change-detection) on Default and
OnPush component compatibility pose a challenge for component reuse.

If a component is to be used in an OnPush context, it must also be OnPush. Thus
any components in a common library should ideally be OnPush. This in itself is
fine, but becomes problematic if such a component takes a `ComponentFactory` as
input to render children.

In order to comply with the requirement that OnPush components should only have
OnPush descendants, the `ComponentFactory` would have to create an OnPush
component. However, it's undesirable to force this requirement on users of a
shared component whose app may otherwise entirely use default change detection.

The `@changeDetectionLink` annotation addresses this conundrum. It allows an
OnPush component to load Default components via `ComponentFactory` and honor
their change detection contract as if they were used by another Default
component.

NOTE: `@changeDetectionLink` is restricted to
`package:angular/experimental.dart` users.

For more details, see the `@changeDetectionLink`
[documentation][change-detection-link-docs].

[change-detection-link-docs]: https://github.com/dart-lang/angular/blob/master/angular/lib/src/core/metadata/change_detection_link.dart
[mark-child-for-check-docs]: https://github.com/dart-lang/angular/blob/master/angular/lib/src/core/change_detection/change_detector_ref.dart

