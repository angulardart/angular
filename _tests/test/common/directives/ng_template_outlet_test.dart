@TestOn('browser')
import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/common/directives/ng_template_outlet.dart';
import 'package:angular/src/debug/debug_node.dart';
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
      DebugElement debugElement = getDebugNode(element);
      CaptureTplRefs refs = debugElement.children[0].getLocal("refs");
      await testFixture.update((TestInsertContentComponent componentInstance) {
        componentInstance.currentTplRef = refs.tplRefs.first;
      });
      expect(element, hasTextContent("foo"));
    });
    test("should clear content if TemplateRef becomes null", () async {
      var testBed = new NgTestBed<TestClearContentComponent>();
      var testFixture = await testBed.create();
      var element = testFixture.rootElement;
      DebugElement debugElement = getDebugNode(element);
      CaptureTplRefs refs = debugElement.children[0].getLocal("refs");
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
      DebugElement debugElement = getDebugNode(element);
      CaptureTplRefs refs = debugElement.children[0].getLocal("refs");
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
  });
}

@Directive(
  selector: "tpl-refs", exportAs: "tplRefs",
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class CaptureTplRefs {
  @ContentChildren(TemplateRef)
  List<TemplateRef> tplRefs;
}

@Component(
  selector: "test-cmp",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: "",
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: "test-cmp-null",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<template [ngTemplateOutlet]="null"></template>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestWithNullComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: "test-cmp-insert-content",
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestInsertContentComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: 'test-clear-content',
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestClearContentComponent {
  TemplateRef currentTplRef;
}

@Component(
  selector: 'test-change-content',
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template><template>'
      'bar</template></tpl-refs><template '
      '[ngTemplateOutlet]="currentTplRef"></template>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestChangeContentComponent {
  TemplateRef currentTplRef;
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
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
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContextProxyChangeComponent {
  String contextValue = 'foo';
}

@Component(
  selector: 'text-context-template-ref-change',
  template: '''
    <template #greet let-text>Hello {{text}}!</template>
    <template #farewell let-text>Goodbye {{text}}!</template>
    <template
        [ngTemplateOutlet]="isGreeting ? greet : farewell"
        [ngTemplateOutletContext]="{'\$implicit': 'world'}">
    </template>
  ''',
  directives: const [NgTemplateOutlet],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class TestContextTemplateRefChangeComponent {
  bool isGreeting = true;
}
