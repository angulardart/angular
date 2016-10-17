@TestOn('browser && !js')
library angular2.test.core.linker.change_detection_integration_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/core.dart';
import 'package:angular2/src/core/linker/element_ref.dart' show ElementRef;
import 'package:angular2/src/core/metadata/lifecycle_hooks.dart' show OnDestroy;
import 'package:angular2/src/facade/async.dart' show EventEmitter;
import 'package:angular2/src/testing/angular2_testing.dart';
import 'package:angular2/testing.dart';
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

import '../../compiler/test_bindings.dart' show TEST_PROVIDERS;

const ALL_DIRECTIVES = const [
//  TestDirective,
  CompWithRef,
  TestContainer,
  TestChild,
  TestDirective,
  AnotherComponent,
  OrderCheckDirective2,
  OrderCheckDirective0,
  OrderCheckDirective1,
];
const ALL_PIPES = const [];

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

  group('Change Detection lifecycle', () {
    group('ngOnInit', () {
      setUpProviders(() => [TestContainer, TestChild, TEST_PROVIDERS]);

      containerTest(
          'should update directive value', '<div testDirective="dir"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(TestDirective.log, [
          'name: dir',
          'dir: ngOnChanges',
          'dir: ngOnInit',
          'dir: ngDoCheck',
          'dir: ngAfterContentInit',
          'dir: ngAfterContentChecked',
          'dir: ngAfterViewInit',
          'dir: ngAfterViewChecked'
        ]);
      });

      containerTest(
          'should only be called only once', '<div testDirective="dir"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngOnInit']), ['dir: ngOnInit']);

        TestDirective.log.clear();
        // Verify that checking should not call them.
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngOnInit']), []);
        // re-verify that changes should not call them.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngOnInit']), []);
      });

      containerTest('should not call ngOnInit again if it throws',
          '<div testDirective="dir" throwOn=\"ngOnInit\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();

        bool errorLogged = false;
        // First pass fails, but ngOnInit should be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          errorLogged = true;
        }
        expect(errorLogged, isTrue);
        expect(filterLog(TestDirective.log, ['ngOnInit']), ['dir: ngOnInit']);
        TestDirective.log.clear();
        // Second change detection also fails, but this time ngOnInit
        // should not be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          throw new Exception(
              'Second detectChanges() should not have run detection.');
        }
        expect(filterLog(TestDirective.log, ['ngOnInit']), []);
      });
    });

    group('ngDoCheck', () {
      setUpProviders(() => [TestContainer, TestChild, TEST_PROVIDERS]);
      containerTest(
          'should be called after ngOnInit', '<div testDirective="dir"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngOnInit', 'ngDoCheck']),
            ['dir: ngOnInit', 'dir: ngDoCheck']);
      });

      containerTest(
          'should be called on every detectChanges run, '
          'except for checkNoChanges',
          '<div testDirective="dir"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngDoCheck']), ['dir: ngDoCheck']);
        TestDirective.log.clear();
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngDoCheck']), []);
        // re-verify that changes are still detected.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngDoCheck']), ['dir: ngDoCheck']);
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngDoCheck']),
            ['dir: ngDoCheck', 'dir: ngDoCheck']);
      });
    });
    group('ngAfterContentInit', () {
      containerTest(
          'should be called after processing the content children '
          'but before the view children',
          '<div testDirective="parent">'
          '    <div *ngIf="true" testDirective="contentChild"></div>'
          '    <other-cmp></other-cmp>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(
            filterLog(TestDirective.log, ['ngDoCheck', 'ngAfterContentInit']), [
          'parent: ngDoCheck',
          'contentChild: ngDoCheck',
          'contentChild: ngAfterContentInit',
          'parent: ngAfterContentInit',
          'viewChild: ngDoCheck',
          'viewChild: ngAfterContentInit'
        ]);
      });

      containerTest('should only be called only once',
          '<div testDirective=\"dir\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterContentInit']),
            ['dir: ngAfterContentInit']);
        TestDirective.log.clear();
        // Verify that checking should not call them.
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngAfterContentInit']), []);
        // re-verify that changes should not call them.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterContentInit']), []);
      });

      containerTest('should not call ngAfterContentInit again if it throws',
          '<div testDirective="dir" throwOn="ngAfterContentInit"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();

        var errored = false;
        // First pass fails, but ngAfterContentInit should be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          errored = true;
        }
        expect(errored, isTrue);
        expect(filterLog(TestDirective.log, ['ngAfterContentInit']),
            ['dir: ngAfterContentInit']);
        TestDirective.log.clear();
        // Second change detection also fails, but this time
        // ngAfterContentInit should not be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          throw new Exception(
              'Second detectChanges() should not have run detection.');
        }
        expect(filterLog(TestDirective.log, ['ngAfterContentInit']), []);
      });
    });
    group('ngAfterContentChecked', () {
      containerTest(
          'should be called after the content children '
          'but before the view children',
          '<div testDirective="parent">'
          '    <div *ngIf="true" testDirective="contentChild"></div>'
          '    <other-cmp></other-cmp>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(
            filterLog(
                TestDirective.log, ['ngDoCheck', 'ngAfterContentChecked']),
            [
              'parent: ngDoCheck',
              'contentChild: ngDoCheck',
              'contentChild: ngAfterContentChecked',
              'parent: ngAfterContentChecked',
              'viewChild: ngDoCheck',
              'viewChild: ngAfterContentChecked'
            ]);
      });
      containerTest(
          'should be called on every detectChanges run'
          'except for checkNoChanges',
          '<div testDirective=\"dir\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterContentChecked']),
            ['dir: ngAfterContentChecked']);
        TestDirective.log.clear();
        // Verify that checking should not call them.
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngAfterContentChecked']), []);

        // re-verify that changes are still detected.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterContentChecked']),
            ['dir: ngAfterContentChecked']);
      });
      containerTest(
          'should be called in reverse order so the child is '
          'always notified before the parent',
          '<div testDirective="parent">'
          '  <div testDirective="child"></div>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterContentChecked']),
            ['child: ngAfterContentChecked', 'parent: ngAfterContentChecked']);
      });
    });
    group("ngAfterViewInit", () {
      containerTest(
          'should be called after processing the view children',
          '<div testDirective="parent">'
          '    <div *ngIf="true" testDirective="contentChild"></div>'
          '    <other-cmp></other-cmp>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngDoCheck', 'ngAfterViewInit']), [
          'parent: ngDoCheck',
          'contentChild: ngDoCheck',
          'contentChild: ngAfterViewInit',
          'viewChild: ngDoCheck',
          'viewChild: ngAfterViewInit',
          'parent: ngAfterViewInit'
        ]);
      });

      containerTest('should only be called only once',
          '<div testDirective=\"dir\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterViewInit']),
            ['dir: ngAfterViewInit']);
        TestDirective.log.clear();
        // Verify that checking should not call them.
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngAfterViewInit']), []);

        // re-verify that changes should not call them.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterViewInit']), []);
      });

      containerTest('should not call ngAfterViewInit again if it throws',
          '<div testDirective="dir" throwOn="ngAfterViewInit"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();

        var errored = false;
        // First pass fails, but ngAfterContentInit should be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          errored = true;
        }
        expect(errored, isTrue);
        expect(filterLog(TestDirective.log, ['ngAfterViewInit']),
            ['dir: ngAfterViewInit']);

        TestDirective.log.clear();
        // Second change detection also fails, but this time ngAfterViewInit
        // should not be called.
        try {
          fixture.detectChanges(false);
        } catch (e) {
          throw new Exception(
              'Second detectChanges() should not have run detection.');
        }
        expect(filterLog(TestDirective.log, ['ngAfterViewInit']), []);
      });
    });

    group("ngAfterViewChecked", () {
      containerTest(
          'should be called after processing the view children',
          '<div testDirective="parent">'
          '    <div *ngIf="true" testDirective="contentChild"></div>'
          '    <other-cmp></other-cmp>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(
            filterLog(TestDirective.log, ['ngDoCheck', 'ngAfterViewChecked']), [
          'parent: ngDoCheck',
          'contentChild: ngDoCheck',
          'contentChild: ngAfterViewChecked',
          'viewChild: ngDoCheck',
          'viewChild: ngAfterViewChecked',
          'parent: ngAfterViewChecked'
        ]);
      });

      containerTest(
          'should be called on every detectChanges run'
          'except for checkNoChanges',
          '<div testDirective=\"dir\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterViewChecked']),
            ['dir: ngAfterViewChecked']);
        TestDirective.log.clear();
        // Verify that checking should not call them.
        fixture.checkNoChanges();
        expect(filterLog(TestDirective.log, ['ngAfterViewChecked']), []);

        // re-verify that changes are still detected.
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterViewChecked']),
            ['dir: ngAfterViewChecked']);
      });

      containerTest(
          'should be called in reverse order so the child is '
          'always notified before the parent',
          '<div testDirective="parent">'
          '   <div testDirective="child"></div>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        expect(filterLog(TestDirective.log, ['ngAfterViewChecked']),
            ['child: ngAfterViewChecked', 'parent: ngAfterViewChecked']);
      });
    });
    group("ngOnDestroy", () {
      containerTest('should be called on view destruction',
          '<div testDirective=\"dir\"></div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        fixture.destroy();
        expect(filterLog(TestDirective.log, ['ngOnDestroy']),
            ['dir: ngOnDestroy']);
      });

      containerTest(
          'should be called after processing the content '
          'and view children',
          '<div testDirective="parent">'
          '  <div *ngFor="let x of [0,1]" '
          '       testDirective="contentChild{{x}}">'
          '  </div>'
          '  <other-cmp></other-cmp>'
          '</div>',
          (ComponentFixture fixture, TestContainer container, TestChild child) {
        TestDirective.log.clear();
        fixture.detectChanges(false);
        fixture.destroy();
        expect(filterLog(TestDirective.log, ['ngOnDestroy']), [
          'contentChild0: ngOnDestroy',
          'contentChild1: ngOnDestroy',
          'viewChild: ngOnDestroy',
          'parent: ngOnDestroy'
        ]);

        containerTest(
            'should be called in reverse order so the child is always '
            'notified before the parent',
            '<div testDirective="parent">'
            '  <div testDirective="child"></div>'
            '</div>', (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          fixture.detectChanges(false);
          fixture.destroy();
          expect(filterLog(TestDirective.log, ['ngOnDestroy']),
              ['child: ngOnDestroy', 'parent: ngOnDestroy']);
        });
      });

      group("enforce no new changes", () {
        containerTest(
            'should throw when a record gets changed after it has been checked',
            '<test-child [someProp]="a"></test-child>',
            (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          container.a = 1;
          fixture.checkNoChanges();
          throw new Exception('Should have thrown exception for value change');
        }, onError: (e) {
          expect(e.toString(),
              contains('Expression has changed after it was checked'));
        });

        containerTest(
            'should not throw when two arrays are structurally the same',
            '<test-child [someProp]="a"></test-child>',
            (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          container.a = ["value"];
          fixture.detectChanges(false);
          container.a = ["value"];
          // should not throw.
          fixture.checkNoChanges();
        });

        containerTest('should not break the next run',
            '<test-child [someProp]="a"></test-child>',
            (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          container.a = "value";
          expect(() => fixture.checkNoChanges(), throws);
          fixture.detectChanges();
          expect(child.someProp, "value");
        });
      });
      group("mode", () {
        containerTest(
            'Detached', '<comp-with-ref [testValue]="a"></comp-with-ref>',
            (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          CompWithRef cmp =
              fixture.debugElement.childNodes[0].componentInstance;
          // Step1 verify attached works.
          container.a = 'hello';
          expect(cmp.testValue, null);
          fixture.detectChanges();
          expect(cmp.testValue, "hello");
          // Step2 fail when detached.
          fixture.changeDetectorRef.detach();
          container.a = 'world';
          fixture.detectChanges();
          expect(cmp.testValue, "hello");
        });
      });
      group("multi directive order", () {
        containerTest('should follow the DI order for the same element',
            '<div orderCheck2="2" orderCheck0="0" orderCheck1="1"></div>',
            (ComponentFixture fixture, TestContainer container,
                TestChild child) {
          TestDirective.log.clear();
          fixture.detectChanges();
          expect(TestDirective.log, ['0: set', '1: set', '2: set']);
        });
      });
    });
  });
}

