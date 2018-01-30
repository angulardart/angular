@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:html';

import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';
import 'package:angular/src/facade/exceptions.dart' show BaseException;
import 'package:angular_test/angular_test.dart';

import 'dynamic_component_loader_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('SlowComponentLoader', () {
    tearDown(() => disposeAnyRunningTest());

    test('loading next to a location', () async {
      var testBed = new NgTestBed<MyComp>();
      var fixture = await testBed.create();
      fixture.update((MyComp component) {
        component.loader
            .loadNextToLocation(DynamicallyLoaded, component.viewContainerRef)
            .then((ref) {
          expect(fixture.text, 'DynamicallyLoaded;');
        });
      });
    });
    test('should return a disposable component ref', () async {
      var testBed = new NgTestBed<MyComp>();
      var fixture = await testBed.create();
      fixture.update((MyComp component) {
        component.loader
            .loadNextToLocation(DynamicallyLoaded, component.viewContainerRef)
            .then((ref) {
          component.loader
              .loadNextToLocation(
                  DynamicallyLoaded2, component.viewContainerRef)
              .then((ref2) {
            expect(fixture.text, 'DynamicallyLoaded;DynamicallyLoaded2;');
            ref2.destroy();
            expect(fixture.text, 'DynamicallyLoaded;');
          });
        });
      });
    });

    test('should update host properties', () async {
      var testBed = new NgTestBed<MyComp>();
      var fixture = await testBed.create();
      ComponentRef loadedComponent;
      await fixture.update((MyComp component) async {
        loadedComponent = await component.loader.loadNextToLocation(
            DynamicallyLoadedWithHostProps, component.viewContainerRef);
      });
      await fixture.update((MyComp component) {
        loadedComponent.instance.id = 'new value';
      });

      var newlyInsertedElement =
          (getDebugNode(fixture.rootElement) as DebugElement)
              .children[1]
              .nativeNode;
      expect(((newlyInsertedElement as dynamic)).id, 'new value');
    });

    test('should leave the view tree in a consistent state if hydration fails',
        () async {
      var testBed = new NgTestBed<MyComp>();
      var fixture = await testBed.create();
      String errorMsg;
      await fixture.update((MyComp component) async {
        component.loader
            .loadNextToLocation(
                DynamicallyLoadedThrows, component.viewContainerRef)
            .then((loadedComponent) {})
            .catchError((error) async {
          errorMsg = error.message;
        });
      });

      expect(errorMsg, contains('ThrownInConstructor'));
      // should not throw.
      await fixture.update((MyComp component) {});
    });
  });

  group('loadAsRoot', () {
    tearDown(() => disposeAnyRunningTest());

    test('should allow to create, update and destroy components', () async {
      var testBed = new NgTestBed<MyComp>();
      var fixture = await testBed.create();
      var rootEl;
      ComponentRef componentRef;
      await fixture.update((MyComp component) async {
        componentRef = await component.loader.load(ChildComp, null);
        rootEl = componentRef.location;
        document.body.append(rootEl);
      });
      componentRef.changeDetectorRef.detectChanges();
      expect(rootEl, hasTextContent('CHILD_hello'));
      componentRef.instance.ctxProp = 'new';
      componentRef.changeDetectorRef.detectChanges();
      expect(rootEl, hasTextContent('CHILD_new'));
      componentRef.destroy();
      expect(rootEl.parentNode, isNull);
    });
  });
}

dynamic createRootElement(HtmlDocument doc, String name) {
  var nodes = doc.querySelectorAll(name);
  for (var i = 0; i < nodes.length; i++) {
    nodes[i].remove();
  }
  Element rootEl = new Element.tag(name);
  doc.body.append(rootEl);
  return rootEl;
}

typedef bool _Predicate<T>(T item);

_Predicate<DebugElement> filterByDirective(Type type) {
  return (debugElement) {
    return !identical(debugElement.providerTokens.indexOf(type), -1);
  };
}

@Component(
  selector: 'child-cmp',
  template: 'CHILD_{{ctxProp}}',
)
class ChildComp {
  Element element;
  String ctxProp;
  ChildComp(this.element) {
    this.ctxProp = 'hello';
  }
}

@Component(
  selector: 'dummy',
  template: 'DynamicallyLoaded;',
)
class DynamicallyLoaded {}

@Component(
  selector: 'dummy',
  template: 'DynamicallyLoaded;',
)
class DynamicallyLoadedThrows {
  DynamicallyLoadedThrows() {
    throw new BaseException('ThrownInConstructor');
  }
}

@Component(
  selector: 'dummy',
  template: 'DynamicallyLoaded2;',
)
class DynamicallyLoaded2 {}

@Component(
  selector: 'dummy',
  host: const {'[id]': 'id'},
  template: 'DynamicallyLoadedWithHostProps;',
)
class DynamicallyLoadedWithHostProps {
  String id;
  DynamicallyLoadedWithHostProps() {
    this.id = 'default';
  }
}

@Component(
  selector: 'dummy',
  template: 'dynamic(<ng-content></ng-content>)',
)
class DynamicallyLoadedWithNgContent {
  String id;
  DynamicallyLoadedWithNgContent() {
    this.id = 'default';
  }
}

@Component(
  selector: 'my-comp',
  directives: const [],
  template: '<div #loc></div>',
)
class MyComp {
  bool ctxBoolProp;
  @ViewChild('loc', read: ViewContainerRef)
  ViewContainerRef viewContainerRef;
  // ignore: deprecated_member_use
  final SlowComponentLoader loader;
  MyComp(this.loader) {
    this.ctxBoolProp = false;
  }
}
