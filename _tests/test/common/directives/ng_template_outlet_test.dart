@Tags(const ['codegen'])
@TestOn('browser')
import 'dart:html';

import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular/src/common/directives/ng_template_outlet.dart'
    show NgTemplateOutlet;
import 'package:angular/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';

import 'ng_template_outlet_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group("insert", () {
    tearDown(() => disposeAnyRunningTest());
    test("should do nothing if templateRef is null", () async {
      var testBed = new NgTestBed<TestWithNullComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
      expect(element, hasTextContent(""));
    });

    test("should insert content specified by TemplateRef", () async {
      var testBed = new NgTestBed<TestInsertContentComponent>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement;
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
      Element element = testFixture.rootElement;
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
      Element element = testFixture.rootElement;
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
}

@Directive(selector: "tpl-refs", exportAs: "tplRefs")
class CaptureTplRefs {
  @ContentChildren(TemplateRef)
  QueryList<TemplateRef> tplRefs;
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
}

@Component(
  selector: 'test-clear-content',
  directives: const [NgTemplateOutlet, CaptureTplRefs],
  template: '<tpl-refs #refs="tplRefs"><template>foo</template></tpl-refs>'
      '<template [ngTemplateOutlet]="currentTplRef"></template>',
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
)
class TestChangeContentComponent {
  TemplateRef currentTplRef;
}
