// Reusable code for writing integration-style tests verifying the behavior
// of @{Content|View}Child[ren], where the end result is a Iterable or single
// element that is assigned by the framework.

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

/// A mixin for components that receive a list of child elements/directives.
abstract class HasChildren<T> {
  /// Child elements of type [T].
  Iterable<T> get children => actualChildren.map((e) => e as T);

  /// Override in concrete classes to provide a collection of child elements.
  ///
  /// **NOTE**: This API is used because as-of today `QueryList` is never
  /// reified as anything but `QueryList<dynamic>`. The new API will have the
  /// correct reified type arguments, but the test suite needs to work for both.
  @protected
  Iterable<Object> get actualChildren;
}

/// An interface for components that receive a single element/directive.
abstract class HasChild<T> {
  /// Element of type [T].
  T get child;
}

/// A simple directive that can be created in order to be queried.
///
/// Accepts a single input, [value], for use with the helper [hasChildValues].
@Directive(
  selector: 'value,[value]',
)
class ValueDirective {
  @Input()
  int value;
}

/// Returns a [Matcher] that looks for [ValueDirective] in a [NgTestFixture].
Matcher hasChildValues(List<int> values) => new _HasChildValues(values);

class _HasChildValues extends Matcher {
  final List<int> values;

  const _HasChildValues(this.values);

  @override
  Description describe(Description description) {
    return description.addDescriptionOf(values);
  }

  @override
  bool matches(item, Map matchState) {
    if (item is NgTestFixture<HasChild<ValueDirective>>) {
      return item.assertOnlyInstance.child.value == values.single;
    }
    if (item is NgTestFixture<HasChildren<ValueDirective>>) {
      final equality = const IterableEquality();
      return equality.equals(
        item.assertOnlyInstance.children.map((v) => v.value),
        values,
      );
    }
    return false;
  }
}

class TestCase<T> {
  final NgTestBed<T> testBed;
  final Iterable<int> expectValues;

  const TestCase(this.testBed, this.expectValues);
}

void testViewChildren({
  @required TestCase<HasChildren<ValueDirective>> directViewChildren,
}) {
  group('@ViewChildren(...)', () {
    test('should find direct view children', () async {
      final fixture = await directViewChildren.testBed.create();
      expect(fixture, hasChildValues(directViewChildren.expectValues));
    });
  });
}
