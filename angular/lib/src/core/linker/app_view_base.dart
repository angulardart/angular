import 'package:meta/meta.dart';

import '../../di/injector/injector.dart';

/// Defines the "public" interface all `AppView` classes must implement.
///
/// This is part of the refactor in order to split `AppView` into various
/// abstract classes (`ComponentView`, `HostView`, `EmbeddedView`) without
/// breaking changes. Statically we validate that every concrete class, at the
/// end of the day, must implement all these public (or protected) members).
///
/// * [T] should be represent a `class` annotated with `@Component`.
/// * This class is not yet complete, most members are in `AppView`.
abstract class View<T> {
  /// Implements the semantic elements of the current view.
  ///
  /// For component and embedded views, this means, for the most part, creating
  /// the necessary initial DOM nodes, eagerly provided services or references
  /// (such as `ViewContainerRef`), and making them available as class members
  /// for later access (such as in [detectChanges] or [destroy]).
  @protected
  void build();

  /// Destroys the internal state of the view.
  ///
  /// If appropriate, any nodes that were added to the DOM by [build] are also
  /// detached from the DOM and destroyed.
  void destroy();

  /// Invokes change detection on this view and any child views.
  ///
  /// A view that has an uncaught exception, is destroyed, or is otherwise
  /// not meant to be checked (such as being detached or having a change
  /// detection mode that skips checks conditionally) should immediately return.
  void detectChanges();

  /// Backing implementation of `detectChanges` for the current view.
  ///
  /// Defaults to an empty method for the rare components with no bindings.
  @protected
  void detectChangesInternal() {}

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
  @protected
  Injector injector(int nodeIndex);

  /// Backing implementation of `injectorGet` for the current view.
  ///
  /// By default (i.e. for views with no provided services or references), this
  /// is expected to be an identity function for returning [notFoundResult].
  ///
  /// In a generated view, the component view retains some of the information
  /// for it's children's providers, with each child node representing a
  /// different [nodeIndex].
  @protected
  dynamic injectorGetInternal(
    Object token,
    int nodeIndex,
    Object notFoundResult,
  ) =>
      notFoundResult;
}
