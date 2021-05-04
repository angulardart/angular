import 'package:collection/collection.dart';
import 'package:meta/dart2js.dart' as dart2js;
import 'package:meta/meta.dart';
import 'package:angular/src/utilities.dart';

/// Whether [_debugCheckBinding] should throw if the values are different.
var _debugThrowIfChanged = false;

/// Whether [_debugCheckBinding] should throw immediately, or collect the
/// values to be thrown in [debugThrowIfUnstableExpressionsFound].
var _debugThrowImmediately = false;
final _unstableExpressionValues = <UnstableExpressionValue>[];

/// Whether [debugEnterThrowOnChanged] was enabled for the current cycle.
bool get debugThrowIfChanged => isDevMode && _debugThrowIfChanged;

/// Modifies the runtime of [checkBinding] to record if the values have changed.
void debugEnterThrowOnChanged() {
  _debugThrowIfChanged = true;
}

/// Modifies [_debugCheckBinding] to throw immediately.
void debugThrowOnChangedImmediately() {
  _debugThrowImmediately = true;
}

/// Throws if unstable expressions have been detected.
void debugThrowIfUnstableExpressionsFound() {
  if (_unstableExpressionValues.isNotEmpty) {
    final message = _unstableExpressionValues.join();
    _unstableExpressionValues.clear();
    throw UnstableExpressionError(message);
  }
}

/// Reverts [debugEnterThrowOnChanged]
void debugExitThrowOnChanged() {
  _debugThrowIfChanged = false;
  _debugThrowImmediately = false;
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
void debugCheckBindings([bool enabled = true]) {
  _debugCheckAllExpressionsAndReportExpressionContext = enabled;
}

const _goLink = 'go/angulardart/dev/debugging#debugCheckBindings';

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
  Object? oldValue,
  Object? newValue, [
  String? expression,
  String? location,
]) =>
    isDevMode && _debugThrowIfChanged
        ? !_debugCheckBinding(oldValue, newValue, expression, location)
        : !identical(oldValue, newValue);

/// Returns `true` if [oldValue] is identical to [newValue].
///
/// Executed only in debug mode when [_debugThrowIfChanged] is `true`. If
/// [oldValue] is _not_ identical to [newValue], we will record that the binding
/// should not have changed the provided value in the middle of a change
/// detection cycle.
///
/// If [_debugThrowImmediately] is set to `true`, an error is thrown
/// immediately, otherwise the changed bindings are accumulated in a list and
/// reported together in a single exception thrown from
/// [debugThrowIfUnstableExpressionsFound].
bool _debugCheckBinding(
  Object? oldValue,
  Object? newValue, [
  String? expression,
  String? location,
]) {
  final isIdentical = _debugCheckAllExpressionsAndReportExpressionContext
      ? identical(oldValue, newValue)
      : const _DevModeEquality().equals(oldValue, newValue);

  if (!isIdentical) {
    _unstableExpressionValues.add(UnstableExpressionValue._(
      expression: expression,
      location: location,
      oldValue: oldValue,
      newValue: newValue,
    ));
    if (_debugThrowImmediately) {
      debugThrowIfUnstableExpressionsFound();
    }
  }

  return true;
}

/// A record collected in debug mode when the top-down data flow contract failed.
///
/// AngularDart requires that during a synchronous pass of change detection
/// evaluating a bound [expression] does not result in a [newValue] that has a
/// different identity to [oldValue].
class UnstableExpressionValue {
  /// Contextual expression that was evaluated to result in [newValue].
  final String? expression;

  /// Location in the underlying template that [expression] was within.
  final String? location;

  /// Previous value of evaluating [expression].
  final Object? oldValue;

  /// Current value of evaluating [expression].
  final Object? newValue;

  UnstableExpressionValue._({
    @required this.oldValue,
    @required this.newValue,
    this.expression,
    this.location,
  });

  @override
  String toString() {
    if (_debugCheckAllExpressionsAndReportExpressionContext) {
      return ''
          'Unstable expression ${expression ?? 'UNKNOWN'} '
          'in ${location ?? 'UNKNOWN'}:\n'
          '  Previous: $oldValue (#${identityHashCode(oldValue)})\n'
          '  Current:  $newValue (#${identityHashCode(newValue)})\n';
    }
    return ''
        'Expression has changed after it was checked. '
        'Previous value: "$oldValue". Current value: "$newValue".\n';
  }
}

/// An error thrown in debug mode when the top-down data flow contract failed.
///
/// AngularDart requires that during a synchronous pass of change detection
/// evaluating a bound [expression] does not result in a [newValue] that has a
/// different identity to [oldValue].
///
/// **WARNING**: Do _not_ attempt to catch or handle this (or any) [Error].
class UnstableExpressionError extends Error {
  UnstableExpressionError(this.details);

  /// Formatted string describing the unstable expressions.
  final String details;

  @override
  String toString() {
    final message = ''
        'An expression bound in an AngularDart template returned a different '
        'value the second time it was evaluated.\n';
    return '$message\n$details\n$_goLink\n';
  }
}

/// A buggy implementation of [_debugCheckBinding].
///
/// This accidentally considers most objects equal if they are not primitives.
class _DevModeEquality extends DefaultEquality<Object> {
  const _DevModeEquality();

  @override
  bool equals(Object? a, Object? b) {
    if (a is Iterable<Object> && b is Iterable<Object>) {
      return const IterableEquality(_DevModeEquality()).equals(a, b);
    } else if (a is! Iterable<Object> &&
        !a.isPrimitive &&
        b is! Iterable<Object> &&
        !b.isPrimitive) {
      // Code inlined from TS facade.
      return true;
    } else {
      return identical(a, b);
    }
  }
}
