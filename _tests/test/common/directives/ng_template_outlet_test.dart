import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_template_outlet_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  group('insert', () {
    test('should do nothing if templateRef is null', () async {
      var testBed = NgTestBed(ng.createTestWithNullComponentFactory());
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      expect(element, hasTextContent(''));
    });

    test('should insert content specified by TemplateRef', () async {
      var testBed = NgTestBed(ng.createTestInsertContentComponentFactory());
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      expect(element, hasTextContent(''));
      var refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestInsertContentComponent componentInstance) {
        componentInstance.currentTplRef = refs!.tplRefs!.first;
      });
      expect(element, hasTextContent('foo'));
    });

    test('should clear content if TemplateRef becomes null', () async {
      var testBed = NgTestBed(ng.createTestClearContentComponentFactory());
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      var refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestClearContentComponent componentInstance) {
        componentInstance.currentTplRef = refs!.tplRefs!.first;
      });
      expect(element, hasTextContent('foo'));
      await testFixture.update((TestClearContentComponent componentInstance) {
        // Set it back to null.
        componentInstance.currentTplRef = null;
      });
      expect(element, hasTextContent(''));
    });

    test('should swap content if TemplateRef changes', () async {
      var testBed = NgTestBed(ng.createTestChangeContentComponentFactory());
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      var refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestChangeContentComponent componentInstance) {
        componentInstance.currentTplRef = refs!.tplRefs!.first;
      });
      expect(element, hasTextContent('foo'));
      await testFixture.update((TestChangeContentComponent componentInstance) {
        componentInstance.currentTplRef = refs!.tplRefs!.last;
      });
      expect(element, hasTextContent('bar'));
    });
  });

  group('[ngTemplateOutletContext]', () {
    test('should update on changes', () async {
      final testBed = NgTestBed(ng.createTestContextChangeComponentFactory());
      final testFixture = await testBed.create();
      expect(testFixture.text, contains('foo'));
      await testFixture.update((component) {
        component.context['\$implicit'] = 'bar';
      });
      expect(testFixture.text, contains('bar'));
    });

    test('should update when identity changes', () async {
      final testBed = NgTestBed(ng.createTestContextChangeComponentFactory());
      final testFixture = await testBed.create();
      expect(testFixture.text, contains('foo'));
      await testFixture.update((component) {
        component.context = {
          '\$implicit': 'bar',
        };
      });
      expect(testFixture.text, contains('bar'));
    });

    test('should reapply when [ngTemplateOutlet] changes', () async {
      final testBed =
          NgTestBed(ng.createTestContextTemplateRefChangeComponentFactory());
      final testFixture = await testBed.create();
      expect(testFixture.text, contains('Hello world!'));
      await testFixture.update((component) {
        component.isGreeting = false;
      });
      expect(testFixture.text, contains('Goodbye world!'));
    });

    test('should support *-syntax', () async {
      final testBed = NgTestBed(ng.createTestStarSyntaxFactory());
      final testFixture = await testBed.create();
      expect(
        testFixture.text,
        contains(testFixture.assertOnlyInstance.templateContext['message']),
      );
    });
  });

  test('should support [ngTemplateOutletValue] as a short-hand', () async {
    final testBed = NgTestBed(ng.createTestValueInputFactory());
    final testFixture = await testBed.create(beforeChangeDetection: (c) {
      c.value = 'Hello World';
    });
    expect(testFixture.text, contains('Hello World'));
  });

  test('should not crash setting and resetting [ngTemplateOutlet]', () async {
    final testBed = NgTestBed(ng.createTestSetTemplateFactory());
    final testFixture = await testBed.create();
    await testFixture.update((component) {
      // This sets the active view within `NgTemplateOutlet`.
      component.activeTemplate = component.greetingTemplate;
    });
    expect(testFixture.text!.trim(), 'Hello world!');
    await testFixture.update((component) {
      // This incorrectly wouldn't invalidate the active view.
      component.activeTemplate = null;
    });
    expect(testFixture.text!.trim(), isEmpty);
    await testFixture.update((component) {
      // This would attempt to remove the previously active view a second time
      // and crash.
      component.activeTemplate = component.greetingTemplate;
    });
    expect(testFixture.text!.trim(), 'Hello world!');
  });
}

@Directive(
  selector: 'tpl-refs',
  exportAs: 'tplRefs',
)
class CaptureTplRefs {
  @ContentChildren(TemplateRef)
  List<TemplateRef>? tplRefs;
}

@Component(
  selector: 'test-cmp',
  directives: [NgTemplateOutlet, CaptureTplRefs],
  template: '',
)
class TestComponent {
  TemplateRef? currentTplRef;
}

@Component(
  selector: 'test-cmp-null',
  directives: [NgTemplateOutlet, CaptureTplRefs],
  template: '<template [ngTemplateOutlet]="null"></template>',
)
class TestWithNullComponent {
  TemplateRef? currentTplRef;
}

@Component(
  selector: 'test-cmp-insert-content',
  directives: [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
)
class TestInsertContentComponent {
  TemplateRef? currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs? refs;
}

@Component(
  selector: 'test-clear-content',
  directives: [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
)
class TestClearContentComponent {
  TemplateRef? currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs? refs;
}

@Component(
  selector: 'test-change-content',
  directives: [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template><template>'
      'bar</template></tpl-refs><template '
      '[ngTemplateOutlet]="currentTplRef"></template>',
)
class TestChangeContentComponent {
  TemplateRef? currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs? refs;
}

@Component(
  selector: 'test-context-change',
  template: '''
    <template #template let-text>{{text}}</template>
    <template
        [ngTemplateOutlet]="template"
        [ngTemplateOutletContext]="context">
    </template>
  ''',
  directives: [NgTemplateOutlet],
)
class TestContextChangeComponent {
  Map<String, dynamic> context = {
    '\$implicit': 'foo',
  };
}

@Component(
  selector: 'test-context-template-ref-change',
  template: '''
    <template #greet let-text>Hello {{text}}!</template>
    <template #farewell let-text>Goodbye {{text}}!</template>
    <template
        [ngTemplateOutlet]="isGreeting ? greet : farewell"
        [ngTemplateOutletContext]="context">
    </template>
  ''',
  directives: [NgTemplateOutlet],
)
class TestContextTemplateRefChangeComponent {
  static const context = {r'$implicit': 'world'};

  bool isGreeting = true;
}

@Component(
  selector: 'test',
  template: '''
    <template #templateRef let-msg="message">{{msg}}</template>
    <ng-container *ngTemplateOutlet="templateRef; context: templateContext">
    </ng-container>
  ''',
  directives: [NgTemplateOutlet],
)
class TestStarSyntax {
  Map<String, dynamic> templateContext = {'message': 'Hello world!'};
}

@Component(
  selector: 'test',
  template: '''
    <template #templateRef let-message>{{message}}</template>
    <template [ngTemplateOutlet]="templateRef" [ngTemplateOutletValue]="value"></template>
  ''',
  directives: [NgTemplateOutlet],
)
class TestValueInput {
  String? value;
}

@Component(
  selector: 'test',
  template: '''
    <template #greeting>Hello world!</template>
    <ng-container *ngTemplateOutlet="activeTemplate"></ng-container>
  ''',
  directives: [NgTemplateOutlet],
)
class TestSetTemplate {
  @ViewChild('greeting')
  TemplateRef? greetingTemplate;
  TemplateRef? activeTemplate;
}
