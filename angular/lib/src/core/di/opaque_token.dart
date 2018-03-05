import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

/// A token to be used instead of [Type] when configuring dependency injection.
///
/// ```
/// const loginUrl = const OpaqueToken<String>('loginUrl');
///
/// @Component(
///   selector: 'dashboard',
///   providers: const [
///     const ValueProvider.forToken(loginUrl, 'https://someurl.com'),
///   ],
/// )
/// class DashboardComponent {}
/// ```
///
/// The type [T] is not required, but is recommended, otherwise it is `dynamic`.
///
/// You may also sub-class [OpaqueToken] to create a "more unique" token:
/// ```
/// class LoginUrl extends OpaqueToken<String> {
///   const LoginUrl();
/// }
///
/// const loginUrl = const LoginUrl();
///
/// @Component(
///   selector: 'dashboard',
///   providers: const [
///     const ValueProvider.forToken(loginUrl, 'https://someurl.com'),
///   ],
/// )
/// class DashboardComponent {}
/// ```
///
/// **WARNING**: It is not supported to create a non-const instance of this
/// class or sub-types of this class. Instances should only be created or
/// referenced using the `const` operator.
@optionalTypeArgs
class OpaqueToken<T> {
  final String _desc;

  const OpaqueToken([this._desc = '']);

  @override
  String toString() {
    if (isDevMode) {
      return "OpaqueToken (${super.toString()}) <$T>('$_desc')";
    }
    return super.toString();
  }
}

/// A token representing multiple values of [T] for dependency injection.
///
/// ```
/// const usPresidents = const MultiToken<String>('usPresidents');
///
/// @Component(
///   selector: 'presidents-list',
///   providers: const [
///     const ValueProvider.forToken(usPresidents, 'George Washington'),
///     const ValueProvider.forToken(usPresidents, 'Abraham Lincoln'),
///   ],
/// )
/// class PresidentsListComponent {
///   // Will be ['George Washington', 'Abraham Lincoln'].
///   final List<String> items;
///
///   PresidentsListComponent(@Inject(usPresidents) this.items);
/// }
/// ```
///
/// The type [T] is not required, but is recommended, otherwise it is `dynamic`.
///
/// This is is the preferred mechanism for configuring multiple bound values to
/// a single token, and will replace `Provider(..., multi: true)` and other
/// variations of the `multi: true` APIs.
///
/// You may also sub-class [MultiToken] to create a "more unique" token:
/// ```
/// class UsPresidents extends MultiToken<String> {
///   const UsPresidents();
/// }
///
/// const usPresidents = const UsPresidents();
///
/// @Component(
///   selector: 'presidents-list',
///   providers: const [
///     const ValueProvider.forToken(usPresidents, 'George Washington'),
///     const ValueProvider.forToken(usPresidents, 'Abraham Lincoln'),
///   ],
/// )
/// class PresidentsListComponent {
///   // Will be ['George Washington', 'Abraham Lincoln'].
///   final List<String> items;
///
///   PresidentsListComponent(@Inject(usPresidents) this.items);
/// }
/// ```
///
/// **WARNING**: It is not supported to create a non-const instance of this
/// class or sub-types of this class. Instances should only be created or
/// referenced using the `const` operator.
@optionalTypeArgs
class MultiToken<T> extends OpaqueToken<T> {
  const MultiToken([String description = '']) : super(description);

  @override
  String toString() {
    if (isDevMode) {
      return "MultiToken (${super.toString()}) <$T>('$_desc')";
    }
    return super.toString();
  }
}
