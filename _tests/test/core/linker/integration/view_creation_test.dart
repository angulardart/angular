@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

import 'view_creation_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support imperative views', () async {
    final testBed = new NgTestBed<SimpleImperativeViewComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello imp view');
  });

  test('should support moving embedded views', () async {
    final template = new TemplateElement()..append(new DivElement());
    final testBed = new NgTestBed<MovesEmbeddedViewComponent>().addProviders([
      provide(ANCHOR_ELEMENT, useValue: template),
    ]);
    final testFixture = await testBed.create();
    final nestedDiv = testFixture.rootElement.firstChild.firstChild;
    final viewport = getDebugNode(nestedDiv).inject(SomeImperativeViewport);
    expect(viewport.anchor.text, '');
    await testFixture.update((component) => component.ctxBoolProp = true);
    expect(viewport.anchor.text, 'hello');
    await testFixture.update((component) => component.ctxBoolProp = false);
    expect(viewport.anchor.text, '');
  });

  group('property bindings', () {
    test("shouldn't throw if unknown property exists on directive", () async {
      final testBed = new NgTestBed<UnknownPropertyOnDirectiveComponent>();
      await testBed.create();
    });

    test("shouldn't be created when a directive property has the same name",
        () async {
      final testBed = new NgTestBed<OverriddenPropertyComponent>();
      final testFixture = await testBed.create();
      final span = testFixture.rootElement.querySelector('span');
      expect(span.title, isEmpty);
    });

    test('should allow directive host property to update DOM', () async {
      final testBed = new NgTestBed<DirectiveUpdatesDomComponent>();
      final testFixture = await testBed.create();
      final span = testFixture.rootElement.querySelector('span');
      expect(span.title, 'TITLE');
    });
  });

  group('property decorators', () {
    test('should support @Input', () async {
      final testBed = new NgTestBed<DecoratorsComponent>();
      final testFixture = await testBed.create();
      final debugNode = getDebugNode(testFixture.rootElement.firstChild);
      final directive = debugNode.inject(DirectiveWithPropDecorators);
      expect(directive.dirProp, 'foo');
    });

    test('should support @HostBinding', () async {
      final testBed = new NgTestBed<DecoratorsComponent>();
      final testFixture = await testBed.create();
      final directiveElement = testFixture.rootElement.children.first;
      final debugNode = getDebugNode(directiveElement);
      final directive = debugNode.inject(DirectiveWithPropDecorators);
      await testFixture.update((_) => directive.myAttr = 'bar');
      expect(directiveElement.attributes, containsPair('my-attr', 'bar'));
    });

    test('should support @Output', () async {
      final testBed = new NgTestBed<DecoratorsComponent>();
      final testFixture = await testBed.create();
      final directiveElement = testFixture.rootElement.children.first;
      final debugNode = getDebugNode(directiveElement);
      final directive = debugNode.inject(DirectiveWithPropDecorators);
      var component;
      await testFixture.update((instance) {
        component = instance;
        expect(component.value, isNull);
        directive.fireEvent('fired!');
      });
      expect(component.value, 'called');
    });

    test('should support @HostListener', () async {
      final testBed = new NgTestBed<DecoratorsComponent>();
      final testFixture = await testBed.create();
      final directiveElement = testFixture.rootElement.children.first;
      final debugNode = getDebugNode(directiveElement);
      final directive = debugNode.inject(DirectiveWithPropDecorators);
      expect(directive.target, isNull);
      directiveElement.dispatchEvent(new MouseEvent('click'));
      await testFixture.update();
      expect(directive.target, directiveElement);
    });
  });

  test('should support svg elements', () async {
    final testBed = new NgTestBed<SvgElementsComponent>();
    final testFixture = await testBed.create();
    final svg = testFixture.rootElement.querySelector('svg');
    expect(svg.namespaceUri, 'http://www.w3.org/2000/svg');
    final use = testFixture.rootElement.querySelector('use');
    expect(use.namespaceUri, 'http://www.w3.org/2000/svg');
    final foreignObject =
        testFixture.rootElement.querySelector('foreignObject');
    expect(foreignObject.namespaceUri, 'http://www.w3.org/2000/svg');
    final div = testFixture.rootElement.querySelector('div');
    expect(div.namespaceUri, 'http://www.w3.org/1999/xhtml');
    final p = testFixture.rootElement.querySelector('p');
    expect(p.namespaceUri, 'http://www.w3.org/1999/xhtml');
  });

  group('namespace attributes', () {
    test('should be supported', () async {
      final testBed = new NgTestBed<NamespaceAttributeComponent>();
      final testFixture = await testBed.create();
      final use = testFixture.rootElement.querySelector('use');
      expect(use.getAttributeNS('http://www.w3.org/1999/xlink', 'href'), '#id');
    });

    test('should support binding', () async {
      final testBed = new NgTestBed<NamespaceAttributeBindingComponent>();
      final testFixture = await testBed.create();
      final use = testFixture.rootElement.querySelector('use');
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SimpleImperativeViewComponent {
  SimpleImperativeViewComponent(ElementRef elementRef) {
    final hostElement = elementRef.nativeElement;
    hostElement.append(new Text('hello imp view'));
  }
}

const ANCHOR_ELEMENT = const OpaqueToken('AnchorElement');

@Directive(
  selector: '[someImpvp]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SomeImperativeViewport {
  ViewContainerRef vc;
  TemplateRef templateRef;
  EmbeddedViewRef view;
  var anchor;

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
      var nodes = view.rootNodes;
      for (var i = 0; i < nodes.length; i++) {
        anchor.append(nodes[i]);
      }
    }
  }
}

@Component(
  selector: 'moves-embedded-view',
  template: '<div><div *someImpvp="ctxBoolProp">hello</div></div>',
  directives: const [SomeImperativeViewport],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MovesEmbeddedViewComponent {
  bool ctxBoolProp = false;
}

@Directive(
  selector: '[has-property]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PropertyDirective {
  @Input('property')
  String value;
}

@Component(
  selector: 'unknown-property-on-directive',
  template: '<div has-property [property]="value"></div>',
  directives: const [PropertyDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class UnknownPropertyOnDirectiveComponent {
  String value = 'Hello world!';
}

@Directive(
  selector: '[title]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveWithTitle {
  @Input()
  String title;
}

@Component(
  selector: 'overridden-property',
  template: '<span [title]="name"></span>',
  directives: const [DirectiveWithTitle],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OverriddenPropertyComponent {
  String name = 'TITLE';
}

@Directive(
  selector: '[title]',
  host: const {'[title]': 'title'},
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveWithTitleAndHostProperty {
  @Input()
  String title;
}

@Component(
  selector: 'directive-updates-dom',
  template: '<span [title]="name"></span>',
  directives: const [DirectiveWithTitleAndHostProperty],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveUpdatesDomComponent {
  String name = 'TITLE';
}

@Directive(
  selector: 'with-prop-decorators',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveWithPropDecorators {
  final StreamController<String> _streamController =
      new StreamController<String>();
  var target;

  @Input('elProp')
  String dirProp;

  @Output('elEvent')
  Stream get event => _streamController.stream;

  @HostBinding('attr.my-attr')
  String myAttr;

  @HostListener('click', const ['\$event.target'])
  onClick(target) {
    this.target = target;
  }

  fireEvent(msg) {
    _streamController.add(msg);
  }
}

@Component(
  selector: 'uses-input-decorator',
  template: '''
<with-prop-decorators elProp="foo" (elEvent)="value='called'">
</with-prop-decorators>''',
  directives: const [DirectiveWithPropDecorators],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DecoratorsComponent {
  String value;
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SvgElementsComponent {}

@Component(
  selector: 'namespace-attribute',
  template: '<svg:use xlink:href="#id"/>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NamespaceAttributeComponent {}

@Component(
  selector: 'namespace-attribute-binding',
  template: '<svg:use [attr.xlink:href]="value"/>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NamespaceAttributeBindingComponent {
  String value;
}