@Component(
    selector: "other-cmp",
    directives: ALL_DIRECTIVES,
    pipes: ALL_PIPES,
    template: '<div testDirective="viewChild"></div>')
class AnotherComponent {}

@Component(
    selector: "comp-with-ref",
    template: '<div (event)="noop()" emitterDirective>'
        '</div>{{value}}',
    host: const {"event": "noop()"},
    directives: ALL_DIRECTIVES,
    pipes: ALL_PIPES)
class CompWithRef {
  ChangeDetectorRef changeDetectorRef;
  @Input()
  dynamic value;
  @Input()
  var testValue;
  CompWithRef(this.changeDetectorRef);
  noop() {}
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

  String get name => _name;

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
      throw new Exception("Boom!");
    }
  }

  @override
  ngOnChanges(changes) {
    log.add('$name: ngOnChanges');
    var r = {};
    changes.forEach((key, c) => r[key] = c.currentValue);
    this.changes = r;
    if (this.throwOn == "ngOnChanges") {
      throw new Exception("Boom!");
    }
  }

  @override
  ngAfterContentInit() {
    log.add('$name: ngAfterContentInit');
    if (this.throwOn == "ngAfterContentInit") {
      throw new Exception("Boom!");
    }
  }

  @override
  ngAfterContentChecked() {
    log.add('$name: ngAfterContentChecked');
    if (this.throwOn == "ngAfterContentChecked") {
      throw new Exception("Boom!");
    }
  }

  @override
  ngAfterViewInit() {
    log.add('$name: ngAfterViewInit');
    if (this.throwOn == "ngAfterViewInit") {
      throw new Exception("Boom!");
    }
  }

  @override
  ngAfterViewChecked() {
    log.add('$name: ngAfterViewChecked');
    if (this.throwOn == "ngAfterViewChecked") {
      throw new Exception("Boom!");
    }
  }

  @override
  ngOnDestroy() {
    log.add('$name: ngOnDestroy');
    if (this.throwOn == "ngOnDestroy") {
      throw new Exception("Boom!");
    }
  }
}

/// orderCheck0/1/2 directives are used to make sure they are instantiated
/// in the correct order according to dependency graph.
@Directive(selector: "[orderCheck0]")
class OrderCheckDirective0 {
  String _name;
  @Input("orderCheck0")
  set name(String value) {
    _name = value;
    TestDirective.log.add('$_name: set');
  }

  OrderCheckDirective0();
}

@Directive(selector: "[orderCheck1]")
class OrderCheckDirective1 {
  String _name;
  OrderCheckDirective1(OrderCheckDirective0 _check0);
  @Input("orderCheck1")
  set name(String value) {
    _name = value;
    TestDirective.log.add('$_name: set');
  }
}

@Directive(selector: "[orderCheck2]")
class OrderCheckDirective2 {
  String _name;
  OrderCheckDirective2(OrderCheckDirective1 _check1);
  @Input("orderCheck2")
  set name(String value) {
    _name = value;
    TestDirective.log.add('$_name: set');
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

List<String> filterLog(List<String> log, List<String> matches) {
  var res = <String>[];
  for (String item in log) {
    for (String filter in matches) {
      if (item.contains(filter)) {
        res.add(item);
        break;
      }
    }
  }
  return res;
}
