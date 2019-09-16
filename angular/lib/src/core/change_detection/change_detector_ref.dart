/// Provides influence over how change detection should execute for a component.
///
/// In practice, this is often used just for [markForCheck], which sets a
/// component that uses `ChangeDetectionStrategy.OnPush` as dirty for future
/// change detection.
///
/// **NOTE**: This API is currently _transitional_. Please use carefully, and
/// avoid methods that are marked `@Deprecated(...)`, as they will be eventually
/// removed entirely.
abstract class ChangeDetectorRef {
  /// Marks this and all `ChangeDetectionStrategy.OnPush` ancestors as dirty.
  ///
  /// Components that use `changeDetection: ChangeDetectionStrategy.OnPush` are
  /// only checked once (after creation), and are no longer considered "dirty"
  /// until either:
  ///
  /// * The identity of an expression bound to an `@Input()` changes.
  /// * An event binding or output bound to the component's template is invoked.
  /// * This method ([markForCheck]) is called.
  ///
  /// Use [markForCheck] when Angular would otherwise not know that the state
  /// of the component has changed - for example if an async function was
  /// executed or an observable model has changed:
  ///
  /// ```
  /// @Component(
  ///   selector: 'on-push-example',
  ///   template: 'Number of ticks: {{ticks}}",
  ///   changeDetection: ChangeDetectionStrategy.OnPush,
  /// )
  /// class OnPushExample implements OnDestroy {
  ///   Timer timer;
  ///
  ///   var ticks = 0;
  ///
  ///   OnPushExample(ChangeDetectorRef changeDetector) {
  ///     timer = Timer.periodic(Duration(seconds: 1), () {
  ///       ticks++;
  ///       changeDetector.markForCheck();
  ///     });
  ///   }
  ///
  ///   @override
  ///   void ngOnDestroy() {
  ///     timer.cancel();
  ///   }
  /// }
  /// ```
  ///
  /// For those familiar with more reactive frameworks (Flutter, React),
  /// [markForCheck] operates similar to the `setState(...)` function, which
  /// ultimately marks the component or widget as dirty.
  void markForCheck();

  /// Invokes [markForCheck] on [child]'s associated [ChangeDetectorRef].
  ///
  /// This only works if [child] is a reference obtained from any of the
  /// following annotations:
  ///
  ///   * `@ContentChild()`
  ///   * `@ContentChildren()`
  ///   * `@ViewChild()`
  ///   * `@ViewChildren()`
  ///
  /// On any other argument, this method is still safe to call, but has no
  /// effect. This allows the caller to use this method without explicit
  /// knowledge of whether or not [child] is backed by a component using
  /// `ChangeDetectionStrategy.OnPush`.
  ///
  /// ```
  /// @Component(
  ///   selector: 'example',
  ///   template: '<ng-content></ng-content>',
  ///   changeDetection: ChangeDetectionStrategy.OnPush,
  /// )
  /// class ExampleComponent {
  ///   ExampleComponent(this._changeDetectorRef);
  ///
  ///   final ChangeDetectorRef _changeDetectorRef;
  ///
  ///   @ContentChildren(Child)
  ///   List<Child> children;
  ///
  ///   void updateChildren(Model model) {
  ///     for (final child in children) {
  ///       // If child is implemented by an OnPush component, imperatively
  ///       // mutating a property like this won't be observed without marking
  ///       // the child to be checked.
  ///       child.model = model;
  ///       _changeDetectorRef.markChildForCheck(child);
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Prefer propagating updates to children through the template over this
  /// method when possible. This method is intended as a last resort to
  /// facilitate migrating components to use `ChangeDetectionStrategy.OnPush`.
  void markChildForCheck(Object child);

  /// Detaches the component from the change detection hierarchy.
  ///
  /// A component whose change detector has been detached will be skipped during
  /// change detection until [reattach] is called. This strategy could be used
  /// for specific optimizations around components that are not visible to the
  /// user (such as modals or popups) but are loaded.
  ///
  /// **NOTE**: Lifecycle events (such as `ngOnInit`, `ngAfterChanges`, and so
  /// on) are still called if the component has been detached. We may consider
  /// changing this behavior in the future: b/129780288.
  ///
  /// In most cases simply using `ChangeDetectionStrategy.OnPush` and calling
  /// [markForCheck] is preferred as it provides the same contract around not
  /// checking a component until it is dirtied.
  ///
  /// **WARNING**: This API should be considered rather _rare_. Strongly
  /// consider reaching out if you have a bug or performance issue that leads
  /// to using [detach] over `ChangeDetectionStrategy.OnPush` / [markForCheck].
  @Deprecated('Use "changeDetection: ChangeDetectionStrategy.OnPush" instead')
  void detach();

  /// Reattaches a component that was [detach]-ed previously from the hierarchy.
  ///
  /// This method also invokes [markForCheck], and the now re-attached component
  /// will be checked for changes during the next change detection run. See the
  /// docs around [detach] for details of how detaching works and why this
  /// method invocation should be rare.
  @Deprecated('Use "changeDetection: ChangeDetectionStrategy.OnPush" instead')
  void reattach();

  /// Forces synchronous change detection of this component and its children.
  ///
  /// **WARNING**: In practice, this API was not intended to be public with
  /// perhaps the exception of a select few specialized leaf components, and is
  /// being completely removed in a future version of Angular.
  ///
  /// Try instead:
  ///
  /// * Simply removing it, and seeing if it breaks your app.
  /// * Using `ChangeDetectionStrategy.OnPush` and [markForCheck] instead.
  ///
  /// If all else fails, it is strongly preferable to use our explicit API for
  /// forcing more change detection, `NgZone.runAfterChangesObserved`. It is
  /// also worth filing a bug if this is needed.
  @Deprecated('Breaks assumptions around change detection and will be removed')
  void detectChanges();
}
