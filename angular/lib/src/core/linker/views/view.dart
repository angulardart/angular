import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/change_detection/change_detector_ref.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/di/errors.dart';
import 'package:angular/src/di/injector/element.dart';
import 'package:angular/src/di/injector/injector.dart';

/// The base implementation of all views.
///
/// Note that generated views should never extend this class directly, but
/// rather one of its specializations.
abstract class View implements ChangeDetectorRef {
  /// All live query children's associated [ChangeDetectorRef]s.
  ///
  /// The framework generates code to store the associated [ChangeDetectorRef]
  /// for each result used to populate any of the following queries:
  ///
  ///   * `@ContentChild()`
  ///   * `@ContentChildren()`
  ///   * `@ViewChild()`
  ///   * `@ViewChildren()`
  ///
  /// This is used to implement [markChildForCheck].
  ///
  /// The [ChangeDetectorRef] associated with a query child depends on its
  /// source. A component's associated [ChangeDetectorRef] is its component
  /// view. A directive's associated [ChangeDetectorRef] is its enclosing view.
  static final queryChangeDetectorRefs = Expando<ChangeDetectorRef>();

  /// Sentinel value that means an injector has no provider for a given token.
  static const _providerNotFound = Object();

  /// Returns whether this is the first change detection pass.
  bool get firstCheck;

  /// The index of this view within its [parentView].
  ///
  /// May be null if this view has no [parentView].
  int get parentIndex;

  /// This view's parent view.
  ///
  /// Not all view types have a parent view, but exposing this property improves
  /// the ergonomics of a common pattern used to optimize dependency injection:
  /// when a nested embedded view injects a token provided by a known ancestor
  /// view, it uses chained property access to retrieve it.
  View get parentView;

  /// Creates the internal state of this view.
  ///
  /// This means, for the most part, creating the necessary initial DOM nodes,
  /// eagerly provided services or references (such as `ViewContainerRef`), and
  /// making them available as class members for later access (such as in
  /// [detectChanges] or [destroyInternalState]).
  @protected
  void build();

  /// Destroys the internal state of this view.
  ///
  /// Note that unlike `EmbeddedViewRef.destroy`, this does not detach the view
  /// from its container.
  void destroyInternalState();

  /// Backing implementation of [destroyInternalState] for this view.
  ///
  /// Generated views may override this method to destroy any internal state.
  ///
  /// Defaults to an empty method for views with no state to destroy.
  @protected
  void destroyInternal() {}

  /// Invokes change detection on this view and any child views.
  ///
  /// A view that has an uncaught exception, is destroyed, or is otherwise
  /// not meant to be checked (such as being detached or having a change
  /// detection mode that skips checks conditionally) should immediately return.
  void detectChanges();

  /// Invokes change detection on views that use default change detection.
  ///
  /// This applies to all embedded and components views whose associated
  /// component does not use default change detection and is annotated with
  /// `@changeDetectionLink`. Upon reaching a host view, [detectChanges] is
  /// invoked on the hosted component view if it uses default change detection.
  ///
  /// Defaults to an empty method for views that use default change detection,
  /// aren't annotated with `@changeDetectionLink`, or contain no view
  /// containers and `@changeDetectionLink` children.
  @experimental
  void detectChangesInCheckAlwaysViews() {}

  /// Backing implementation of [detectChanges] for this view.
  ///
  /// Generated views may override this method to detect and propagate changes.
  ///
  /// Defaults to an empty method for views with no bindings to change detect.
  @protected
  void detectChangesInternal() {}

  /// Change detects this view within a try-catch block.
  ///
  /// This only is run after the framework has detected a crash.
  @protected
  void detectCrash() {
    try {
      detectChangesInternal();
    } catch (e, s) {
      ChangeDetectionHost.handleCrash(this, e, s);
    }
  }

  /// Permanently disables change detection of this view.
  ///
  /// This is invoked after this view throws an unhandled exception during
  /// change detection. Disabling change detection of this view will prevent it
  /// from throwing the same exception repeatedly on subsequent change detection
  /// cycles.
  void disableChangeDetection();

  @override
  void markChildForCheck(Object child) {
    queryChangeDetectorRefs[child]?.markForCheck();
  }

  /// Adapts and returns services available at [nodeIndex] as an [Injector].
  ///
  /// As an optimization, views use [injectorGet] (and [injectorGetInternal])
  /// for intra-view dependency injection. However, when a user "injects" the
  /// [Injector], they are expecting the API to match other types of injectors:
  ///
  /// ```
  /// class C {
  ///   C(Injector i) {
  ///     // This view (located at 'nodeIndex') adapted to the Injector API.
  ///     final context = i.provideType<UserContext>(UserContext);
  ///   }
  /// }
  /// ```
  Injector injector(int nodeIndex) => ElementInjector(this, nodeIndex);

