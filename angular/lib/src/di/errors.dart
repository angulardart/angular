import 'package:meta/dart2js.dart' as dart2js;
import 'package:angular/src/runtime.dart';

/// Current stack of tokens being requested for an injection.
List<Object> _tokenStack;

/// In debug mode, trace entering an injection lookup of [token] in [injector].
///
/// For example:
/// ```
/// dynamic get(Object token) {
///   debugInjectorEnter(token);
///   var result = _getOrThrow(token);
///   debugInjectorLeave(token);
///   return result;
/// }
/// ```
@dart2js.tryInline
void debugInjectorEnter(Object token) {
  // Tree-shake out in Dart2JS.
  if (isDevMode) {
    if (_tokenStack == null) {
      _tokenStack = [token];
    } else {
      _tokenStack.add(token);
    }
  }
}

/// In debug mode, trace leaving an injection lookup (successfully).
@dart2js.tryInline
void debugInjectorLeave(Object token) {
  // Tree-shake out in Dart2JS.
  if (isDevMode) {
    final removed = _tokenStack.removeLast();
    assert(identical(removed, token));
  }
}

/// Wraps invoking [wrap] with [debugInjectorEnter] and [debugInjectorLeave].
T debugInjectorWrap<T>(Object token, T Function() wrap) {
  debugInjectorEnter(token);
  final result = wrap();
  debugInjectorLeave(token);
  return result;
}

/// Returns an error describing that [token] was not found as a provider.
Error noProviderError(Object token) {
  // Only in developer mode.
  // There are already users relying on an ArgumentError _always_ being thrown.
  if (isDevMode) {
    final error = NoProviderError._(token, _tokenStack);
    // IMPORTANT: Clears the stack after reporting the error.
    _tokenStack = null;
    return error;
  }
  return ArgumentError(_noProviderError(token));
}

String _noProviderError(Object token) => 'No provider found for $token';

/// A class of error that is thrown related to dependency injection.
///
/// **NOTE**: These are considered [AssertionError]s, and during production
/// builds may be swapped out for less informative errors that cannot be caught;
/// do not rely on being able to catch an [InjectionError] at runtime.
abstract class InjectionError extends AssertionError {
  InjectionError._();
}

/// Thrown when there is no dependency injection provider found for a [token].
class NoProviderError extends InjectionError {
  // Transforms: [A, B, B, C, B] ==> [A, B, C, B].
  static List<Object> _withAdjacentDeduped(List<Object> input, Object token) {
    if (input == null) {
      return const [];
    }
    final output = <Object>[];
    var lastElement = Object();
    for (final element in input) {
      if (!identical(lastElement, element)) {
        output.add(lastElement = element);
      }
    }
    // Remove the last T (== token), to avoid printing T: T -> T.
    if (output.isNotEmpty) {
      output.removeLast();
    }
    return output;
  }

  /// Token that failed to be found during lookup.
  final Object token;

  /// Path of tokens traversed until it resulted in [token] failing.
  final List<Object> path;

  NoProviderError._(this.token, List<Object> stack)
      : path = _withAdjacentDeduped(stack, token),
        super._();

  @override
  String toString() => path.isEmpty
      ? _noProviderError(token)
      : _noProviderError(token) +
          ':\n  ${path.join(' ->\n  ')} ->\n  $token.\n'
              '**NOTE**: This path is not exhaustive, and nodes may be missing '
              'in between the "->" delimiters. There is ongoing work to improve '
              'this error message and include all the nodes where possible. ';
}
