@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/debug/debug_node.dart';

import 'directive_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support nested components', () async {
    final testBed = new NgTestBed<ParentComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello');
  });

  test('should consume directive input binding', () async {
    final testBed = new NgTestBed<BoundDirectiveInputComponent>();
    final testFixture = await testBed.create();
    final divs = testFixture.rootElement.children.map(getDebugNode).toList();
    await testFixture.update((component) => component.value = 'New property');
    expect(divs[0].inject(MyDir).dirProp, 'New property');
    expect(divs[1].inject(MyDir).dirProp, 'Hi there!');
    expect(divs[2].inject(MyDir).dirProp, 'Hi there!');
    expect(divs[3].inject(MyDir).dirProp, 'One more New property');
  });

  test('should support multiple directives on a single node', () async {
    final testBed = new NgTestBed<MultipleDirectivesComponent>();
    final testFixture = await testBed.create();
    final child = getDebugNode(testFixture.rootElement.querySelector('child'));
    expect(child.inject(MyDir).dirProp, 'Hello world!');
    expect(testFixture.text, 'hello');
  });

  test('should support directives missing input bindings', () async {
    final testBed = new NgTestBed<UnboundDirectiveInputComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, isEmpty);
  });

  test('should execute a directive once, even if specified multiple times',
      () async {
    final testBed = new NgTestBed<DuplicateDirectivesComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'noduplicate');
  });

  test('should support directives whose selector matches native property',
      () async {
    final testBed = new NgTestBed<OverrideNativePropertyComponent>();
    final testFixture = await testBed.create();
    final div = getDebugNode(testFixture.rootElement.querySelector('div'));
    expect(div.inject(IdDir).id, 'some_id');
    await testFixture.update((component) => component.value = 'other_id');
    expect(div.inject(IdDir).id, 'other_id');
  });

  test('should support directives whose selector matches event binding',
      () async {
    final testBed = new NgTestBed<EventDirectiveComponent>();
    final testFixture = await testBed.create();
    final p = getDebugNode(testFixture.rootElement.querySelector('p'));
    expect(p.inject(EventDir), isNotNull);
  });

  test('should read directives metadata from their binding token', () async {
    final testBed = new NgTestBed<RetrievesDependencyFromHostComponent>();
    await testBed.create(); // Directive constructor tests expected condition.
  });

  test('should consume pipe binding', () async {
    final testBed = new NgTestBed<PipedDirectiveInputComponent>();
    final testFixture = await testBed.create();
    final div = getDebugNode(testFixture.rootElement.querySelector('div'));
    expect(div.getLocal('dir').dirProp, 'aa');
  });

  test('should not bind attribute matcher when generating host view', () async {
    // This test will fail on DDC if [width] in host template generates
    // invalid code to initialize width.
    final testBed = new NgTestBed<SimpleButton>();
    await testBed.create();
  });
  test('should not bind attribute matcher when generating host view', () async {
    // This test will fail on DDC if [width] in host template generates
    // invalid code to initialize width.
    final testBed = new NgTestBed<SimpleInput>();
    await testBed.create();
  });
}

@Component(
  selector: 'input[type=text][width]',
  template: 'Test',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SimpleInput {
  @Input()
  int width;
}

@Component(
  selector: 'button[width]',
  template: 'Test',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class SimpleButton {
  @Input()
  int width;
}

@Directive(
  selector: '[my-dir]',
  exportAs: 'myDir',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MyDir {
  @Input('elProp')
  String dirProp = '';
}

@Component(
  selector: 'bound-directive-input',
  template: '<div my-dir [elProp]="value"></div>'
      '<div my-dir elProp="Hi there!"></div>'
      '<div my-dir elProp="Hi {{\'there!\'}}"></div>'
      '<div my-dir elProp="One more {{value}}"></div>',
  directives: const [
    MyDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class BoundDirectiveInputComponent {
  String value = 'Initial value';
}

@Injectable()
class MyService {
  String greeting = 'hello';
}

@Component(
  selector: 'child',
  template: '{{value}}',
  viewProviders: const [
    MyService,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ChildComponent {
  String value;

  ChildComponent(MyService service) {
    value = service.greeting;
  }
}

@Component(
  selector: 'parent',
  template: '<child></child>',
  directives: const [
    ChildComponent,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ParentComponent {}

@Component(
  selector: 'multiple-directives',
  template: '<child my-dir [elProp]="value"></child>',
  directives: const [
    ChildComponent,
    MyDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class MultipleDirectivesComponent {
  String value = 'Hello world!';
}

@Component(
  selector: 'unbound-directive-input',
  template: '<div my-dir></div>',
  directives: const [
    MyDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class UnboundDirectiveInputComponent {}

@Directive(
  selector: '[no-duplicate]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DuplicateDir {
  DuplicateDir(HtmlElement element) {
    element.text = '${element.text}noduplicate';
  }
}

@Component(
  selector: 'duplicate-directives',
  template: '<div no-duplicate></div>',
  directives: const [
    DuplicateDir,
    DuplicateDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DuplicateDirectivesComponent {}

@Directive(
  selector: '[id]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class IdDir {
  @Input()
  String id;
}

@Component(
  selector: 'override-native-property',
  template: '<div [id]="value"></div>',
  directives: const [
    IdDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class OverrideNativePropertyComponent {
  String value = 'some_id';
}

@Directive(
  selector: '[customEvent]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EventDir {
  final _streamController = new StreamController<String>();

  @Output()
  Stream<String> get customEvent => _streamController.stream;
}

@Component(
  selector: 'event-directive',
  template: '<p (customEvent)="doNothing()"></p>',
  directives: const [
    EventDir,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class EventDirectiveComponent {
  void doNothing() {}
}

@Injectable()
class PublicApi {}

@Directive(
  selector: '[public-api]',
  providers: const [
    const Provider(PublicApi, useExisting: PrivateImpl),
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PrivateImpl extends PublicApi {}

@Directive(
  selector: '[needs-public-api]',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class NeedsPublicApi {
  NeedsPublicApi(@Host() PublicApi api) {
    expect(api, new isInstanceOf<PrivateImpl>());
  }
}

@Component(
  selector: 'retrieves-dependency-from-host',
  template: '<div public-api><div needs-public-api></div></div>',
  directives: const [
    PrivateImpl,
    NeedsPublicApi,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class RetrievesDependencyFromHostComponent {}

@Pipe('double')
class DoublePipe implements PipeTransform {
  String transform(dynamic value) => '$value$value';
}

@Component(
  selector: 'piped-directive-input',
  template: '<div my-dir #dir="myDir" [elProp]="value | double"></div>',
  directives: const [
    MyDir,
  ],
  pipes: const [
    DoublePipe,
  ],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class PipedDirectiveInputComponent {
  String value = 'a';
}
