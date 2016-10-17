@TestOn('browser && !js')
library angular2.test.core.linker.change_detection_integration_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import "package:angular2/common.dart" show AsyncPipe;
import "package:angular2/core.dart";
import "package:angular2/src/core/change_detection/change_detection.dart"
    show PipeTransform, WrappedValue;
import "package:angular2/src/core/linker/element_ref.dart" show ElementRef;
import "package:angular2/src/core/metadata/lifecycle_hooks.dart" show OnDestroy;
import "package:angular2/src/facade/async.dart" show EventEmitter;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import 'package:angular2/src/testing/angular2_testing.dart';
import 'package:angular2/testing.dart';
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

import "../../compiler/test_bindings.dart" show TEST_PROVIDERS;

const ALL_DIRECTIVES = const [
  TestContainer,
  TestChild,
  TestDirective,
  TestLocals,
  TestUninitialized,
  TestUninitializedChild,
];

const ALL_PIPES = const [
  CountingPipe,
  CountingImpurePipe,
  MultiArgPipe,
  PipeWithOnDestroy,
  IdentityPipe,
  WrappedPipe,
  AsyncPipe
];

void bindingTest(String description, String binding, expectation) {
  ngComponentTest(description, TestContainer, (ComponentFixture fixture) {
    fixture.detectChanges(false);
    TestChild child = fixture.debugElement.childNodes[0].inject(TestChild);
    expect(child.someProp, expectation);
  },
      templateOverride: "<test-child [someProp]='$binding'></test-child>",
      directives: ALL_DIRECTIVES,
      pipes: ALL_PIPES);
}

void containerTest(String description, String template, Function fn,
    {Function onError}) {
  ngComponentTest(description, TestContainer, (ComponentFixture fixture) {
    TestContainer container = fixture.componentInstance;
    TestChild child = fixture.debugElement.childNodes[0].inject(TestChild);
    fn(fixture, container, child);
  },
      templateOverride: template,
      directives: ALL_DIRECTIVES,
      pipes: ALL_PIPES,
      onError: onError);
}

