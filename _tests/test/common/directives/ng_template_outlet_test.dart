@TestOn('browser')
import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/common/directives/ng_template_outlet.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_template_outlet_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  tearDown(disposeAnyRunningTest);

  group("insert", () {
    test("should do nothing if templateRef is null", () async {
      var testBed = new NgTestBed<TestWithNullComponent>();
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      expect(element, hasTextContent(""));
    });

    test("should insert content specified by TemplateRef", () async {
      var testBed = new NgTestBed<TestInsertContentComponent>();
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      expect(element, hasTextContent(""));
      CaptureTplRefs refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestInsertContentComponent componentInstance) {
        componentInstance.currentTplRef = refs.tplRefs.first;
      });
      expect(element, hasTextContent("foo"));
    });
    test("should clear content if TemplateRef becomes null", () async {
      var testBed = new NgTestBed<TestClearContentComponent>();
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      CaptureTplRefs refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestClearContentComponent componentInstance) {
        componentInstance.currentTplRef = refs.tplRefs.first;
      });
      expect(element, hasTextContent("foo"));
      await testFixture.update((TestClearContentComponent componentInstance) {
        // Set it back to null.
        componentInstance.currentTplRef = null;
      });
      expect(element, hasTextContent(""));
    });

    test("should swap content if TemplateRef changes", () async {
      var testBed = new NgTestBed<TestChangeContentComponent>();
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      CaptureTplRefs refs = testFixture.assertOnlyInstance.refs;
      await testFixture.update((TestChangeContentComponent componentInstance) {
        componentInstance.currentTplRef = refs.tplRefs.first;
      });
      expect(element, hasTextContent("foo"));
      await testFixture.update((TestChangeContentComponent componentInstance) {
        componentInstance.currentTplRef = refs.tplRefs.last;
      });
      expect(element, hasTextContent("bar"));
    });
  });

  group('[ngTemplateOutletContext]', () {
    test('should update on changes', () async {
      final testBed = new NgTestBed<TestContextChangeComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text, 'foo');
      await testFixture.update((component) {
        component.context['\$implicit'] = 'bar';
      });
      expect(testFixture.text, 'bar');
    });

    test('should update when identity changes', () async {
      final testBed = new NgTestBed<TestContextChangeComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text, 'foo');
      await testFixture.update((component) {
        component.context = {
          '\$implicit': 'bar',
        };
      });
      expect(testFixture.text, 'bar');
    });

    test('should update when map proxy changes', () async {
      final testBed = new NgTestBed<TestContextProxyChangeComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text, 'foo');
      await testFixture.update((component) {
        component.contextValue = 'bar';
      });
      expect(testFixture.text, 'bar');
    });

    test('should reapply when [ngTemplateOutlet] changes', () async {
      final testBed = new NgTestBed<TestContextTemplateRefChangeComponent>();
      final testFixture = await testBed.create();
      expect(testFixture.text, 'Hello world!');
      await testFixture.update((component) {
        component.isGreeting = false;
      });
      expect(testFixture.text, 'Goodbye world!');
    });

    test('should support *-syntax', () async {
      final testBed = new NgTestBed<TestStarSyntax>();
      final testFixture = await testBed.create();
      expect(
        testFixture.text,
        testFixture.assertOnlyInstance.templateContext['message'],
      );
    });
  });
}

@Directive(
  selector: "tpl-refs",
  exportAs: "tplRefs",
)
class CaptureTplRefs {
  @ContentChildren(TemplateRef)
  List<TemplateRef> tplRefs;
}

@Component(
  selector: "test-cmp",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: "",
)
class TestComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: "test-cmp-null",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<template [ngTemplateOutlet]="null"></template>',
)
class TestWithNullComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: "test-cmp-insert-content",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
)
class TestInsertContentComponent {
  TemplateRef currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs refs;
}

@Component(
  selector: 'test-clear-content',
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
)
class TestClearContentComponent {
  TemplateRef currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs refs;
}

@Component(
  selector: 'test-change-content',
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template><template>'
      'bar</template></tpl-refs><template '
      '[ngTemplateOutlet]="currentTplRef"></template>',
)
class TestChangeContentComponent {
  TemplateRef currentTplRef;

  @ViewChild('refs')
  CaptureTplRefs refs;
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
  directives: const [NgTemplateOutlet],
)
class TestContextChangeComponent {
  Map<String, dynamic> context = {
    '\$implicit': 'foo',
  };
}

@Component(
  selector: 'test-context-proxy-change',
  template: '''
    <template #template let-text>{{text}}</template>
    <template
        [ngTemplateOutlet]="template"
        [ngTemplateOutletContext]="{'\$implicit': contextValue}">
    </template>
  ''',
  directives: const [NgTemplateOutlet],
)
class TestContextProxyChangeComponent {
  String contextValue = 'foo';
}

@Component(
  selector: 'test-context-template-ref-change',
  template: '''
    <template #greet let-text>Hello {{text}}!</template>
    <template #farewell let-text>Goodbye {{text}}!</template>
    <template
        [ngTemplateOutlet]="isGreeting ? greet : farewell"
        [ngTemplateOutletContext]="{'\$implicit': 'world'}">
    </template>
  ''',
  directives: const [NgTemplateOutlet],
)
class TestContextTemplateRefChangeComponent {
  bool isGreeting = true;
}

@Component(
  selector: 'test',
  template: '''
    <template #templateRef let-msg="message">{{msg}}</template>
    <ng-container *ngTemplateOutlet="templateRef; context: templateContext">
    </ng-container>
  ''',
  directives: const [NgTemplateOutlet],
)
class TestStarSyntax {
  Map<String, dynamic> templateContext = {'message': 'Hello world!'};
}
