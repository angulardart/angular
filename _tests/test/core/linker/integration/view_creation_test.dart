import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'view_creation_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('should support imperative views', () async {
    final testBed = NgTestBed(
      ng.createSimpleImperativeViewComponentFactory(),
    );
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello imp view');
  });

  test('should support moving embedded views', () async {
    final template = TemplateElement()..append(DivElement());
    final testBed = NgTestBed(
      ng.createMovesEmbeddedViewComponentFactory(),
    ).addInjector(
      (i) => Injector.map({
        ANCHOR_ELEMENT: template,
      }, i),
    );
    final testFixture = await testBed.create();
    final viewport = testFixture.assertOnlyInstance.viewport!;
    expect(viewport.anchor.text, '');
    await testFixture.update((component) => component.ctxBoolProp = true);
    expect(viewport.anchor.text, 'hello');
    await testFixture.update((component) => component.ctxBoolProp = false);
    expect(viewport.anchor.text, '');
  });

  group('property bindings', () {
    test("shouldn't throw if unknown property exists on directive", () async {
      final testBed = NgTestBed(
        ng.createUnknownPropertyOnDirectiveComponentFactory(),
      );
      await testBed.create();
    });

    test("shouldn't be created when a directive property has the same name",
        () async {
      final testBed = NgTestBed(
        ng.createOverriddenPropertyComponentFactory(),
      );
      final testFixture = await testBed.create();
      final span = testFixture.rootElement.querySelector('span');
      expect(span!.title, isEmpty);
    });

    test('should allow directive host property to update DOM', () async {
      final testBed = NgTestBed(
        ng.createDirectiveUpdatesDomComponentFactory(),
      );
      final testFixture = await testBed.create();
      final span = testFixture.rootElement.querySelector('span');
      expect(span!.title, 'TITLE');
    });
  });

  group('property decorators', () {
    test('should support @Input', () async {
      final testBed = NgTestBed(
        ng.createDecoratorsComponentFactory(),
      );
      final testFixture = await testBed.create();
      final directive = testFixture.assertOnlyInstance.directive;
      expect(directive!.dirProp, 'foo');
    });

    test('should support @HostBinding', () async {
      final testBed = NgTestBed(
        ng.createDecoratorsComponentFactory(),
      );
      final testFixture = await testBed.create();
      await testFixture.update((component) {
        component.directive!.myAttr = 'bar';
      });
      final directiveElement = testFixture.rootElement.children.first;
      expect(directiveElement.attributes, containsPair('my-attr', 'bar'));
    });

    test('should support @Output', () async {
      final testBed = NgTestBed(
        ng.createDecoratorsComponentFactory(),
      );
      final testFixture = await testBed.create();
      await testFixture.update((component) {
        expect(component.value, isNull);
        component.directive!.fireEvent('fired!');
      });
      expect(testFixture.assertOnlyInstance.value, 'called');
    });

    test('should support @HostListener', () async {
      final testBed = NgTestBed(
        ng.createDecoratorsComponentFactory(),
      );
      final testFixture = await testBed.create();
      final directive = testFixture.assertOnlyInstance.directive!;
      expect(directive.target, isNull);
      final directiveElement = testFixture.rootElement.children.first;
      directiveElement.dispatchEvent(MouseEvent('click'));
      await testFixture.update();
      expect(directive.target, directiveElement);
    });
  });

  test('should support svg elements', () async {
    final testBed = NgTestBed(
      ng.createSvgElementsComponentFactory(),
    );
    final testFixture = await testBed.create();
    final svg = testFixture.rootElement.querySelector('svg')!;
    expect(svg.namespaceUri, 'http://www.w3.org/2000/svg');
    final use = testFixture.rootElement.querySelector('use')!;
    expect(use.namespaceUri, 'http://www.w3.org/2000/svg');
    final foreignObject =
        testFixture.rootElement.querySelector('foreignObject')!;
    expect(foreignObject.namespaceUri, 'http://www.w3.org/2000/svg');
    final div = testFixture.rootElement.querySelector('div')!;
    expect(div.namespaceUri, 'http://www.w3.org/1999/xhtml');
    final p = testFixture.rootElement.querySelector('p')!;
    expect(p.namespaceUri, 'http://www.w3.org/1999/xhtml');
  });

  group('namespace attributes', () {
    test('should be supported', () async {
      final testBed = NgTestBed(
        ng.createNamespaceAttributeComponentFactory(),
      );
      final testFixture = await testBed.create();
      final use = testFixture.rootElement.querySelector('use')!;
      expect(use.getAttributeNS('http://www.w3.org/1999/xlink', 'href'), '#id');
    });

    test('should support binding', () async {
      final testBed = NgTestBed(
        ng.createNamespaceAttributeBindingComponentFactory(),
      );
      final testFixture = await testBed.create();
      final use = testFixture.rootElement.querySelector('use')!;
      expect(
          use.getAttributeNS('http://www.w3.org/1999/xlink', 'href'), isNull);
      await testFixture.update((component) => component.value = '#id');
      expect(use.getAttributeNS('http://www.w3.org/1999/xlink', 'href'), '#id');
    });
  });
}

