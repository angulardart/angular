@Tags(const ['codegen'])
@TestOn('browser')

import 'package:angular2/angular2.dart';
import 'package:test/test.dart';
import 'package:angular_test/angular_test.dart';

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
  });
}

@Component(
  selector: 'interpolate-constant-test',
  template: '<div>{{myConst}}</div>',
  exports: const [myConst],
)
class InterpolateConstantTest {}

@Component(
  selector: 'interpolate-static-field-test',
  template: '<div>{{MyClass.staticField}}</div>',
  exports: const [MyClass],
)
class InterpolateStaticFieldTest {}

@Component(
  selector: 'interpolate-enum-test',
  template: '<div>{{MyEnum.a}}</div>',
  exports: const [MyEnum],
)
class InterpolateEnumTest {}

@Component(
  selector: 'interpolate-top-level-function-test',
  template: '<div>{{myFunc("hello")}}</div>',
  exports: const [myFunc],
)
class InterpolateTopLevelFunctionTest {}

@Component(
  selector: 'interpolate-static-function-test',
  template: '<div>{{MyClass.staticFunc("hello")}}</div>',
  exports: const [MyClass],
)
class InterpolateStaticFunctionTest {}

@Component(
  selector: 'static-ng-for-test',
  template: '<div *ngFor="let item of myList">{{item}}</div>',
  exports: const [myList],
  directives: const [NgFor],
)
class StaticNgForTest {}

@Component(
  selector: 'static-event-handler-test',
  template: '<div (click)="staticClickHandler()"></div>',
  exports: const [staticClickHandler],
)
class StaticEventHandlerTest {}
