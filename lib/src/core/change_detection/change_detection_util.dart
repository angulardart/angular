import 'package:angular2/src/facade/lang.dart' show looseIdentical, isPrimitive;
export 'package:angular2/src/facade/lang.dart' show looseIdentical;
import 'package:collection/collection.dart';

class _DevModeEquality extends DefaultEquality<Object> {
  const _DevModeEquality();

  @override
  bool equals(Object a, Object b) {
    if (a is Iterable && b is Iterable) {
      return const IterableEquality(const _DevModeEquality()).equals(a, b);
    } else if (a is! Iterable &&
        !isPrimitive(a) &&
        b is! Iterable &&
        !isPrimitive(b)) {
      // Code inlined from TS facade.
      return true;
    } else {
      return looseIdentical(a, b);
    }
  }
}

bool devModeEqual(Object a, Object b) => const _DevModeEquality().equals(a, b);

Object uninitialized = const Object();

/**
 * Indicates that the result of a [PipeMetadata] transformation has changed even though the
 * reference
 * has not changed.
 *
 * The wrapped value will be unwrapped by change detection, and the unwrapped value will be stored.
 *
 * Example:
 *
 * ```
 * if (this._latestValue === this._latestReturnedValue) {
 *    return this._latestReturnedValue;
 *  } else {
 *    this._latestReturnedValue = this._latestValue;
 *    return WrappedValue.wrap(this._latestValue); // this will force update
 *  }
 * ```
 */
class WrappedValue {
  dynamic wrapped;
  WrappedValue(this.wrapped);
  static WrappedValue wrap(dynamic value) {
    return new WrappedValue(value);
  }
}

/**
 * Helper class for unwrapping WrappedValue s
 */
class ValueUnwrapper {
  var hasWrappedValue = false;
  dynamic unwrap(dynamic value) {
    if (value is WrappedValue) {
      this.hasWrappedValue = true;
      return value.wrapped;
    }
    return value;
  }

  reset() {
    this.hasWrappedValue = false;
  }
}

/**
 * Represents a basic change from a previous to a new value.
 */
class SimpleChange {
  dynamic previousValue;
  dynamic currentValue;
  SimpleChange(this.previousValue, this.currentValue);
  /**
   * Check whether the new value is the first value assigned.
   */
  bool isFirstChange() {
    return identical(this.previousValue, uninitialized);
  }
}
