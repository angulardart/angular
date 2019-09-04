import 'package:angular/src/runtime.dart';
import 'package:meta/meta.dart';

/// A token to be used instead of [Type] when configuring dependency injection.
///
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
/// The only positional argument, `uniqueName`, is used to determine uniqueness
/// of the token. That is, `const OpaqueToken('SECRET')` is identical to
/// `const OpaqueToken('SECRET')` in another library or package.
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
  final String _uniqueName;

  const OpaqueToken([this._uniqueName = '']);

  @override
  String toString() {
    if (isDevMode) {
      return "OpaqueToken<$T>('$_uniqueName')";
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
/// The only positional argument, `uniqueName`, is used to determine uniqueness
/// of the token. That is, `const MultiToken('SECRETS')` is identical to
/// `const MultiToken('SECRETS')` in another library or package.
///
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
/// This is is the preferred mechanism for configuring multiple bound values to
/// a single token, and will replace `Provider(..., multi: true)` and other
/// variations of the `multi: true` APIs.
///
/// **WARNING**: It is not supported to create a non-const instance of this
/// class or sub-types of this class. Instances should only be created or
/// referenced using the `const` operator.
@optionalTypeArgs
class MultiToken<T> extends OpaqueToken<List<T>> {
  const MultiToken([String uniqueName = '']) : super(uniqueName);

  /// See [listOfMultiToken].
  List<T> _listOf() => <T>[];

  @override
  String toString() {
    if (isDevMode) {
      return "MultiToken (${super.toString()}) <$T>('$_uniqueName')";
    }
    return super.toString();
  }
}

/// **INTERNAL ONLY**: Used to provide type inference for [MultiToken].
List<T> listOfMultiToken<T>(MultiToken<T> token) => token._listOf();
