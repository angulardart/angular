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
@optionalTypeArgs
class OpaqueToken<T> {
  final String _desc;

  const OpaqueToken([this._desc = '']);

  @override
  bool operator ==(other) => other is OpaqueToken && _desc == other._desc;

  @override
  int get hashCode => _desc.hashCode;

  // Temporary: We are using this to canonical-ize OpaqueTokens in source_gen.
  toJson() => toString();

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
/// This is is the preferred mechanism for configuring multiple bound values to
/// a single token, and will replace `Provider(..., multi: true)` and other
/// variations of the `multi: true` APIs.
@optionalTypeArgs
class MultiToken<T> extends OpaqueToken<T> {
  const MultiToken([String description = '']) : super(description);

  @override
  bool operator ==(other) => other is MultiToken && _desc == other._desc;

  @override
  int get hashCode => super.hashCode;

  @override
  String toString() {
    if (isDevMode) {
      return "MultiToken (${super.toString()}) <$T>('$_desc')";
    }
    return super.toString();
  }
}
