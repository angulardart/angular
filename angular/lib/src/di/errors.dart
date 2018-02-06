import 'package:angular/src/facade/lang.dart';
import 'package:meta/meta.dart';

/// Returns an error describing that [token] was not found as a provider.
Error noProviderError(Object token) {
  // Only in developer mode, and only when a flag is set.
  // There are already users relying on an ArgumentError _always_ being thrown.
  if (assertionsEnabled() && InjectionError.enableBetterErrors) {
    return new NoProviderError._(token);
  }
  return new ArgumentError(_noProviderError(token));
}

String _noProviderError(Object token) => 'No provider found for $token.';

/// A class of error that is thrown related to dependency injection.
///
/// **NOTE**: These are considered [AssertionError]s, and during production
/// builds may be swapped out for less informative errors that cannot be caught;
/// do not rely on being able to catch an [InjectionError] at runtime.
abstract class InjectionError extends AssertionError {
  /// May be set to `true` in order to get more debuggable error messages.
  ///
  /// **NOTE**: When assertions are disabled changing this does nothing.
  @experimental
  static bool enableBetterErrors = false;

  InjectionError._();
}

/// Thrown when there is no dependency injection provider found for a [token].
class NoProviderError extends InjectionError {
  final Object token;

  NoProviderError._(this.token) : super._();

  @override
  String toString() => _noProviderError(token);
}
