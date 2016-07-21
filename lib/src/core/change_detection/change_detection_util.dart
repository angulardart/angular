import "package:angular2/src/facade/collection.dart"
    show isListLikeIterable, areIterablesEqual;
import "package:angular2/src/facade/lang.dart" show looseIdentical, isPrimitive;

export "package:angular2/src/facade/lang.dart" show looseIdentical;

Object uninitialized = const Object();
bool devModeEqual(dynamic a, dynamic b) {
  if (isListLikeIterable(a) && isListLikeIterable(b)) {
    return areIterablesEqual(a, b, devModeEqual);
  } else if (!isListLikeIterable(a) &&
      !isPrimitive(a) &&
      !isListLikeIterable(b) &&
      !isPrimitive(b)) {
    return true;
  } else {
    return looseIdentical(a, b);
  }
}

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
  WrappedValue(this.wrapped) {}
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
  SimpleChange(this.previousValue, this.currentValue) {}
  /**
   * Check whether the new value is the first value assigned.
   */
  bool isFirstChange() {
    return identical(this.previousValue, uninitialized);
  }
}