void main() {
  initAngularTests();

  group('Change Detection', () {
    setUpProviders(() => [TestContainer, TestChild, TEST_PROVIDERS]);
    bindingTest('should support literals', '10', 10);
    bindingTest('should strip quotes from literals', '"str"', 'str');
    bindingTest('should support newlines in literals', '"a\n\nb"', 'a\n\nb');
    bindingTest('should support + operations', '10 + 2', 12);
    bindingTest('should support - operations', '10 - 2', 8);
    bindingTest('should support * operations', '10 * 2', 20);
    bindingTest('should support / operations', '10 / 2', 5);
    bindingTest('should support % operations', '11 % 2', 1);
    bindingTest('should support == operations', '1 == 1', true);
    bindingTest('should support != operations', '1 != 1', false);
    bindingTest(
        'should not support == operations on coerceible', '1 == true', false);
    bindingTest('should support === operations on identical', '1 === 1', true);
    bindingTest('should support !== operations on identical', '1 !== 1', false);
    bindingTest(
        'should not coerce values for === operations', '1 === true', false);
    bindingTest('should support true < operations', '1 < 2', true);
    bindingTest('should support false < operations', '2 < 1', false);
    bindingTest('should support false > operations', '1 > 2', false);
    bindingTest('should support true > operations', '2 > 1', true);
    bindingTest('should support true <= operations', '1 <= 2', true);
    bindingTest('should support equal <= operations', '2 <= 2', true);
    bindingTest('should support false <= operations', '2 <= 1', false);
    bindingTest('should support true >= operations', '2 >= 1', true);
    bindingTest('should support equal >= operations', '2 >= 2', true);
    bindingTest('should support false >= operations', '1 >= 2', false);
    bindingTest('should support true && operations', 'true && true', true);
    bindingTest(
        'should support true && false operations', 'true && false', false);
    bindingTest(
        'should support false && true operations', 'false && true', false);
    bindingTest(
        'should support true || false operations', 'true || false', true);
    bindingTest(
        'should support false || true operations', 'false || true', true);
    bindingTest('should support false || operations', 'false || false', false);
    bindingTest('should support negate true', '!true', false);
    bindingTest('should support negate false', '!false', true);
    bindingTest('should support double negate', '!!true', true);
    bindingTest('should support true conditionals', '1 < 2 ? 1 : 2', 1);
    bindingTest('should support false conditionals', '1 > 2 ? 1 : 2', 2);
    bindingTest('should support keyed access to a list item',
        '["foo", "bar"][0]', 'foo');
    bindingTest('should support keyed access to a map item',
        '{"foo": "bar"}["foo"]', 'bar');

    ngComponentTest(
        'Should assign null to uninitialized values', TestUninitialized,
        (ComponentFixture fixture) {
      TestUninitializedChild child =
          fixture.debugElement.childNodes[0].inject(TestUninitializedChild);
      expect(child.someProp, isNotNull);
      fixture.detectChanges(false);
      expect(child.someProp, null);
    });

    containerTest(
        'Should assign null values', "<test-child [someProp]='a'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = null;
      fixture.detectChanges(false);
      expect(child.someProp, null);
    });

    containerTest('should support simple chained property access',
        "<test-child [someProp]='address.city'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = new Address('Grenoble');
      fixture.detectChanges(false);
      expect(child.someProp, 'Grenoble');
    });

    containerTest('should support NaN',
        "<test-child [someProp]='numericValue'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.numericValue = double.NAN;
      fixture.detectChanges(false);
      expect(child.someProp, isNaN);
      child.someProp = '';
      // Should not set it again.
      fixture.detectChanges(false);
      expect(child.someProp, '');
    });

    containerTest('should do simple change detection for strings',
        "<test-child [someProp]='name'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = 'matan';
      fixture.detectChanges(false);
      expect(child.someProp, 'matan');
      child.someProp = '';
      fixture.detectChanges(false);
      expect(child.someProp, '');
      container.name = 'yegor';
      fixture.detectChanges(false);
      expect(child.someProp, 'yegor');
    });
  });

  group('elvis operator', () {
    containerTest('should support reading properties of nulls',
        "<test-child [someProp]='address?.city'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = null;
      // shouldn't throw exception due to null address.
      fixture.detectChanges(false);
      expect(child.someProp, null);
    });

    containerTest('should support reading properties of nulls',
        "<test-child [someProp]='address?.toString()'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = null;
      // shouldn't throw exception due to null address.
      fixture.detectChanges(false);
      expect(child.someProp, null);
    });

    containerTest('should support reading properties on non nulls',
        "<test-child [someProp]='address?.city'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = new Address('MTV');
      fixture.detectChanges(false);
      expect(child.someProp, 'MTV');
    });

    containerTest('should support reading properties on non nulls',
        "<test-child [someProp]='address?.toString()'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = new Address('MTV');
      fixture.detectChanges(false);
      expect(child.someProp, 'MTV');
    });
  });

  group('Function call bindings', () {
    containerTest('should support method calls',
        "<test-child [someProp]='sayHi(\"Jim\")'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, 'Hi, Jim');
    });

    containerTest('should support reading properties on non nulls',
        "<test-child [someProp]='a()(99)'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = () => (a) => 200 + a;
      fixture.detectChanges(false);
      expect(child.someProp, 299);
    });

    containerTest('should support chained method calls',
        "<test-child [someProp]='address.toString()'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.address = new Address('NYC');
      fixture.detectChanges(false);
      expect(child.someProp, 'NYC');
    });
  });

  group('Binding to objects', () {
    containerTest('should support literal array made of literals',
        "<test-child [someProp]='[1, 2]'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, [1, 2]);
    });

    containerTest('should support empty literal array',
        "<test-child [someProp]='[]'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, []);
    });

    containerTest('should support literal array made of expressions',
        "<test-child [someProp]='[1, a]'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 2;
      fixture.detectChanges(false);
      expect(child.someProp, [1, 2]);
    });

    containerTest(
        'should not recreate literal arrays unless their content changed',
        "<test-child [someProp]='[1, a]'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 2;
      fixture.detectChanges(false);
      List list1 = child.someProp;
      expect(child.someProp, [1, 2]);
      fixture.detectChanges(false);
      fixture.detectChanges(false);
      expect(identical(child.someProp, list1), true);
      container.a = 3;
      fixture.detectChanges(false);
      List list2 = child.someProp;
      expect(child.someProp, [1, 3]);
      fixture.detectChanges(false);
      fixture.detectChanges(false);
      expect(identical(child.someProp, list2), true);
    });

    containerTest('should support literal maps made of literals',
        "<test-child [someProp]='{z: 1}'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, {'z': 1});
    });

    containerTest('should support empty literal map',
        "<test-child [someProp]='{}'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, {});
    });

    containerTest('should support literal maps made of expressions',
        "<test-child [someProp]='{z: a}'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 1;
      fixture.detectChanges(false);
      expect(child.someProp, {'z': 1});
    });

    containerTest(
        'should not recreate literal maps unless their content changed',
        "<test-child [someProp]='{z: a}'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 1;
      fixture.detectChanges(false);
      Map map1 = child.someProp;
      expect(map1, {'z': 1});
      fixture.detectChanges(false);
      fixture.detectChanges(false);
      expect(identical(child.someProp, map1), true);
      container.a = 2;
      fixture.detectChanges(false);
      Map map2 = child.someProp;
      expect(map2, {'z': 2});
      fixture.detectChanges(false);
      fixture.detectChanges(false);
      expect(identical(child.someProp, map2), true);
    });

    containerTest('should support interpolation',
        "<test-child someProp=\"B{{a}}C\"></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 'magic';
      fixture.detectChanges(false);
      expect(child.someProp, 'BmagicC');
    });

    containerTest(
        'should output empty strings for null values in interpolation',
        "<test-child someProp=\"B{{a}}C\"></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = null;
      fixture.detectChanges(false);
      expect(child.someProp, 'BC');
    });

    containerTest(
        'should escape values in literals that indicate interpolation',
        "<test-child [someProp]='\"\$\"'></test-child>",
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, '\$');
    });
  });
  group('pipes', () {
    containerTest('should use the return value of the pipe',
        '<test-child [someProp]="name | countingPipe"></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = "bob";
      fixture.detectChanges(false);
      expect(child.someProp, 'bob state:0');
    });

    containerTest(
        'should support arguments in pipes',
        '<test-child [someProp]="name | multiArgPipe:\'one\':address.city">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = "value";
      container.address = new Address('two');
      fixture.detectChanges(false);
      expect(child.someProp, 'value one two default');
    });

    containerTest(
        'should associate pipes right-to-left',
        '<test-child'
        ' [someProp]="name | multiArgPipe:\'a\':\'b\' | multiArgPipe:0:1">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = "value";
      fixture.detectChanges(false);
      expect(child.someProp, 'value a b default 0 1 default');
    });

    containerTest(
        'should support calling pure pipes with different '
        'number of arguments',
        '<test-child'
        ' [someProp]="name | multiArgPipe:\'a\':\'b\' | multiArgPipe:0:1:2">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = "value";
      fixture.detectChanges(false);
      expect(child.someProp, 'value a b default 0 1 2');
    });

    containerTest(
        'should do nothing when there is no change',
        '<test-child [someProp]="\'ConstStr\' | identityPipe">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, 'ConstStr');
      child.someProp = '';
      fixture.detectChanges(false);
      expect(child.someProp, '');
    });

    containerTest(
        'should unwrap the wrapped value',
        '<test-child [someProp]="\'ConstStr\' | wrappedPipe">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      fixture.detectChanges(false);
      expect(child.someProp, 'ConstStr');
      child.someProp = '';
      // Since the value was wrapped, each change detection will generatae
      // new identity and update binding.
      fixture.detectChanges(false);
      expect(child.someProp, 'ConstStr');
    });

    containerTest(
        'should call pure pipes only if the arguments change',
        '<test-child [someProp]="name | countingPipe">'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      // uninitialized -> null.
      container.name = null;
      fixture.detectChanges(false);
      expect(child.someProp, 'null state:0');
      fixture.detectChanges(false);
      expect(child.someProp, 'null state:0');
      // Change from null to value.
      container.name = 'bob';
      fixture.detectChanges(false);
      expect(child.someProp, 'bob state:1');
      fixture.detectChanges(false);
      expect(child.someProp, 'bob state:1');
      // Change to new value.
      container.name = 'new';
      fixture.detectChanges(false);
      expect(child.someProp, 'new state:2');
      fixture.detectChanges(false);
      expect(child.someProp, 'new state:2');
    });

    containerTest('should call impure pipes on each change detection run',
        '<test-child [someProp]="name | countingImpurePipe"></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.name = 'bob';
      fixture.detectChanges(false);
      expect(child.someProp, 'bob state:0');
      fixture.detectChanges(false);
      expect(child.someProp, 'bob state:1');
    });
  });

  group('event expressions', () {
    containerTest('should support field assignments',
        '<test-child (custom-event)=\'b=a=\$event\'></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      var evt = new Event('custom-event');
      child.element.dispatchEvent(evt);
      expect(container.a, evt);
      expect(container.b, evt);
    });

    containerTest('should support keyed assignments',
        '<test-child (custom-event)=\'a[0]=\$event\'></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = ["OLDVALUE"];
      var evt = new Event('custom-event');
      child.element.dispatchEvent(evt);
      expect(container.a[0], evt);
    });

    containerTest('should support chained expressions',
        '<test-child (custom-event)=\'a=a+1; a=a+2;\'></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 5;
      var evt = new Event('custom-event');
      child.element.dispatchEvent(evt);
      expect(container.a, 8);
      evt = new Event('custom-event');
      child.element.dispatchEvent(evt);
      expect(container.a, 11);
    });

    containerTest('should throw exception when assigning to local',
        '<test-child (custom-event)=\'\$event=1;\'></test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      throw new Error();
    }, onError: (e) {
      expect(
          e.toString(), contains('Cannot assign to a reference or variable!'));
    });

    containerTest(
        'should support short-circuiting',
        '<test-child (custom-event)=\'true ? a = a + 1 : a = a + 1\'>'
        '</test-child>',
        (ComponentFixture fixture, TestContainer container, TestChild child) {
      container.a = 0;
      var evt = new Event('custom-event');
      child.element.dispatchEvent(evt);
      expect(container.a, 1);
    });
  });

  group('change notification', () {
    group('updating directives', () {
      containerTest(
          'should update directive value',
          '<test-child testDirective [a]=\'42\'>'
          '</test-child>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(container.a, null);
        expect(TestDirective.log.sublist(0, 1), ['a: 42']);
      });

      containerTest(
          'should read directive properties',
          '<test-child '
          'testDirective [a]="42" ref-dir="testDirective" [someProp]="dir.a">'
          '</test-child>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(TestDirective.log.sublist(0, 1), ['a: 42']);
      });

      containerTest(
          'should notify the directive when a group of records changes',
          '<div [testDirective]="\'inst1\'" [a]="1" [b]="2"></div>'
          '<div [testDirective]="\'inst2\'" [a]="4"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(TestDirective.log, [
          'a: 1',
          'b: 2',
          'name: inst1',
          'inst1: ngOnChanges',
          'inst1: ngOnInit',
          'inst1: ngDoCheck',
          'a: 4',
          'name: inst2',
          'inst2: ngOnChanges',
          'inst2: ngOnInit',
          'inst2: ngDoCheck',
          'inst1: ngAfterContentInit',
          'inst1: ngAfterContentChecked',
          'inst2: ngAfterContentInit',
          'inst2: ngAfterContentChecked',
          'inst1: ngAfterViewInit',
          'inst1: ngAfterViewChecked',
          'inst2: ngAfterViewInit',
          'inst2: ngAfterViewChecked'
        ]);
      });
    });
    group('lifecycle', () {});
  });
}

