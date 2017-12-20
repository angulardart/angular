import 'package:collection/collection.dart';
import 'package:angular/src/facade/lang.dart' show isPrimitive;

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
      return identical(a, b);
    }
  }
}

bool devModeEqual(Object a, Object b) => const _DevModeEquality().equals(a, b);

/// Represents a basic change from a previous to a new value.
class SimpleChange {
  dynamic previousValue;
  dynamic currentValue;
  SimpleChange(this.previousValue, this.currentValue);
}
