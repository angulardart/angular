@TestOn('browser')
library angular2.test.core.change_detection.differs.iterable_differs_test;

import "package:angular2/core.dart" show provide, ReflectiveInjector;
import "package:angular2/src/core/change_detection/differs/iterable_differs.dart"
    show IterableDiffers;
import "package:angular2/testing_internal.dart";
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../../core_mocks.dart';

main() {
  group("IterableDiffers", () {
    var factory1;
    var factory2;
    var factory3;
    setUp(() {
      factory1 = new MockIterableDifferFactory();
      factory2 = new MockIterableDifferFactory();
      factory3 = new MockIterableDifferFactory();
    });
    test("should throw when no suitable implementation found", () {
      var differs = new IterableDiffers([]);
      expect(() => differs.find("some object"),
          throwsWith("Cannot find a differ supporting object 'some object'"));
    });
    test("should return the first suitable implementation", () {
      when(factory1.supports(any)).thenReturn(false);
      when(factory2.supports(any)).thenReturn(true);
      when(factory2.supports(any)).thenReturn(true);
      var differs =
          IterableDiffers.create(([factory1, factory2, factory3] as dynamic));
      expect(differs.find("some object"), factory2);
    });
    test("should copy over differs from the parent repo", () {
      when(factory1.supports(any)).thenReturn(true);
      when(factory2.supports(any)).thenReturn(false);
      var parent = IterableDiffers.create(([factory1] as dynamic));
      var child = IterableDiffers.create(([factory2] as dynamic), parent);
      expect(child.factories, [factory2, factory1]);
    });
    group(".extend()", () {
      test("should throw if calling extend when creating root injector", () {
        var injector =
            ReflectiveInjector.resolveAndCreate([IterableDiffers.extend([])]);
        expect(
            () => injector.get(IterableDiffers),
            throwsWith(
                "Cannot extend IterableDiffers without a parent injector"));
      });
      test("should extend di-inherited diffesr", () {
        var parent = new IterableDiffers([factory1]);
        var injector = ReflectiveInjector
            .resolveAndCreate([provide(IterableDiffers, useValue: parent)]);
        var childInjector = injector.resolveAndCreateChild([
          IterableDiffers.extend([factory2])
        ]);
        expect(injector.get(IterableDiffers).factories, [factory1]);
        expect(
            childInjector.get(IterableDiffers).factories, [factory2, factory1]);
      });
    });
  });
}