  /// Finds an object provided for [token] at [nodeIndex] in this view.
  ///
  /// If no object was provided for [token] within this view, it will continue
  /// to look through the parent hierarchy until reaching the root view.
  ///
  /// If no result is found and [notFoundResult] was specified, this returns
  /// [notFoundResult]. Otherwise, this will throw an error describing that no
  /// provider for [token] could be found.
  Object injectorGet(
    Object token,
    int nodeIndex, [
    Object notFoundResult = throwIfNotFound,
  ]) {
    debugInjectorEnter(token);
    final result = inject(token, nodeIndex, notFoundResult);
    debugInjectorLeave(token);
    return result;
  }

  /// Alternative to [injectorGet] that may return `null` if missing.
  ///
  /// Used to reduce code-size for dynamic lookups sourced from `@Optional()`.
  @dart2js.noInline
  Object injectorGetOptional(Object token, int nodeIndex) =>
      injectorGet(token, nodeIndex, null);

  /// Backing implementation of [injectorGet] for this view.
  ///
  /// Generated views may override this method to provide services.
  ///
  /// By default (i.e. for views with no provided services or references), this
  /// is expected to be an identity function for returning [notFoundResult].
  ///
  /// Generated views retain some of the information for it's children's
  /// providers, with each child node representing a different [nodeIndex].
  @protected
  Object injectorGetInternal(
    Object token,
    int nodeIndex,
    Object notFoundResult,
  ) =>
      notFoundResult;

  /// The dependency lookup implementation for [injectorGet].
  ///
  /// This indirection allows [injectorGet] to wrap the invocation of this
  /// method with [debugInjectorEnter] and [debugInjectorLeave].
  @protected
  Object inject(Object token, int nodeIndex, Object notFoundResult) {
    var result = _providerNotFound;
    // This is null when the requests originates from the `parentInjector` field
    // of a view container declared at the top-level of a template.
    if (nodeIndex != null) {
      result = injectorGetInternal(token, nodeIndex, _providerNotFound);
    }
    // If this didn't have a provider for `token`, try injecting from an
    // ancestor.
    if (identical(result, _providerNotFound)) {
      result = injectFromAncestry(token, notFoundResult);
    }
    return result;
  }

  /// Finds an object provided for [token] from this view's ancestry.
  ///
  /// This should be implemented by specific base view types, as each has a
  /// unique way of delegating dependency injection to an ancestor.
  @protected
  Object injectFromAncestry(Object token, Object notFoundResult);
}

/// The interface for [View] data bundled together as an optimization.
///
/// Note this interface exists solely as a common point for documentation.
/// Nowhere should this interface be actually needed, as each implementation
/// should be referenced by its concrete, derived type internally within a
/// specific [View] type. This allows dart2js to entirely drop this type from
/// compiled code.
///
/// The intent of each derived [ViewData] implementation is to reduce
/// polymorphic calls, and reduce the amount of code generated by dart2js.
///
/// In a typical application, each derived [View] type serves as the base class
/// for many generated views. This means the view types are highly polymorphic,
/// and pay a higher cost to access their members. By moving what would be the
/// view's own members into a separate class with a single concrete
/// implementation, only an initial polymorphic access is required to retrieve
/// the data. Once retrieved, the contained members can be efficiently accessed.
///
/// Furthermore, super constructors and field initializers (which includes null
/// fields since JavaScript has to initialize null explicitly) get inlined in
/// derived constructors. By moving the storage for these members to another
/// class with an outlined factory constructor, we alleviate this cost. Instead
/// of initializing this data in every [View] implementation's constructor, we
/// only make a call to a derived [ViewData] factory constructor, which is
/// shared between all view implementations.
abstract class ViewData {
  /// Tracks this view's [ChangeDetectionStrategy].
  // TODO(b/132122866): host and embedded views only need a detached bit.
  int get changeDetectionMode;

  /// Tracks this view's [ChangeDetectorState].
  // TODO(b/132122866): host views only need an error bit.
  int get changeDetectorState;

  /// Whether this view has been destroyed.
  bool get destroyed;

  /// Whether this view should be skipped during change detection.
  ///
  /// This flag is automatically updated when either [changeDetectionMode] or
  /// [changeDetectorState] change.
  bool get shouldSkipChangeDetection;

  /// Destroys this views data and marks this as [destroyed].
  void destroy();
}
