@TestOn('browser')

import 'dart:async';
import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'directive_integration_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  test('should support nested components', () async {
    final testBed = NgTestBed<ParentComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'hello');
  });

  test('should consume directive input binding', () async {
    final testBed = NgTestBed<BoundDirectiveInputComponent>();
    final testFixture = await testBed.create();
    final directives = testFixture.assertOnlyInstance.directives;
    await testFixture.update((component) => component.value = 'New property');
    expect(directives[0].dirProp, 'New property');
    expect(directives[1].dirProp, 'Hi there!');
    expect(directives[2].dirProp, 'Hey there!!');
    expect(directives[3].dirProp, 'One more New property');
  });

  test('should support multiple directives on a single node', () async {
    final testBed = NgTestBed<MultipleDirectivesComponent>();
    final testFixture = await testBed.create();
    final directive = testFixture.assertOnlyInstance.directive;
    expect(directive.dirProp, 'Hello world!');
    expect(testFixture.text, 'hello');
  });

  test('should support directives missing input bindings', () async {
    final testBed = NgTestBed<UnboundDirectiveInputComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, isEmpty);
  });

  test('should execute a directive once, even if specified multiple times',
      () async {
    final testBed = NgTestBed<DuplicateDirectivesComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.text, 'noduplicate');
  });

  test('should support directives whose selector matches native property',
      () async {
    final testBed = NgTestBed<OverrideNativePropertyComponent>();
    final testFixture = await testBed.create();
    final directive = testFixture.assertOnlyInstance.directive;
    expect(directive.id, 'some_id');
    await testFixture.update((component) => component.value = 'other_id');
    expect(directive.id, 'other_id');
  });

  test('should support directives whose selector matches event binding',
      () async {
    final testBed = NgTestBed<EventDirectiveComponent>();
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.directive, isNotNull);
  });

  test('should read directives metadata from their binding token', () async {
    final testBed = NgTestBed<RetrievesDependencyFromHostComponent>();
    final testFixture = await testBed.create();
    final needsPublicApi = testFixture.assertOnlyInstance.needsPublicApi;
    expect(needsPublicApi.api, const TypeMatcher<PrivateImpl>());
  });

  test('should consume pipe binding', () async {
    final testBed = NgTestBed<PipedDirectiveInputComponent>();
    final testFixture = await testBed.create();
    final directive = testFixture.assertOnlyInstance.directive;
    expect(directive.dirProp, 'aa');
  });

  test('should not bind attribute matcher when generating host view', () async {
    // This test will fail on DDC if [width] in host template generates
    // invalid code to initialize width.
    final testBed = NgTestBed<SimpleButton>();
    await testBed.create();
  });
  test('should not bind attribute matcher when generating host view', () async {
    // This test will fail on DDC if [width] in host template generates
    // invalid code to initialize width.
    final testBed = NgTestBed<SimpleInput>();
    await testBed.create();
  });
}

@Component(
  selector: 'input[type=text][width]',
  template: 'Test',
)
class SimpleInput {
  @Input()
  int width;
}

@Component(
  selector: 'button[width]',
  template: 'Test',
)
class SimpleButton {
  @Input()
  int width;
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
      '<div my-dir elProp="Hey {{\'there!!\'}}"></div>'
      '<div my-dir elProp="One more {{value}}"></div>',
  directives: [
    MyDir,
  ],
)
class BoundDirectiveInputComponent {
  String value = 'Initial value';

  @ViewChildren(MyDir)
  List<MyDir> directives;
}

@Injectable()
class MyService {
  String greeting = 'hello';
}

@Component(
  selector: 'child',
  template: '{{value}}',
  viewProviders: [
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
  directives: [
    ChildComponent,
  ],
)
class ParentComponent {}

@Component(
  selector: 'multiple-directives',
  template: '<child my-dir [elProp]="value"></child>',
  directives: [
    ChildComponent,
    MyDir,
  ],
)
class MultipleDirectivesComponent {
  String value = 'Hello world!';

  @ViewChild(MyDir)
  MyDir directive;
}

@Component(
  selector: 'unbound-directive-input',
  template: '<div my-dir></div>',
  directives: [
    MyDir,
  ],
)
class UnboundDirectiveInputComponent {}

@Directive(
  selector: '[no-duplicate]',
)
class DuplicateDir {
  DuplicateDir(HtmlElement element) {
    element.text = '${element.text}noduplicate';
  }
}

@Component(
  selector: 'duplicate-directives',
  template: '<div no-duplicate></div>',
  directives: [
    DuplicateDir,
    DuplicateDir,
  ],
)
class DuplicateDirectivesComponent {}

@Directive(
  selector: '[id]',
)
class IdDir {
  @Input()
  String id;
}

@Component(
  selector: 'override-native-property',
  template: '<div [id]="value"></div>',
  directives: [
    IdDir,
  ],
)
class OverrideNativePropertyComponent {
  String value = 'some_id';

  @ViewChild(IdDir)
  IdDir directive;
}

@Directive(
  selector: '[customEvent]',
)
class EventDir {
  final _streamController = StreamController<String>();

  @Output()
  Stream<String> get customEvent => _streamController.stream;
}

@Component(
  selector: 'event-directive',
  template: '<p (customEvent)="doNothing()"></p>',
  directives: [
    EventDir,
  ],
)
class EventDirectiveComponent {
  @ViewChild(EventDir)
  EventDir directive;

  void doNothing() {}
}

@Injectable()
class PublicApi {}

@Directive(
  selector: '[public-api]',
  providers: [
    Provider(PublicApi, useExisting: PrivateImpl),
  ],
)
class PrivateImpl extends PublicApi {}

@Directive(
  selector: '[needs-public-api]',
)
class NeedsPublicApi {
  final PublicApi api;

  NeedsPublicApi(@Host() this.api);
}

@Component(
  selector: 'retrieves-dependency-from-host',
  template: '<div public-api><div needs-public-api></div></div>',
  directives: [
    PrivateImpl,
    NeedsPublicApi,
  ],
)
class RetrievesDependencyFromHostComponent {
  @ViewChild(NeedsPublicApi)
  NeedsPublicApi needsPublicApi;
}

@Pipe('double')
class DoublePipe implements PipeTransform {
  String transform(dynamic value) => '$value$value';
}

@Component(
  selector: 'piped-directive-input',
  template: '<div my-dir #dir="myDir" [elProp]="value | double"></div>',
  directives: [
    MyDir,
  ],
  pipes: [
    DoublePipe,
  ],
)
class PipedDirectiveInputComponent {
  String value = 'a';

  @ViewChild('dir')
  MyDir directive;
}
