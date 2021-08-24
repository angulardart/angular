// Reusable code for writing integration-style tests verifying the behavior
// of @{Content|View}Child[ren], where the end result is a Iterable or single
// element that is assigned by the framework.

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

/// A mixin for components that receive a list of child elements/directives.
abstract class HasChildren<T> {
  /// Child elements of type [T].
  List<T>? get children;
}

/// An interface for components that receive a single element/directive.
abstract class HasChild<T> {
  /// Element of type [T].
  T? get child;
}

/// A simple directive that can be created in order to be queried.
///
/// Accepts a single input, [value], for use with the helper [hasChildValues].
@Directive(
  selector: 'value,[value]',
)
class ValueDirective {
  @Input()
  int? value;
}

/// Similar to `*ngIf`, but always true.
@Directive(
  selector: '[alwaysShow]',
)
class AlwaysShowDirective {
  AlwaysShowDirective(ViewContainerRef container, TemplateRef template) {
    container.createEmbeddedView(template);
  }
}

/// Similar to `*ngIf`, but always false.
@Directive(
  selector: '[neverShow]',
)
class NeverShowDirective {}

/// Returns a [Matcher] that looks for [ValueDirective] in a [NgTestFixture].
Matcher hasChildValues(Iterable<int> values) =>
    _HasChildValues(values.toList());

class _HasChildValues extends Matcher {
  static final _equality = const IterableEquality();
  final List<int> values;

  const _HasChildValues(this.values);

  @override
  Description describe(Description description) {
    return description.addDescriptionOf(values);
  }

  @override
  Description describeMismatch(
    item,
    Description mismatchDescription,
    void _,
    void __,
  ) {
    Iterable<int?>? children;
    if (item is NgTestFixture<HasChild<ValueDirective>>) {
      final child = item.assertOnlyInstance.child;
      children = child != null ? [child.value] : [];
    }
    if (item is NgTestFixture<HasChildren<ValueDirective>>) {
      children = item.assertOnlyInstance.children!.map((v) => v.value);
    }
    return mismatchDescription
        .addDescriptionOf(values)
        .add(' (expected) is not the same as ')
        .addDescriptionOf(children)
        .add(' (actual)');
  }

  @override
  bool matches(item, void _) {
    if (item is NgTestFixture<HasChild<ValueDirective>>) {
      final child = item.assertOnlyInstance.child;
      if (child == null && values.isEmpty) {
        return true;
      }
      return child!.value == values.single;
    }
    if (item is NgTestFixture<HasChildren<ValueDirective>>) {
      return _equality.equals(
        item.assertOnlyInstance.children!.map((v) => v.value),
        values,
      );
    }
    return false;
  }
}

class TestCase<T extends Object> {
  final NgTestBed<T> testBed;
  final Iterable<int> expectValues;

  const TestCase(this.testBed, this.expectValues);
}

void testViewChildren({
  required TestCase<HasChildren<ValueDirective>> directViewChildren,
  TestCase<HasChild<ValueDirective>>? directViewChild,
  required TestCase<HasChildren<ValueDirective>> viewChildrenAndEmbedded,
  TestCase<HasChild<ValueDirective>>? viewChildEmbedded,
  TestCase<HasChild<ValueDirective>>? viewChildNestedOffOn,
  TestCase<HasChild<ValueDirective>>? viewChildNestedNgIfOffOn,
  TestCase<HasChild<ValueDirective>>? viewChildNestedNgIfOffOnAsync,
}) {
  group('@ViewChild[ren](...)', () {
    test('should find direct view children', () async {
      final fixture = await directViewChildren.testBed.create();
      expect(fixture, hasChildValues(directViewChildren.expectValues));
    });

    test('should find a direct view child', () async {
      final fixture = await directViewChild!.testBed.create();
      expect(fixture, hasChildValues(directViewChild.expectValues));
    }, skip: directViewChild == null);

    test('should find direct view children in embedded templates', () async {
      final fixture = await viewChildrenAndEmbedded.testBed.create();
      expect(fixture, hasChildValues(viewChildrenAndEmbedded.expectValues));
    });

    test('should find direct view child in embedded templates', () async {
      final fixture = await viewChildEmbedded!.testBed.create();
      expect(fixture, hasChildValues(viewChildEmbedded.expectValues));
    }, skip: viewChildEmbedded == null);

    group('should not find embedded view child on', () {
      test('a nested pair of <template> tags (off then on)', () async {
        final fixture = await viewChildNestedOffOn!.testBed.create();
        expect(fixture, hasChildValues(viewChildNestedOffOn.expectValues));
      }, skip: viewChildNestedOffOn == null);

      test('a nested pair of *ngIf usages (true than false)', () async {
        final fixture = await viewChildNestedNgIfOffOn!.testBed.create();
        expect(fixture, hasChildValues(viewChildNestedNgIfOffOn.expectValues));
      }, skip: viewChildNestedNgIfOffOn == null);

      test('a nested pair of *ngIf usages that becomes true, false', () async {
        final fixture = await viewChildNestedNgIfOffOnAsync!.testBed.create();
        expect(
          fixture,
          hasChildValues(viewChildNestedNgIfOffOnAsync.expectValues),
        );
      }, skip: viewChildNestedNgIfOffOnAsync == null);
    });
  });
}

void testContentChildren({
  required TestCase<HasChildren<ValueDirective>> contentChildren,
  TestCase<HasChild<ValueDirective>>? contentChild,
}) {
  group('@ContentChild[ren](...)', () {
    test('should find content children', () async {
      final fixture = await contentChildren.testBed.create();
      expect(fixture, hasChildValues(contentChildren.expectValues));
    });

    test('should find a content child', () async {
      final fixture = await contentChild!.testBed.create();
      expect(fixture, hasChildValues(contentChild.expectValues));
    }, skip: contentChild == null);
  });
}
