import 'package:angular/src/facade/lang.dart';

import 'injector/injector.dart';

/// A list representing tokens not found in development mode.
///
/// In production mode, this is always `null`, and should be ignored.
List<Object> devModeTokensNotResolvable;

/// An error thrown when a token is not found when using an [Injector].
///
/// **NOTE**: This error is only guaranteed to be thrown in development mode
/// (i.e. when `assert` is enabled). Otherwise a generic error is thrown with
/// less information (but better performance and lower code-size).
class MissingProviderError extends Error {
  /// Creates an error representing a miss on [token] looked up on [injector].
  static Error create(Injector injector, Object token) {
    if (assertionsEnabled()) {
      _findMissingTokenPath(injector, token);
      return new MissingProviderError._(devModeTokensNotResolvable);
    }
    return new ArgumentError('No provider found for $token.');
  }

  static void _findMissingTokenPath(Injector injector, Object token) {
    // TODO(matanl): Actually implement the rest of the missing path.
    // i.e. Leaf -> Parent -> Root, not just Leaf.
    devModeTokensNotResolvable = [token];
  }

  /// A list of tokens that was attempted, in order, that resulted in an error.
  ///
  /// For example: `[Leaf, Parent, Root]`, where `Root` was the root service
  /// that was missing, looked up via a dependency on `Parent`, which was a
  /// dependency of `Leaf`, the actual token requested via `get(Leaf)`.
  final List<Object> tokens;

  MissingProviderError._(this.tokens);

  @override
  String toString() =>
      // Example: No provider found for Leaf: Leaf -> Parent -> Root.
      tokens.length == 1
          ? 'No provider found for ${tokens.first}'
          : 'No provider found for ${tokens.first}: ' + tokens.join(' -> ');
}
