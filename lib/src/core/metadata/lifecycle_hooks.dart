import "package:angular2/src/core/change_detection/change_detection_util.dart"
    show SimpleChange;

enum LifecycleHooks {
  OnInit,
  OnDestroy,
  DoCheck,
  OnChanges,
  AfterContentInit,
  AfterContentChecked,
  AfterViewInit,
  AfterViewChecked
}

/// Lifecycle hooks are guaranteed to be called in the following order:
/// - `OnChanges` (if any bindings have changed),
/// - `OnInit` (after the first check only),
/// - `DoCheck`,
/// - `AfterContentInit`,
/// - `AfterContentChecked`,
/// - `AfterViewInit`,
/// - `AfterViewChecked`,
/// - `OnDestroy` (at the very end before destruction)
var LIFECYCLE_HOOKS_VALUES = [
  LifecycleHooks.OnInit,
  LifecycleHooks.OnDestroy,
  LifecycleHooks.DoCheck,
  LifecycleHooks.OnChanges,
  LifecycleHooks.AfterContentInit,
  LifecycleHooks.AfterContentChecked,
  LifecycleHooks.AfterViewInit,
  LifecycleHooks.AfterViewChecked
];

/// Implement this interface to get notified when any data-bound property of
/// your directive changes.
///
/// [ngOnChanges] is called right after the data-bound properties have been
/// checked and before view and content children are checked if at least one of
/// them has changed.
///
/// The [changes] parameter contains an entry for each changed data-bound
/// property. The key is the property name and the value is an instance of
/// [SimpleChange].
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/on_changes_component.dart region=ng-on-changes}
///
/// [docs]: docs/guide/lifecycle-hooks.html#onchanges
/// [ex]: examples/lifecycle-hooks#onchanges
abstract class OnChanges {
  ngOnChanges(Map<String, SimpleChange> changes);
}

/// Implement this interface to execute custom initialization logic after your
/// directive's data-bound properties have been initialized.
///
/// [ngOnInit] is called right after the directive's data-bound properties have
/// been checked for the first time, and before any of its children have been
/// checked. It is invoked only once when the directive is instantiated.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/spy_directive.dart region=spy-directive}
///
/// [docs]: docs/guide/lifecycle-hooks.html#oninit
/// [ex]: examples/lifecycle-hooks#spy
abstract class OnInit {
  ngOnInit();
}

/// Implement this interface to override the default change detection algorithm
/// for your directive.
///
/// [ngDoCheck] gets called to check the changes in the directives instead of
/// the default algorithm.
///
/// The default change detection algorithm looks for differences by comparing
/// bound-property values by reference across change detection runs. When
/// [DoCheck] is implemented, the default algorithm is disabled and [ngDoCheck]
/// is responsible for checking for changes.
///
/// Implementing this interface allows improving performance by using insights
/// about the component, its implementation and data types of its properties.
///
/// Note that a directive should not implement both [DoCheck] and [OnChanges] at
/// the same time.  [ngOnChanges] would not be called when a directive
/// implements [DoCheck]. Reaction to the changes have to be handled from within
/// the [ngDoCheck] callback.
///
/// Use [KeyValueDiffers] and [IterableDiffers] to add your custom check
/// mechanisms.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/do_check_component.dart region=ng-do-check}
///
/// [docs]: docs/guide/lifecycle-hooks.html#docheck
/// [ex]: examples/lifecycle-hooks#docheck
abstract class DoCheck {
  ngDoCheck();
}

/// Implement this interface to get notified when your directive is destroyed.
///
/// [ngOnDestroy] callback is typically used for any custom cleanup that needs
/// to occur when the instance is destroyed
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/spy_directive.dart region=spy-directive}
///
/// [docs]: docs/guide/lifecycle-hooks.html#ondestroy
/// [ex]: examples/lifecycle-hooks#spy
abstract class OnDestroy {
  ngOnDestroy();
}

/// Implement this interface to get notified when your directive's content has
/// been fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/after_content_component.dart region=template}
///
/// {@example docs/lifecycle-hooks/lib/after_content_component.dart region=hooks}
///
/// [docs]: docs/guide/lifecycle-hooks.html#aftercontent
/// [ex]: examples/lifecycle-hooks#after-content
abstract class AfterContentInit {
  ngAfterContentInit();
}

/// Implement this interface to get notified after every check of your
/// directive's content.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/after_content_component.dart region=template}
///
/// {@example docs/lifecycle-hooks/lib/after_content_component.dart region=hooks}
///
/// [docs]: docs/guide/lifecycle-hooks.html#aftercontent
/// [ex]: examples/lifecycle-hooks#after-content
abstract class AfterContentChecked {
  ngAfterContentChecked();
}

/// Implement this interface to get notified when your component's view has been
/// fully initialized.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/after_view_component.dart region=template}
///
/// {@example docs/lifecycle-hooks/lib/after_view_component.dart region=hooks}
///
/// [docs]: docs/guide/lifecycle-hooks.html#afterview
/// [ex]: examples/lifecycle-hooks#after-view
abstract class AfterViewInit {
  ngAfterViewInit();
}

/// Implement this interface to get notified after every check of your
/// component's view.
///
/// ### Examples
///
/// Try this [live example][ex] from the [Lifecycle Hooks][docs] page:
///
/// {@example docs/lifecycle-hooks/lib/after_view_component.dart region=template}
///
/// {@example docs/lifecycle-hooks/lib/after_view_component.dart region=hooks}
///
/// [docs]: docs/guide/lifecycle-hooks.html#afterview
/// [ex]: examples/lifecycle-hooks#after-view
abstract class AfterViewChecked {
  ngAfterViewChecked();
}
