@TestOn('browser')
import 'dart:async';

import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

import 'bound.dart';
import 'generic_component.dart';
import 'generics_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('components', () {
    test('should support a single concrete type argument', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestSingleConcreteTypeArgumentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<SingleGenericComponent<String>>());
    });

    test('should support multiple concrete type arguments', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestMultipleConcreteTypeArgumentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<MultipleGenericComponent<String, int>>());
    });

    test('should support a nested concrete type argument', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestNestedConcreteTypeArgumentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<SingleGenericComponent<List<String>>>());
    });

    test('should flow a type argument', () async {
      final testBed = NgTestBed.forComponent(ng.TestFlowTypeArgumentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<FlowTypeArgumentComponent<String>>());
      expect(testFixture.assertOnlyInstance.child.child,
          const TypeMatcher<SingleGenericComponent<String>>());
    });

    test('should distinctly type unique instances of same component', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestDistinctlyTypedDirectivesNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.children, [
        const TypeMatcher<SingleGenericComponent<int>>(),
        const TypeMatcher<SingleGenericComponent<String>>(),
      ]);
    });

    test('should support generics when @deferred', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestDeferredGenericComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<GenericComponent<String>>());
    });

    test('should instantiate to bounds', () async {
      final testBed =
          NgTestBed.forComponent(ng.TestBoundedGenericComponentNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.child,
          const TypeMatcher<BoundedGenericComponent<Bound>>());
    });
  });

  group('directives', () {
    test('should support generics', () async {
      final testBed = NgTestBed.forComponent(ng.TestGenericDirectiveNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.directive,
          const TypeMatcher<GenericDirective<String>>());
    });

    test('with a change detector host should support generics', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestGenericDirectiveWithChangeDetectorNgFactory);
      final testFixture = await testBed.create();
      expect(testFixture.assertOnlyInstance.directive,
          const TypeMatcher<GenericDirectiveWithChangeDetector<String>>());
    });

    test('should instantiate to bounds', () async {
      final testBed = NgTestBed.forComponent(
          ng.TestBoundedGenericDirectiveWithChangeDetectorNgFactory);
      final testFixture = await testBed.create();
      expect(
        testFixture.assertOnlyInstance.directive,
        const TypeMatcher<BoundedGenericDirectiveWithChangeDetector<Bound>>(),
      );
    });
  });
}

/// This base type serves as a trigger for any runtime type errors.
abstract class IO<T> {
  final _controller = StreamController<T>();

  @Input()
  set input(T value) {
    _controller.add(value);
  }

  @Output()
  Stream<T> get output => _controller.stream;
}

@Component(
  selector: 'generic',
  template: '',
)
class SingleGenericComponent<T> extends IO<T> {}

@Component(
  selector: 'generic',
  template: '',
)
class MultipleGenericComponent<K, V> extends IO<Map<K, V>> {}

@Component(
  selector: 'test',
  template: '<generic [input]="value" (output)="handle"></generic>',
  directives: [SingleGenericComponent],
  directiveTypes: [Typed<SingleGenericComponent<String>>()],
)
class TestSingleConcreteTypeArgument {
  @ViewChild(SingleGenericComponent)
  SingleGenericComponent child;

  var value = 'a';

  void handle(String output) {}
}

@Component(
  selector: 'test',
  template: '<generic [input]="value" (output)="handle"></generic>',
  directives: [MultipleGenericComponent],
  directiveTypes: [Typed<MultipleGenericComponent<String, int>>()],
)
class TestMultipleConcreteTypeArgument {
  @ViewChild(MultipleGenericComponent)
  MultipleGenericComponent child;

  var value = {'a': 1};

  void handle(Map<String, int> output) {}
}

@Component(
  selector: 'test',
  template: '<generic></generic>',
  directives: [SingleGenericComponent],
  directiveTypes: [Typed<SingleGenericComponent<List<String>>>()],
)
class TestNestedConcreteTypeArgument {
  @ViewChild(SingleGenericComponent)
  SingleGenericComponent child;

  var value = ['a'];

  void handle(List<String> output) {}
}

