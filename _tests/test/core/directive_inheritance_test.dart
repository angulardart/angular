@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'directive_inheritance_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  group('@ContentChildren', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.contentChildren, hasLength(3));
    });

    test('selector should be overriden', () async {
      TestAnnotatedDerivedComponent testComponent;
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.contentChildren, hasLength(2));
    });
  });

  group('@HostBinding', () {
    test('should be inherited', () async {
      final testBed = new NgTestBed<TestDerivedComponent>();
      final testFixture = await testBed.create();
      final hostElement = testFixture.rootElement.querySelector('derived');
      expect(hostElement.attributes, containsPair('title', 'inherited'));
    });

    test('implementation should be overriden', () async {
      final testBed = new NgTestBed<TestOverrideComponent>();
      final testFixture = await testBed.create();
      final hostElement = testFixture.rootElement.querySelector('override');
      expect(hostElement.attributes, containsPair('title', 'overridden'));
    });

    test('should allow multiple bindings to inherited property', () async {
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      final testFixture = await testBed.create();
      final hostElement =
          testFixture.rootElement.querySelector('annotated-derived');
      expect(hostElement.attributes, containsPair('title', 'inherited'));
      expect(hostElement.attributes, containsPair('id', 'inherited'));
    });
  });

  group('@HostListener', () {
    test('should be inherited', () async {
      final testBed = new NgTestBed<TestDerivedComponent>();
      final testFixture = await testBed.create()
        ..rootElement
            .querySelector('derived')
            .dispatchEvent(new MouseEvent('click'));
      await testFixture.update((component) {
        expect(component.derivedComponent.clickMessage, 'Original message');
      });
    });

    test('implementation should be overriden', () async {
      final testBed = new NgTestBed<TestOverrideComponent>();
      final testFixture = await testBed.create()
        ..rootElement
            .querySelector('override')
            .dispatchEvent(new MouseEvent('click'));
      await testFixture.update((component) {
        expect(component.derivedComponent.clickMessage, 'Overridden message');
      });
    });
  });

  group('@Input', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..input = 'Hello';
      });
      expect(testComponent.derivedComponent.input, 'Hello');
    });

    test('implementation should be overridden', () async {
      TestOverrideComponent testComponent;
      final testBed = new NgTestBed<TestOverrideComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..input = 'Hello';
      });
      expect(testComponent.derivedComponent.input, 'Hello!');
    });
  });

  group('@Output', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..derivedComponent.dispatchOutput('Bye');
      });
      expect(testComponent.receivedOutput, 'Bye');
    });

    test('implementation should be overridden', () async {
      TestOverrideComponent testComponent;
      final testBed = new NgTestBed<TestOverrideComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..derivedComponent.dispatchOutput('Bye');
      });
      expect(testComponent.receivedOutput, 'Bye!');
    });
  });

  group('@ViewChildren', () {
    test('should be inherited', () async {
      TestDerivedComponent testComponent;
      final testBed = new NgTestBed<TestDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.viewChildren, hasLength(3));
    });

    test('selector should be overriden', () async {
      TestAnnotatedDerivedComponent testComponent;
      final testBed = new NgTestBed<TestAnnotatedDerivedComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component;
      });
      expect(testComponent.derivedComponent.viewChildren, hasLength(2));
    });
  });

  group('Component should inherit metadata', () {
    test('from Directive', () async {
      final testBed = new NgTestBed<TestDirectiveDerivedComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.input = 'Hello!';
      });
      expect(testFixture.text, 'Hello!');
    });

    test('from super', () async {
      final testBed = new NgTestBed<TestInheritMetadataComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.description = 'Inherited description';
      });
      expect(testFixture.text, 'Inherited description');
    });

    test('from interface', () async {
      final testBed = new NgTestBed<TestImplementMetadataComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.description = 'Implemented description';
      });
      expect(testFixture.text, 'Implemented description');
    });

    test('from interface implemented by mixin', () async {
      final testBed = new NgTestBed<TestMixesInInterface>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.input = 'Implemented through mixin';
      });
      expect(testFixture.text, 'Implemented through mixin');
    });

    test('from mixin', () async {
      final testBed = new NgTestBed<TestMixinMetadataComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.description = 'Mixed-in description';
      });
      expect(testFixture.text, 'Mixed-in description');
    });

    test('from all supertypes', () async {
      final testBed = new NgTestBed<TestMultipleSupertypesComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component.viewChild
          ..foo = '1'
          ..bar = '2'
          ..baz = '3';
      });
      final element =
          testFixture.rootElement.querySelector('multiple-supertypes');
      expect(element.attributes, containsPair('foo', '1'));
      expect(element.attributes, containsPair('bar', '2'));
      expect(element.attributes, containsPair('baz', '3'));
    });

    test('from most derived binding', () async {
      final testBed = new NgTestBed<TestMostDerivedMetadataComponent>();
      final testFixture =
          await testBed.create(beforeChangeDetection: (component) {
        component
          ..value = '1'
          ..fooValue = '2';
      });
      expect(testFixture.rootElement.attributes, containsPair('foo', '2'));
      expect(testFixture.rootElement.attributes, containsPair('bar', '1'));
    });
  });

  group('Directive', () {
    test('should inherit metadata', () async {
      TestDirectiveInheritMetadataComponent testComponent;
      final testBed = new NgTestBed<TestDirectiveInheritMetadataComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..tooltipMessage = 'Successfully inherited!';
      });
      expect(testComponent.directive.tooltip, 'Successfully inherited!');
    });

    test('can alias input name to match selector', () async {
      TestDirectiveAliasInputComponent testComponent;
      final testBed = new NgTestBed<TestDirectiveAliasInputComponent>();
      await testBed.create(beforeChangeDetection: (component) {
        testComponent = component..tooltipMessage = 'Successfully aliased!';
      });
      expect(testComponent.directive.tooltip, 'Successfully aliased!');
    });
  });
}

