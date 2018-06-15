@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'exports_statics.dart' as lib;
import 'exports_statics.dart';

import 'exports_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('exports', () {
    tearDown(disposeAnyRunningTest);

    group('can interpolate', () {
      test('constants', () async {
        var testBed = NgTestBed<InterpolateConstantTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello');
      });
      test('static fields', () async {
        var testBed = NgTestBed<InterpolateStaticFieldTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'static field');
      });
      test('enums', () async {
        var testBed = NgTestBed<InterpolateEnumTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'MyEnum.a');
      });
      test('top-level functions', () async {
        var testBed = NgTestBed<InterpolateTopLevelFunctionTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello!!!');
      });
      test('static functions', () async {
        var testBed = NgTestBed<InterpolateStaticFunctionTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello???');
      });
    });

    test('can be used in NgFor', () async {
      var testBed = NgTestBed<StaticNgForTest>();
      var fixture = await testBed.create();
      expect(fixture.text, '123');
    });

    test('can be used in event handlers', () async {
      var testBed = NgTestBed<StaticEventHandlerTest>();
      var fixture = await testBed.create();
      var div = fixture.rootElement.querySelector('div');
      clickHandled = false;
      await fixture.update((_) {
        div.click();
      });
      expect(clickHandled, true);
    });

    test('can be assigned in an event handler', () async {
      var testBed = NgTestBed<StaticEventHandlerTargetTest>();
      var fixture = await testBed.create();
      var div = fixture.rootElement.querySelector('div');
      MyClass.clickHandled = false;
      await fixture.update((_) {
        div.click();
      });
      expect(MyClass.clickHandled, true);
    });

    test('can be used as event handler arguments', () async {
      var testBed = NgTestBed<StaticEventHandlerArgTest>();
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
      var testBed = NgTestBed<SelfReferTest>();
      var fixture = await testBed.create();
      expect(fixture.text, 'hello');
      await fixture.update((_) {
        SelfReferTest.staticField = 'goodbye';
      });
      expect(fixture.text, 'goodbye');
    });

    test('can refer to own statics automatically with @HostBinding', () async {
      var testBed = NgTestBed<SelfReferHostBindingTest>();
      var fixture = await testBed.create();
      expect(fixture.rootElement.title, 'hello');
      await fixture.update((_) {
        SelfReferHostBindingTest.staticField = 'goodbye';
      });
      expect(fixture.rootElement.title, 'goodbye');
    });

    group('can be prefixed', () {
      test('with library prefix', () async {
        var testBed = NgTestBed<StaticLibraryPrefixTest>();
        var fixture = await testBed.create();
        expect(fixture.text, 'hello');
      });
    });
  });
}

@Component(
  selector: 'interpolate-constant-test',
  template: '<div>{{myConst}}</div>',
  exports: [myConst],
)
class InterpolateConstantTest {}

@Component(
  selector: 'interpolate-static-field-test',
  template: '<div>{{MyClass.staticField}}</div>',
  exports: [MyClass],
)
class InterpolateStaticFieldTest {}

@Component(
  selector: 'interpolate-enum-test',
  template: '<div>{{MyEnum.a}}</div>',
  exports: [MyEnum],
)
class InterpolateEnumTest {}

@Component(
  selector: 'interpolate-top-level-function-test',
  template: '<div>{{myFunc("hello")}}</div>',
  exports: [myFunc],
)
class InterpolateTopLevelFunctionTest {}

@Component(
  selector: 'interpolate-static-function-test',
  template: '<div>{{MyClass.staticFunc("hello")}}</div>',
  exports: [MyClass],
)
class InterpolateStaticFunctionTest {}

@Component(
  selector: 'static-ng-for-test',
  template: '<div *ngFor="let item of myList">{{item}}</div>',
  exports: [myList],
  directives: [NgFor],
)
class StaticNgForTest {}

@Component(
  selector: 'static-event-handler-test',
  template: '<div (click)="staticClickHandler()"></div>',
  exports: [staticClickHandler],
)
class StaticEventHandlerTest {}

@Component(
  selector: 'static-event-handler-target-test',
  template: '<div (click)="MyClass.clickHandled = true"></div>',
  exports: [MyClass],
)
class StaticEventHandlerTargetTest {}

@Component(
  selector: 'static-event-handle-arg-test',
  template: '<div (click)="handleClick(myList)"></div>',
  exports: [myList],
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
  exports: [lib.myConst],
)
class StaticLibraryPrefixTest {}

@Component(
  selector: 'self-refer-test',
  template: '<p>{{SelfReferTest.staticField}}</p>',
)
class SelfReferTest {
  static String staticField = 'hello';
}

@Component(
  selector: 'self-refer-host-binding-test',
  template: '',
)
class SelfReferHostBindingTest {
  @HostBinding('title')
  static var staticField = 'hello';
}
