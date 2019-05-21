import 'package:collection/collection.dart';
import 'package:meta/dart2js.dart' as dart2js;

import 'optimizations.dart';

/// Whether [_debugCheckBinding] should throw if the values are different.
var _debugThrowIfChanged = false;

/// Whether [_debugCheckBinding] should check all expressions types.
///
/// The current (live) version of `checkBinding` (in debug mode) accidentally
/// was implemented where it only checks primitive values (strings, numbers,
/// booleans, null) and not other types. While in practice most bindings
/// eventually propagate to strings, this makes errors much more difficult to
/// debug.
///
/// Additionally, if `true` the failing expression (and location) is reported.
var _debugCheckAllExpressionsAndReportExpressionContext = false;

/// Returns whether [a] is considered "changed" compared to [b].
///
/// Semantically, this method is equivalent to [identical].
///
/// In development (i.e. debug mode), this method may throw if global state
/// indicates that AngularDart is checking the consistency of change detection
/// bindings (i.e. that "expressions have not changed since last check"). It
/// then also uses the parameters [expression] and [location] to provide context
/// to the failure.
@dart2js.tryInline
bool checkBinding(
  Object a,
  Object b, [
  String expression,
  String location,
]) =>
    isDevMode && _debugThrowIfChanged
        ? _debugCheckBinding(a, b)
        : !identical(a, b);

/// Executed only in debug mode when [_throwIfChanged] is also set to `true`.
bool _debugCheckBinding(Object a, Object b) {
  // Experimental code branch that fixes the aforementioned mistakes.
  if (_debugCheckAllExpressionsAndReportExpressionContext) {
    throw UnimplementedError();
  }

  // This is the current code branch that is currently executed for users.
  return !const _DevModeEquality().equals(a, b);
}

/// A buggy implementation of [_debugCheckBinding].
///
/// This accidentally considers most objects equal if they are not primitives.
class _DevModeEquality extends DefaultEquality<Object> {
  const _DevModeEquality();

  @override
  bool equals(Object a, Object b) {
    if (a is Iterable<Object> && b is Iterable<Object>) {
      return const IterableEquality(_DevModeEquality()).equals(a, b);
    } else if (a is! Iterable<Object> &&
        !_isPrimitive(a) &&
        b is! Iterable<Object> &&
        !_isPrimitive(b)) {
      // Code inlined from TS facade.
      return true;
    } else {
      return identical(a, b);
    }
  }
}

/// Returns whether [a] is a "primitive" type ([Null], [String], [num], [bool]).
bool _isPrimitive(Object a) {
  return a == null || a is String || a is num || a is bool;
}