/// Base component from which all other components will be derived for testing.
@Component(
  selector: 'root',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RootComponent {
  final StreamController<String> _outputController =
      new StreamController<String>();

  String clickMessage;

  @HostBinding()
  String title = 'inherited';

  @HostListener('click')
  void onClick() {
    clickMessage = 'Original message';
  }

  @Input()
  String input;

  @Output()
  Stream<String> get output => _outputController.stream;

  @ContentChildren(QueryTargetComponent)
  List<QueryTargetComponent> contentChildren;

  @ViewChildren(QueryTargetComponent)
  List<QueryTargetComponent> viewChildren;

  void dispatchOutput(String outputData) {
    _outputController.add(outputData);
  }
}

/// Tests inherited metadata.
@Component(
  selector: 'derived',
  template: '''
    <ng-content></ng-content>
    <query-target></query-target>
    <query-target #view></query-target>
    <query-target #view></query-target>''',
  directives: const [QueryTargetComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DerivedComponent extends RootComponent {}

@Component(
  selector: 'query-target',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class QueryTargetComponent {}

@Component(
  selector: 'test-derived',
  template: '''
    <derived
        [input]="input"
        (output)="receivedOutput = \$event">
      <query-target></query-target>
      <query-target #content></query-target>
      <query-target #content></query-target>
    </derived>''',
  directives: const [DerivedComponent, QueryTargetComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestDerivedComponent {
  @ViewChild(DerivedComponent)
  DerivedComponent derivedComponent;

  String input;
  String receivedOutput;
}

/// Tests overriding inherited metadata implementations.
@Component(
  selector: 'override',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OverrideComponent extends RootComponent {
  String get title => 'overridden';

  void onClick() {
    clickMessage = 'Overridden message';
  }

  set input(String value) {
    super.input = '$value!';
  }

  Stream<String> get output => super.output.map((data) => '$data!');
}

@Component(
  selector: 'test-override',
  template: '''
    <override
        [input]="input"
        (output)="receivedOutput = \$event">
    </override>''',
  directives: const [OverrideComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestOverrideComponent {
  @ViewChild(OverrideComponent)
  OverrideComponent derivedComponent;

  String input;
  String receivedOutput;
}

/// Tests annotating fields already annotated in the base component.
@Component(
  selector: 'annotated-derived',
  template: '''
    <query-target></query-target>
    <query-target #view></query-target>
    <query-target #view></query-target>''',
  directives: const [QueryTargetComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class AnnotatedDerivedComponent extends RootComponent {
  @HostBinding('id')
  String get title => super.title;

  @ContentChildren('content')
  set contentChildren(List<QueryTargetComponent> value) {
    super.contentChildren = value;
  }

  @ViewChildren('view')
  set viewChildren(List<QueryTargetComponent> value) {
    super.viewChildren = value;
  }
}

@Component(
  selector: 'test-redefine',
  template: '''
    <annotated-derived>
      <query-target></query-target>
      <query-target #content></query-target>
      <query-target #content></query-target>
    </annotated-derived>''',
  directives: const [AnnotatedDerivedComponent, QueryTargetComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestAnnotatedDerivedComponent {
  @ViewChild(AnnotatedDerivedComponent)
  AnnotatedDerivedComponent derivedComponent;
}

@Directive(
  selector: 'base',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class BaseDirective {
  @Input()
  String input;
}

@Component(
  selector: 'directive-derived',
  template: '<div>{{input}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveDerivedComponent extends BaseDirective {}

@Component(
  selector: 'test-directive-derived',
  template: '<directive-derived [input]="input"></directive-derived>',
  directives: const [DirectiveDerivedComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestDirectiveDerivedComponent {
  String input;
}

class DescriptionInput {
  @Input()
  String description;
}

@Component(
  selector: 'inherit-metadata',
  template: '<div>{{description}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class InheritMetadataComponent extends DescriptionInput {}

@Component(
  selector: 'test-inherit-metadata',
  template: '<inherit-metadata [description]="description"></inherit-metadata>',
  directives: const [InheritMetadataComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestInheritMetadataComponent {
  String description;
}

@Component(
  selector: 'implement-metadata',
  template: '<div>{{description}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ImplementMetadataComponent implements DescriptionInput {
  String description;
}

@Component(
  selector: 'test-implement-metadata',
  template:
      '<implement-metadata [description]="description"></implement-metadata>',
  directives: const [ImplementMetadataComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestImplementMetadataComponent {
  String description;
}

@Component(
  selector: 'mixin-metadata',
  template: '<div>{{description}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MixinMetadataComponent extends Object with DescriptionInput {}

@Component(
  selector: 'test-mixin-metadata',
  template: '<mixin-metadata [description]="description"></mixin-metadata>',
  directives: const [MixinMetadataComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestMixinMetadataComponent {
  String description;
}

class FooAttribute {
  @HostBinding('attr.foo')
  String foo;
}

class BarAttribute {
  @HostBinding('attr.bar')
  String bar;
}

class BazAttribute {
  @HostBinding('attr.baz')
  String baz;
}

@Component(
  selector: 'multiple-supertypes',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MultipleSupertypesComponent extends FooAttribute
    with BarAttribute
    implements BazAttribute {
  String baz;
}

@Component(
  selector: 'test-multiple-supertypes',
  template: '<multiple-supertypes></multiple-supertypes>',
  directives: const [MultipleSupertypesComponent],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestMultipleSupertypesComponent {
  @ViewChild(MultipleSupertypesComponent)
  MultipleSupertypesComponent viewChild;
}

class Attributes {
  @HostBinding('attr.foo')
  @HostBinding('attr.bar')
  String value;
}

class OverrideFooAttributes extends Attributes {
  @HostBinding('attr.foo')
  String fooValue;
}

@Component(
  selector: 'test-most-derived-metadata',
  template: '',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestMostDerivedMetadataComponent extends OverrideFooAttributes {}

@Directive(
  selector: '[tooltip]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TooltipDirective {
  @Input()
  String tooltip;
}

@Directive(
  selector: '[fancyTooltip]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class FancyTooltipDirective extends TooltipDirective {
  @Input()
  set fancyTooltip(String value) => tooltip = value;
}

@Component(
  selector: 'test-directive-inherit-metadata',
  template: '<div fancyTooltip [tooltip]="tooltipMessage"></div>',
  directives: const [FancyTooltipDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestDirectiveInheritMetadataComponent {
  @ViewChild(FancyTooltipDirective)
  FancyTooltipDirective directive;

  String tooltipMessage;
}

@Component(
  selector: 'test-directive-override-binding',
  template: '<div [fancyTooltip]="tooltipMessage"></div>',
  directives: const [FancyTooltipDirective],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestDirectiveAliasInputComponent {
  @ViewChild(FancyTooltipDirective)
  FancyTooltipDirective directive;

  String tooltipMessage;
}

abstract class MixinInterface {
  @Input()
  set input(String value);
}

class MixinImplementsInterface implements MixinInterface {
  String input;
}

@Component(
  selector: 'mixes-in-interface',
  template: '<div>{{input}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MixesInInterface extends Object with MixinImplementsInterface {}

@Component(
  selector: 'test-mixes-in-interface',
  template: '<mixes-in-interface [input]="input"></mixes-in-interface>',
  directives: const [MixesInInterface],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestMixesInInterface {
  String input;
}
