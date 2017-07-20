import 'instruction.dart' show ComponentInstruction;

/// Defines route lifecycle method `routerOnActivate`, which is called by the router at the end of a
/// successful route navigation.
///
/// For a single component's navigation, only one of either [OnActivate] or [OnReuse]
/// will be called depending on the result of [CanReuse].
///
/// The `routerOnActivate` hook is called with two [ComponentInstruction]s as parameters, the
/// first
/// representing the current route being navigated to, and the second parameter representing the
/// previous route or `null`.
///
/// If `routerOnActivate` returns a promise, the route change will wait until the promise settles to
/// instantiate and activate child components.
///
/// ### Example
///
/// <?code-excerpt "docs/router/lib/src/crisis_center/crisis_detail_component.dart (routerOnActivate)"?>
/// ```dart
/// @override
/// void routerOnActivate(next, prev) {
///   print('Activating ${next.routeName} ${next.urlPath}');
/// }
/// ```
///
/// See the [router documentation][router] for details.
///
/// [router]: https://webdev.dartlang.org/angular/guide/router/5#onactivate
abstract class OnActivate {
  dynamic /* dynamic | Future< dynamic > */ routerOnActivate(
      ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction);
}

/// Defines route lifecycle method `routerOnReuse`, which is called by the router at the end of a
/// successful route navigation when [CanReuse] is implemented and returns or resolves to true.
///
/// For a single component's navigation, only one of either [OnActivate] or [OnReuse]
/// will be called, depending on the result of [CanReuse].
///
/// The `routerOnReuse` hook is called with two [ComponentInstruction]s as
/// parameters, the first representing the current route being navigated to,
/// and the second parameter representing the previous route or `null`.
///
/// ### Example
///
/// <?code-excerpt "docs/router/lib/src/crisis_center/crisis_detail_component.dart (routerOnReuse)"?>
/// ```dart
/// @override
/// Future<Null> routerOnReuse(ComponentInstruction next, prev) =>
///     _setCrisis(next.params['id']);
/// ```
///
/// See the [router documentation][router] for details.
///
/// [router]: https://webdev.dartlang.org/angular/guide/router/5#onreuse
abstract class OnReuse {
  dynamic /* dynamic | Future< dynamic > */ routerOnReuse(
      ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction);
}

/// Defines route lifecycle method `routerOnDeactivate`, which is called by the
/// router before destroying a component as part of a route change.
///
/// The `routerOnDeactivate` hook is called with two [ComponentInstruction]s as
/// parameters, the first representing the current route being navigated to,
/// and the second parameter representing the previous route.
///
/// If `routerOnDeactivate` returns a [Future], then the route change will wait
/// until the [Future] completes.
///
/// ### Example
///
/// <?code-excerpt "docs/router/lib/src/crisis_center/crisis_detail_component.dart (routerOnDeactivate)"?>
/// ```dart
/// @override
/// void routerOnDeactivate(next, prev) {
///   print('Deactivating ${prev.routeName} ${prev.urlPath}');
/// }
/// ```
///
/// See the [router documentation][router] for details.
///
/// [router]: https://webdev.dartlang.org/angular/guide/router/5#ondeactivate
abstract class OnDeactivate {
  dynamic /* dynamic | Future< dynamic > */ routerOnDeactivate(
      ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction);
}

/// Defines route lifecycle method `routerCanReuse`, which is called by the
/// router to determine whether a component should be reused across routes, or
/// whether to destroy and instantiate a new component.
///
/// The `routerCanReuse` hook is called with two [ComponentInstruction]s as
/// parameters, the first representing the current route being navigated to,
/// and the second parameter representing the previous route.
///
/// If `routerCanReuse` returns or resolves to `true`, the component instance
/// will be reused and the [OnDeactivate] hook will be run. If `routerCanReuse`
/// returns or resolves to `false`, a new component will be instantiated, and the
/// existing component will be deactivated and removed as part of the navigation.
///
/// If `routerCanReuse` throws or rejects, the navigation will be cancelled.
///
/// ### Example
///
/// <?code-excerpt "docs/router/lib/src/crisis_center/crisis_detail_component.dart (routerCanReuse)"?>
/// ```dart
/// @override
/// FutureOr<bool> routerCanReuse(next, prev) => true;
/// ```
///
/// See the [router documentation][router] for details.
///
/// [router]: https://webdev.dartlang.org/angular/guide/router/5#canreuse
abstract class CanReuse {
  dynamic /* bool | Future< bool > */ routerCanReuse(
      ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction);
}

/// Defines route lifecycle method `routerCanDeactivate`, which is called by
/// the router to determine if a component can be removed as part of a
/// navigation.
///
/// The `routerCanDeactivate` hook is called with two [ComponentInstruction]s
/// as parameters, the first representing the current route being navigated to,
/// and the second parameter representing the previous route.
///
/// If `routerCanDeactivate` returns or resolves to `false`, the navigation is
/// cancelled. If it returns or resolves to `true`, then the navigation
/// continues, and the component will be deactivated (the [OnDeactivate] hook
/// will be run) and removed.
///
/// If `routerCanDeactivate` throws or rejects, the navigation is also
/// cancelled.
///
/// ### Example
///
/// <?code-excerpt "docs/router/lib/src/crisis_center/crisis_detail_component.dart (routerCanDeactivate)"?>
/// ```dart
/// @override
/// FutureOr<bool> routerCanDeactivate(next, prev) =>
///     crisis == null || crisis.name == name
///         ? true as FutureOr<bool>
///         : _dialogService.confirm('Discard changes?');
/// ```
///
/// See the [router documentation][router] for details.
///
/// [router]: https://webdev.dartlang.org/angular/guide/router/5#candeactivate
abstract class CanDeactivate {
  dynamic /* bool | Future< bool > */ routerCanDeactivate(
      ComponentInstruction nextInstruction,
      ComponentInstruction prevInstruction);
}