@Pipe(name: "countingPipe")
class CountingPipe implements PipeTransform {
  num state = 0;
  String transform(value) {
    return '''${ value} state:${ this . state ++}''';
  }
}

@Pipe(name: "countingImpurePipe", pure: false)
class CountingImpurePipe implements PipeTransform {
  num state = 0;
  String transform(value) {
    return '''${ value} state:${ this . state ++}''';
  }
}

@Pipe(name: "pipeWithOnDestroy")
class PipeWithOnDestroy implements PipeTransform, OnDestroy {
  static bool ngDestroyCalled = false;

  PipeWithOnDestroy();

  @override
  ngOnDestroy() {
    ngDestroyCalled = true;
  }

  transform(value) {
    return null;
  }
}

@Pipe(name: "identityPipe")
class IdentityPipe implements PipeTransform {
  transform(value) {
    return value;
  }
}

@Pipe(name: "wrappedPipe")
class WrappedPipe implements PipeTransform {
  transform(value) {
    return WrappedValue.wrap(value);
  }
}

@Pipe(name: "multiArgPipe")
class MultiArgPipe implements PipeTransform {
  transform(value, arg1, arg2, [arg3 = "default"]) {
    return '''${ value} ${ arg1} ${ arg2} ${ arg3}''';
  }
}

