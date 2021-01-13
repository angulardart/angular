import 'package:meta/meta.dart';
import 'package:angular/src/utilities.dart';

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
class OpaqueToken<T extends Object> {
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
/// **NOTE**: The `List<T>` returned by dependency injection is _not_ guaranteed
/// to be identical across invocations - that is, a new `List` instance is
/// created every time a provider backed by a [MultiToken] is used:
///
/// ```
/// const usPresidents = MultiToken<String>('usPresidents');
///
/// void example(Injector i) {
///   final a = i.provideToken(usPresidents);
///   final b = i.provideToken(usPresidents);
///   print(identical(a, b)); // false
/// }
/// ```
///
/// **WARNING**: It is not supported to create a non-const instance of this
/// class or sub-types of this class. Instances should only be created or
/// referenced using the `const` operator.
@optionalTypeArgs
class MultiToken<T extends Object> extends OpaqueToken<List<T>> {
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
List<Object> listOfMultiToken(MultiToken<Object> token) => token._listOf();