@Component(
  selector: 'flow',
  template: '<generic [input]="value" (output)="handle"></generic>',
  directives: [SingleGenericComponent],
  directiveTypes: [
    Typed<SingleGenericComponent>.of([#T])
  ],
)
class FlowTypeArgumentComponent<T> {
  @ViewChild(SingleGenericComponent)
  SingleGenericComponent child;

  @Input()
  T value;

  void handle(T output) {}
}

@Component(
  selector: 'test',
  template: '<flow [value]="value"></flow>',
  directives: [FlowTypeArgumentComponent],
  directiveTypes: [
    Typed<FlowTypeArgumentComponent<String>>(),
  ],
)
class TestFlowTypeArgument {
  @ViewChild(FlowTypeArgumentComponent)
  FlowTypeArgumentComponent child;

  var value = 'a';
}

@Component(
  selector: 'test',
  template: ''',
    <generic [input]="index" (output)="handleIndex" #indexed></generic>
    <generic [input]="name" (output)="handleName"></generic>
  ''',
  directives: [SingleGenericComponent],
  directiveTypes: [
    Typed<SingleGenericComponent<String>>(),
    Typed<SingleGenericComponent<int>>(on: 'indexed'),
  ],
)
class TestDistinctlyTypedDirectives {
  @ViewChildren(SingleGenericComponent)
  List<SingleGenericComponent> children;

  var index = 2;
  var name = 'a';

  void handleIndex(int output) {}
  void handleName(String output) {}
}

@Directive(selector: '[generic]')
class GenericDirective<T> extends IO<T> {}

@Component(
  selector: 'test',
  template: '<div generic [input]="value" (output)="handle"></div>',
  directives: [GenericDirective],
  directiveTypes: [Typed<GenericDirective<String>>()],
)
class TestGenericDirective {
  @ViewChild(GenericDirective)
  GenericDirective directive;

  var value = 'a';

  void handle(String output) {}
}

/// Change detectors are generated for directives with host bindings.
@Directive(selector: '[generic]')
class GenericDirectiveWithChangeDetector<T> extends IO<T> {
  T _input;

  @override
  set input(T value) {
    _input = value;
    super.input = value;
  }

  @HostBinding('attr.a')
  T get a => _input;
}

@Component(
  selector: 'test',
  template: '<div generic [input]="value" (output)="handle"></div>',
  directives: [GenericDirectiveWithChangeDetector],
  directiveTypes: [Typed<GenericDirectiveWithChangeDetector<String>>()],
)
class TestGenericDirectiveWithChangeDetector {
  @ViewChild(GenericDirectiveWithChangeDetector)
  GenericDirectiveWithChangeDetector directive;

  var value = 'a';

  void handle(String output) {}
}

@Directive(selector: '[generic]')
class BoundedGenericDirectiveWithChangeDetector<T extends Bound> extends IO<T> {
  T _input;

  @override
  set input(T value) {
    _input = value;
    super.input = value;
  }

  @HostBinding('attr.a')
  T get a => _input;
}

@Component(
  selector: 'test',
  template: '<div generic [input]="value" (output)="handle"></div>',
  directives: [BoundedGenericDirectiveWithChangeDetector],
)
class TestBoundedGenericDirectiveWithChangeDetector {
  @ViewChild(BoundedGenericDirectiveWithChangeDetector)
  BoundedGenericDirectiveWithChangeDetector directive;
  var value = Bound();

  void handle(Bound output) {}
}

@Component(
  selector: 'test',
  template: '<generic @deferred [input]="value" (output)="handle"></generic>',
  directives: [GenericComponent],
  directiveTypes: [Typed<GenericComponent<String>>()],
)
class TestDeferredGenericComponent {
  @ViewChild(GenericComponent)
  var child;
  var value = 'a';

  void handle(String output) {}
}

@Component(
  selector: 'generic',
  template: '',
)
class BoundedGenericComponent<T extends Bound> extends IO<T> {}

@Component(
  selector: 'test',
  template: '<generic [input]="value" (output)="handle"></generic>',
  directives: [BoundedGenericComponent],
)
class TestBoundedGenericComponent {
  @ViewChild(BoundedGenericComponent)
  BoundedGenericComponent child;
  var value = Bound();

  void handle(Bound output) {}
}
