@TestOn('browser')
library angular2.test.directives.observable_list_iterable_diff_test;

import 'package:angular2/common.dart' show ObservableListDiffFactory;
import 'package:angular2/core.dart' show ChangeDetectorRef;
import 'package:angular2/testing_internal.dart';
import 'package:mockito/mockito.dart';
import 'package:observe/observe.dart' show ObservableList;
import 'package:test/test.dart';

class MockChangeDetectorRef extends Mock implements ChangeDetectorRef {}

main() {
  group('ObservableListDiff', () {
    var factory, changeDetectorRef;

    setUp(() {
      factory = const ObservableListDiffFactory();
      changeDetectorRef = new MockChangeDetectorRef();
    });

    test("supports ObservableList", () {
      expect(factory.supports(new ObservableList()), isTrue);
    });

    test("doesn't support non observables", () {
      expect(factory.supports([1, 2, 3]), isFalse);
    });

    test("should return itself when called the first time", () {
      final d = factory.create(changeDetectorRef);
      final c = new ObservableList.from([1, 2]);
      expect(d.diff(c), d);
    });

    test("should return itself when no changes between the calls", () {
      final d = factory.create(changeDetectorRef);

      final c = new ObservableList.from([1, 2]);

      d.diff(c);

      expect(d.diff(c), null);
    });

    test("should return the wrapped value once a change has been triggered",
        fakeAsync(() {
      final d = factory.create(changeDetectorRef);

      final c = new ObservableList.from([1, 2]);

      d.diff(c);

      c.add(3);

      // same value, because we have not detected the change yet
      expect(d.diff(c), null);

      // now we detect the change
      flushMicrotasks();
      expect(d.diff(c), d);
    }));

    test("should request a change detection check upon receiving a change",
        fakeAsync(() {
      final d = factory.create(changeDetectorRef);

      final c = new ObservableList.from([1, 2]);
      d.diff(c);

      c.add(3);

      flushMicrotasks();

      verify(changeDetectorRef.markForCheck()).called(1);
    }));

    test("should return the wrapped value after changing a collection", () {
      final d = factory.create(changeDetectorRef);

      final c1 = new ObservableList.from([1, 2]);
      final c2 = new ObservableList.from([3, 4]);

      expect(d.diff(c1), d);
      expect(d.diff(c2), d);
    });

    test(
        'should not unbsubscribe from the stream of chagnes after changing'
        ' a collection', () {
      final d = factory.create(changeDetectorRef);

      final c1 = new ObservableList.from([1, 2]);
      expect(d.diff(c1), d);

      final c2 = new ObservableList.from([3, 4]);
      expect(d.diff(c2), d);

      // pushing into the first collection has no effect, and we do not see the change
      c1.add(3);
      expect(d.diff(c2), null);
    });
  });
}
