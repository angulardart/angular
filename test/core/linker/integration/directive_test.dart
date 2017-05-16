@Tags(const ['codegen'])
@TestOn('browser')

import 'dart:async';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
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
}

@Directive(
  selector: '[my-dir]',
  exportAs: 'myDir',
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
)
class ParentComponent {}

@Component(
  selector: 'multiple-directives',
  template: '<child my-dir [elProp]="value"></child>',
  directives: const [
    ChildComponent,
    MyDir,
  ],
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
)
class UnboundDirectiveInputComponent {}

@Directive(selector: '[no-duplicate]')
class DuplicateDir {
  DuplicateDir(ElementRef elementRef) {
    final element = elementRef.nativeElement;
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
)
class DuplicateDirectivesComponent {}

@Directive(selector: '[id]')
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
)
class OverrideNativePropertyComponent {
  String value = 'some_id';
}

@Directive(selector: '[customEvent]')
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
)
class EventDirectiveComponent {
  void doNothing() {}
}

@Injectable()
class PublicApi {}

@Directive(selector: '[public-api]', providers: const [
  const Provider(PublicApi, useExisting: PrivateImpl),
])
class PrivateImpl extends PublicApi {}

@Directive(selector: '[needs-public-api]')
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
)
class PipedDirectiveInputComponent {
  String value = 'a';
}
