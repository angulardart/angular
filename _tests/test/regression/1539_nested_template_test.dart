@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import '1539_nested_template_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should render a nested template', () async {
    final fixture = await NgTestBed.forComponent(
      ng.NestedTemplateTestNgFactory,
    ).create();

    Future<void> setInnerCondition(bool value) {
      return fixture.update((c) => c.showInner = value);
    }

    Future<void> setOuterCondition(bool value) {
      return fixture.update((c) => c.showOuter = value);
    }

    void expectHelloWorld() {
      expect(fixture.text, contains('Hello World'));
    }

    void expectEmpty() {
      expect(fixture.text, isNot(contains('Hello World')));
    }

    expectEmpty();
    await setOuterCondition(true);
    expectEmpty();
    await setInnerCondition(true);
    expectHelloWorld();
    await setOuterCondition(false);
    expectEmpty();
  });

  test('should render a nested deferred template', () async {
    final fixture = await NgTestBed.forComponent(
      ng.NestedDeferredTestNgFactory,
    ).create();

    Future<void> setOuterCondition(bool value) {
      return fixture.update((c) => c.showOuter = value);
    }

    void expectHelloWorld() {
      expect(fixture.text, contains('Hello World'));
    }

    void expectEmpty() {
      expect(fixture.text, isNot(contains('Hello World')));
    }

    expectEmpty();
    await setOuterCondition(true);
    expectHelloWorld();

    // This fails prior to fixing #1539, the inner component is not removed.
    await setOuterCondition(false);
    expectEmpty();
  });

  test('should render a nested deferred template with a div', () async {
    final fixture = await NgTestBed.forComponent(
      ng.NestedDeferredWithDivTestNgFactory,
    ).create();

    Future<void> setOuterCondition(bool value) {
      return fixture.update((c) => c.showOuter = value);
    }

    void expectHelloWorld() {
      expect(fixture.text, contains('Hello World'));
    }

    void expectEmpty() {
      expect(fixture.text, isNot(contains('Hello World')));
    }

    expectEmpty();
    await setOuterCondition(true);
    expectHelloWorld();
    await setOuterCondition(false);
    expectEmpty();
  });

  test('should render a nested template with a custom directive', () async {
    final fixture = await NgTestBed.forComponent(
      ng.NestedCustomTestNgFactory,
    ).create();

    Future<void> setInnerCondition(bool value) {
      return fixture.update((c) {
        if (value) {
          c.showInner.createChildView();
        } else {
          c.showInner.destroyChildView();
        }
      });
    }

    Future<void> setOuterCondition(bool value) {
      return fixture.update((c) {
        if (value) {
          c.showOuter.createChildView();
        } else {
          c.showOuter.destroyChildView();
        }
      });
    }

    void expectHelloWorld() {
      expect(fixture.text, contains('Hello World'));
    }

    void expectEmpty() {
      expect(fixture.text, isNot(contains('Hello World')));
    }

    expectEmpty();
    await setOuterCondition(true);
    expectEmpty();
    await setInnerCondition(true);
    expectHelloWorld();
    await setOuterCondition(false);
    expectEmpty();
  });
}

@Component(
  selector: 'nested-template-test',
  directives: [
    HelloWorldComponent,
    NgIf,
  ],
  template: r'''
    <template [ngIf]="true">
      <template [ngIf]="showOuter">
        <template [ngIf]="showInner">
          <hello-world></hello-world>
        </template>
      </template>
    </template>
  ''',
)
class NestedTemplateTest {
  bool showOuter = false;
  bool showInner = false;
}

@Component(
  selector: 'nested-deferred-test',
  directives: [
    HelloWorldComponent,
    NgIf,
  ],
  template: r'''
    <div *ngIf="showOuter">
      <hello-world @deferred></hello-world>
    </div>
  ''',
)
class NestedDeferredWithDivTest {
  bool showOuter = false;
}

@Component(
  selector: 'nested-deferred-test',
  directives: [
    HelloWorldComponent,
    NgIf,
  ],
  template: r'''
    <template [ngIf]="showOuter">
      <hello-world @deferred></hello-world>
    </template>
  ''',
)
class NestedDeferredTest {
  bool showOuter = false;
}

@Directive(
  selector: '[customIf]',
)
class CustomIfDirective {
  final TemplateRef _templateRef;
  final ViewContainerRef _viewContainer;

  CustomIfDirective(this._viewContainer, this._templateRef);

  void createChildView() {
    _viewContainer.createEmbeddedView(_templateRef);
  }

  void destroyChildView() {
    _viewContainer.clear();
  }
}

@Component(
  selector: 'nested-custom-test',
  directives: [
    CustomIfDirective,
    HelloWorldComponent,
  ],
  template: r'''
    <template customIf #showOuter>
      <template customIf #showInner>
        <hello-world></hello-world>
      </template>
    </template>
  ''',
)
class NestedCustomTest {
  @ViewChild('showOuter', read: CustomIfDirective)
  CustomIfDirective showOuter;

  @ViewChild('showInner', read: CustomIfDirective)
  CustomIfDirective showInner;
}

@Component(
  selector: 'hello-world',
  template: 'Hello World',
)
class HelloWorldComponent {}
