import 'package:meta/meta.dart';
import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/core/change_detection/change_detector_ref.dart';
import 'package:angular/src/core/change_detection/host.dart';
import 'package:angular/src/core/linker/app_view_utils.dart';
import 'package:angular/src/di/errors.dart';
import 'package:angular/src/di/injector/element.dart';
import 'package:angular/src/di/injector/injector.dart';

/// The base implementation of all views.
///
/// Note that generated views should never extend this class directly, but
/// rather one of its specializations.
abstract class View implements ChangeDetectorRef {
  /// Creates the internal state of this view.
  ///
  /// This means, for the most part, creating the necessary initial DOM nodes,
  /// eagerly provided services or references (such as `ViewContainerRef`), and
  /// making them available as class members for later access (such as in
  /// [detectChanges] or [destroyInternalState]).
  @protected
  void build();

  @override
  void checkNoChanges() {
    AppViewUtils.enterThrowOnChanges();
    detectChanges();
    AppViewUtils.exitThrowOnChanges();
  }

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
    final result = injectorGetViewInternal(token, nodeIndex, notFoundResult);
    debugInjectorLeave(token);
    return result;
  }

  /// Alternative to [injectorGet] that may return `null` if missing.
  ///
  /// Used to reduce code-size for dynamic lookups sourced from `@Optional()`.
  @dart2js.noInline
  Object injectorGetOptional(Object token, int nodeIndex) =>
      injectorGet(token, nodeIndex, null);

  /// The view-specific implementation of [injectorGet].
  ///
  /// This indirection allows [injectorGet] to wrap the invocation of this
  /// method with [debugInjectorEnter] and [debugInjectorLeave].
  @protected
  Object injectorGetViewInternal(
    Object token,
    int nodeIndex, [
    Object notFoundResult = throwIfNotFound,
  ]);

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
}
