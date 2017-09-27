@Tags(const ['codegen'])
@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'exports_statics.dart' as lib;
import 'exports_statics.dart';

void main() {
  group('exports', () {
    tearDown(disposeAnyRunningTest);

    group('can interpolate', () {
      test('constants', () async {
        var testBed = new NgTestBed<InterpolateConstantTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello');
      });
      test('static fields', () async {
        var testBed = new NgTestBed<InterpolateStaticFieldTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'static field');
      });
      test('enums', () async {
        var testBed = new NgTestBed<InterpolateEnumTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'MyEnum.a');
      });
      test('top-level functions', () async {
        var testBed = new NgTestBed<InterpolateTopLevelFunctionTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello!!!');
      });
      test('static functions', () async {
        var testBed = new NgTestBed<InterpolateStaticFunctionTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello???');
      });
    });

    test('can be used in NgFor', () async {
      var testBed = new NgTestBed<StaticNgForTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '123');
    });

    test('can be used in event handlers', () async {
      var testBed = new NgTestBed<StaticEventHandlerTest>();
      var fixture = await testBed.create();
      var div = fixture.rootElement.querySelector('div');
      clickHandled = false;
      await fixture.update((_) {
        div.click();
      });
      expect(clickHandled, true);
    });

    test('can be assigned in an event handler', () async {
      var testBed = new NgTestBed<StaticEventHandlerTargetTest>();
      var fixture = await testBed.create();
      var div = fixture.rootElement.querySelector('div');
      MyClass.clickHandled = false;
      await fixture.update((_) {
        div.click();
      });
      expect(MyClass.clickHandled, true);
    });

    test('can be used as event handler arguments', () async {
      var testBed = new NgTestBed<StaticEventHandlerArgTest>();
      var fixture = await testBed.create();
      var div = fixture.rootElement.querySelector('div');
      var listArg;
      await fixture.update((StaticEventHandlerArgTest component) {
        component.clickHandler = (list) {
          listArg = list;
        };
        div.click();
      });
      expect(listArg, myList);
    });

    test('can refer to own statics automatically', () async {
      var testBed = new NgTestBed<SelfReferTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'hello');
      await fixture.update((_) {
        SelfReferTest.staticField = 'goodbye';
      });
      expect(fixture.text, 'goodbye');
    });

    group('can be prefixed', () {
      test('with library prefix', () async {
        var testBed = new NgTestBed<StaticLibraryPrefixTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello');
      });
    });
  });
}

@Component(
  selector: 'interpolate-constant-test',
  template: '<div>{{myConst}}</div>',
  exports: const [myConst],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolateConstantTest {}

@Component(
  selector: 'interpolate-static-field-test',
  template: '<div>{{MyClass.staticField}}</div>',
  exports: const [MyClass],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolateStaticFieldTest {}

@Component(
  selector: 'interpolate-enum-test',
  template: '<div>{{MyEnum.a}}</div>',
  exports: const [MyEnum],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolateEnumTest {}

@Component(
  selector: 'interpolate-top-level-function-test',
  template: '<div>{{myFunc("hello")}}</div>',
  exports: const [myFunc],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolateTopLevelFunctionTest {}

@Component(
  selector: 'interpolate-static-function-test',
  template: '<div>{{MyClass.staticFunc("hello")}}</div>',
  exports: const [MyClass],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class InterpolateStaticFunctionTest {}

@Component(
  selector: 'static-ng-for-test',
  template: '<div *ngFor="let item of myList">{{item}}</div>',
  exports: const [myList],
  directives: const [NgFor],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StaticNgForTest {}

@Component(
  selector: 'static-event-handler-test',
  template: '<div (click)="staticClickHandler()"></div>',
  exports: const [staticClickHandler],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StaticEventHandlerTest {}

@Component(
  selector: 'static-event-handler-target-test',
  template: '<div (click)="MyClass.clickHandled = true"></div>',
  exports: const [MyClass],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StaticEventHandlerTargetTest {}

@Component(
  selector: 'static-event-handle-arg-test',
  template: '<div (click)="handleClick(myList)"></div>',
  exports: const [myList],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StaticEventHandlerArgTest {
  Function clickHandler;

  handleClick(List list) {
    clickHandler(list);
  }
}

@Component(
  selector: 'static-library-prefix-test',
  template: '<p>{{lib.myConst}}</p>',
  exports: const [lib.myConst],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class StaticLibraryPrefixTest {}

@Component(
  selector: 'self-refer-test',
  template: '<p>{{SelfReferTest.staticField}}</p>',
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class SelfReferTest {
  static String staticField = 'hello';
}
