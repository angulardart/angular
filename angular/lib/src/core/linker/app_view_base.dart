import 'package:meta/meta.dart';

import '../../di/injector/injector.dart';

/// Defines the "public" interface all `AppView` classes must implement.
///
/// This is part of the refactor in order to split `AppView` into various
/// abstract classes (`ComponentView`, `HostView`, `EmbeddedView`) without
/// breaking changes. Statically we validate that every concrete class, at the
/// end of the day, must implement all these public (or protected) members).
///
/// **NOTE**: This class is not yet complete, most members are in `AppView`.
abstract class View {
  /// Implements the semantic elements of the current view.
  ///
  /// For component and embedded views, this means, for the most part, creating
  /// the necessary initial DOM nodes, eagerly provided services or references
  /// (such as `ViewContainerRef`), and making them available as class members
  /// for later access (such as in [detectChanges] or [destroy]).
  @protected
  void build();

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
  @protected
  dynamic injectorGetInternal(
    Object token,
    int nodeIndex,
    Object notFoundResult,
  ) =>
      notFoundResult;
}
