import 'package:collection/collection.dart';
import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';

import 'messages.dart';
import 'optimizations.dart';

/// Whether [_debugCheckBinding] should throw if the values are different.
var _debugThrowIfChanged = false;

/// Whether [debugEnterThrowOnChanged] was enabled for the current cycle.
bool get debugThrowIfChanged => isDevMode && _debugThrowIfChanged;

/// Modifies the runtime of [checkBinding] to throw if the values have changed.
void debugEnterThrowOnChanged() {
  _debugThrowIfChanged = true;
}

/// Reverts [debugEnterThrowOnChanged].
void debugExitThrowOnChanged() {
  _debugThrowIfChanged = false;
}

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

/// Opt-in/out to more precise and exhaustive checking of AngularDart bindings.
///
/// The current (live) version of `checkBinding` (in debug mode) accidentally
/// was implemented where it only checks primitive values (strings, numbers,
/// booleans, null) and not other types. While in practice most bindings
/// eventually propagate to strings, this makes errors much more difficult to
/// debug.
///
/// Context (expression and source location) is also reported when available.
///
/// **WARNING**: This API is not considered part of the stable API.
@experimental
void debugCheckBindings([bool enabled = true]) {
  _debugCheckAllExpressionsAndReportExpressionContext = enabled;
  if (isDevMode && enabled) {
    _warnAboutExperimentalFeature();
  }
}

void _warnAboutExperimentalFeature() {
  print('WARNING: debugCheckBindings() is an experimental feature.');
  print('${runtimeMessages.unstableExpressionReadMore}');
}

/// Returns whether [oldValue] is considered "changed" compared to [newValue].
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
  Object oldValue,
  Object newValue, [
  String expression,
  String location,
]) =>
    isDevMode && _debugThrowIfChanged
        ? !_debugCheckBinding(oldValue, newValue)
        : !identical(oldValue, newValue);

/// Returns `true` if [oldValue] is identical to [newValue].
///
/// Executed only in debug mode when [_throwIfChanged] is also set to `true`. If
/// [oldValue] is _not_ identical to [newValue], we throw a runtime error
/// signifying that the binding should not have changed the provided value in
/// the middle of a change detection cycle.
bool _debugCheckBinding(
  Object oldValue,
  Object newValue, [
  String expression,
  String location,
]) {
  final isIdentical = _debugCheckAllExpressionsAndReportExpressionContext
      ? identical(oldValue, newValue)
      : const _DevModeEquality().equals(oldValue, newValue);

  if (!isIdentical) {
    throw UnstableExpressionError._(
      expression: expression,
      location: location,
      oldValue: oldValue,
      newValue: newValue,
    );
  }

  return true;
}

/// An error thrown in debug mode when the top-down data flow contract failed.
///
/// AngularDart requires that during a synchronous pass of change detection
/// evaluating a bound [expression] does not result in a [newValue] that has a
/// different identity to [oldValue].
///
/// **WARNING**: Do _not_ attempt to catch or handle this (or any) [Error].
class UnstableExpressionError extends Error {
  /// Contextual expression that was evaluated to result in [newValue].
  final String expression;

  /// Location in the underlying template that [expression] was within.
  final String location;

  /// Previous value of evaluating [expression].
  final Object oldValue;

  /// Current value of evaluating [expression].
  final Object newValue;

  UnstableExpressionError._({
    @required this.oldValue,
    @required this.newValue,
    this.expression,
    this.location,
  });

  @override
  String toString() {
    if (_debugCheckAllExpressionsAndReportExpressionContext) {
      final message = ''
          'An expression bound in an AngularDart template returned a different '
          'value the second time it was evaluated.\n\n';
      return '$message'
          '${expression ?? 'UNKNOWN'} in ${location ?? 'UNKNOWN'}:\n'
          '  Previous: $oldValue\n'
          '  Current:  $newValue\n\n'
          '${runtimeMessages.unstableExpressionReadMore}';
    }
    return ''
        'Expression has changed after it was checked. '
        'Previous value: "$oldValue". Current value: "$newValue".';
  }
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