@Directive(selector: "[testDirective]", exportAs: "testDirective")
class TestDirective
    implements
        OnInit,
        DoCheck,
        OnChanges,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked,
        OnDestroy {
  static List<String> log = [];
  var _a, _b;
  var _name;

  @Input()
  set a(value) {
    log.add('a: $value');
    _a = value;
  }

  get a => _a;

  @Input()
  set b(value) {
    log.add('b: $value');
    _b = value;
  }

  get b => _b;

  var changes;
  var event;

  EventEmitter<String> eventEmitter = new EventEmitter<String>();

  @Input("testDirective")
  set name(String value) {
    log.add('name: $value');
    _name = value;
  }

  get name => _name;

  @Input()
  String throwOn;

  TestDirective();

  onEvent(event) {
    this.event = event;
  }

  @override
  ngDoCheck() {
    log.add('$name: ngDoCheck');
  }

  @override
  ngOnInit() {
    log.add('$name: ngOnInit');
    if (this.throwOn == "ngOnInit") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngOnChanges(changes) {
    log.add('$name: ngOnChanges');
    var r = {};
    changes.forEach((key, c) => r[key] = c.currentValue);
    this.changes = r;
    if (this.throwOn == "ngOnChanges") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngAfterContentInit() {
    log.add('$name: ngAfterContentInit');
    if (this.throwOn == "ngAfterContentInit") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngAfterContentChecked() {
    log.add('$name: ngAfterContentChecked');
    if (this.throwOn == "ngAfterContentChecked") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngAfterViewInit() {
    log.add('$name: ngAfterViewInit');
    if (this.throwOn == "ngAfterViewInit") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngAfterViewChecked() {
    log.add('$name: ngAfterViewChecked');
    if (this.throwOn == "ngAfterViewChecked") {
      throw new BaseException("Boom!");
    }
  }

  @override
  ngOnDestroy() {
    log.add('$name: ngOnDestroy');
    if (this.throwOn == "ngOnDestroy") {
      throw new BaseException("Boom!");
    }
  }
}

@Component(
    selector: "test-cmp",
    template: "",
    directives: ALL_DIRECTIVES,
    providers: const [TestChild],
    pipes: ALL_PIPES)
class TestContainer {
  final ElementRef elementRef;
  TestContainer(this.elementRef);
  dynamic value;
  dynamic a;
  dynamic b;
  dynamic c;
  // Use for numeric tests, NaN etc.
  num numericValue;
  // Use for Strings.
  String name;
  // Use for path based access and func call tests.
  Address address;

  void init() {
    c = 'initial value';
  }

  String sayHi(name) => 'Hi, $name';
  Element get element => elementRef.nativeElement as Element;
}

@Component(selector: "test-child", template: "")
class TestChild {
  final ElementRef elementRef;
  TestChild(this.elementRef);
  dynamic _someProp;
  @Input()
  set someProp(value) {
    _someProp = value;
  }

  dynamic get someProp => _someProp;
  Element get element => elementRef.nativeElement as Element;
}

@Component(
    selector: "test-uninitialized",
    template: '<test-uninitialized-child [someProp]="value">'
        '</test-uninitialized-child>',
    directives: ALL_DIRECTIVES,
    pipes: ALL_PIPES)
class TestUninitialized {
  dynamic value;
}

@Component(selector: "test-uninitialized-child", template: "")
class TestUninitializedChild {
  dynamic _someProp = 'uninitialized';
  @Input()
  set someProp(value) {
    _someProp = value;
  }

  dynamic get someProp => _someProp;
}

/// Helper to set a local variable value on a template.
@Directive(selector: "[testLocals]")
class TestLocals {
  TestLocals(TemplateRef templateRef, ViewContainerRef vcRef) {
    var viewRef = vcRef.createEmbeddedView(templateRef);
    viewRef.setLocal("someLocal", "someLocalValue");
  }
}

// Helper class to test property paths.
class Address {
  String _city;
  var _zipcode;
  num cityGetterCalls = 0;
  num zipCodeGetterCalls = 0;
  Address(this._city, [this._zipcode = null]);
  get city {
    this.cityGetterCalls++;
    return this._city;
  }

  get zipcode {
    this.zipCodeGetterCalls++;
    return this._zipcode;
  }

  set city(v) {
    _city = v;
  }

  set zipcode(v) {
    _zipcode = v;
  }

  String toString() => city ?? '-';
}