@Component(
  selector: 'simple-imp-cmp',
  template: '',
)
class SimpleImperativeViewComponent {
  SimpleImperativeViewComponent(Element hostElement) {
    hostElement.append(Text('hello imp view'));
  }
}

const ANCHOR_ELEMENT = OpaqueToken('AnchorElement');

@Directive(
  selector: '[someImpvp]',
)
class SomeImperativeViewport {
  ViewContainerRef vc;
  TemplateRef templateRef;
  EmbeddedViewRef? view;
  TemplateElement anchor;

  SomeImperativeViewport(
      this.vc, this.templateRef, @Inject(ANCHOR_ELEMENT) this.anchor);

  @Input()
  set someImpvp(bool value) {
    if (view != null) {
      vc.clear();
      view = null;
    }
    if (value) {
      view = vc.createEmbeddedView(templateRef);
      var nodes = view!.rootNodes;
      for (var i = 0; i < nodes.length; i++) {
        anchor.append(nodes[i]);
      }
    }
  }
}

@Component(
  selector: 'moves-embedded-view',
  template: '<div><div *someImpvp="ctxBoolProp">hello</div></div>',
  directives: [SomeImperativeViewport],
)
class MovesEmbeddedViewComponent {
  bool ctxBoolProp = false;

  @ViewChild(SomeImperativeViewport)
  SomeImperativeViewport? viewport;
}

@Directive(
  selector: '[has-property]',
)
class PropertyDirective {
  @Input('property')
  String? value;
}

@Component(
  selector: 'unknown-property-on-directive',
  template: '<div has-property [property]="value"></div>',
  directives: [PropertyDirective],
)
class UnknownPropertyOnDirectiveComponent {
  String value = 'Hello world!';
}

@Directive(
  selector: '[title]',
)
class DirectiveWithTitle {
  @Input()
  String? title;
}

@Component(
  selector: 'overridden-property',
  template: '<span [title]="name"></span>',
  directives: [DirectiveWithTitle],
)
class OverriddenPropertyComponent {
  String name = 'TITLE';
}

@Directive(
  selector: '[title]',
)
class DirectiveWithTitleAndHostProperty {
  @HostBinding()
  @Input()
  String? title;
}

@Component(
  selector: 'directive-updates-dom',
  template: '<span [title]="name"></span>',
  directives: [DirectiveWithTitleAndHostProperty],
)
class DirectiveUpdatesDomComponent {
  String name = 'TITLE';
}

@Directive(
  selector: 'with-prop-decorators',
)
class DirectiveWithPropDecorators {
  final StreamController<String> _streamController = StreamController<String>();
  Element? target;

  @Input('elProp')
  String? dirProp;

  @Output('elEvent')
  Stream<String> get event => _streamController.stream;

  @HostBinding('attr.my-attr')
  String? myAttr;

  @HostListener('click', ['\$event.target'])
  void onClick(Element target) {
    this.target = target;
  }

  void fireEvent(String message) {
    _streamController.add(message);
  }
}

@Component(
  selector: 'uses-input-decorator',
  template: '''
<with-prop-decorators elProp="foo" (elEvent)="value='called'">
</with-prop-decorators>''',
  directives: [DirectiveWithPropDecorators],
)
class DecoratorsComponent {
  String? value;

  @ViewChild(DirectiveWithPropDecorators)
  DirectiveWithPropDecorators? directive;
}

@Component(
  selector: 'svg-elements',
  template: '''
<svg>
  <use xlink:href="Port"/>
</svg>
<svg>
  <foreignObject>
    <xhtml:div>
      <p>Test</p>
    </xhtml:div>
  </foreignObject>
</svg>
''',
)
class SvgElementsComponent {}

@Component(
  selector: 'namespace-attribute',
  template: '<svg:use xlink:href="#id"/>',
)
class NamespaceAttributeComponent {}

@Component(
  selector: 'namespace-attribute-binding',
  template: '<svg:use [attr.xlink:href]="value"/>',
)
class NamespaceAttributeBindingComponent {
  String? value;
}
