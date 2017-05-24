@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.core.debug.debug_node_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular2/src/debug/debug_node.dart';
import 'package:angular_test/angular_test.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('debug element', () {
    tearDown(() => disposeAnyRunningTest());

    test("should list all child nodes", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      // The root component has 3 elements.
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.childNodes.length, 3);
    });

    test("should list all child nodes without whitespace", () async {
      var testBed = new NgTestBed<ParentCompNoWhitespace>();
      var fixture = await testBed.create();
      // The root component has 3 elements and no text node children.
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.childNodes.length, 3);
    });

    test("should list all component child elements", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var childEls = debugElement.children;
      // The root component has 3 elements in its view.
      expect(childEls.length, 3);
      Element element = childEls[0].nativeElement as Element;
      expect(element.classes, contains("parent1"));
      element = childEls[1].nativeElement as Element;
      expect(element.classes, contains("parent2"));
      element = childEls[2].nativeElement as Element;
      expect(element.classes, contains("child-comp-class"));
      // Get children nested under parent.
      var nested = childEls[0].children;
      expect(nested.length, 1);
      expect((nested[0].nativeElement as Element).classes,
          contains("parentnested"));
      var childComponent = childEls[2];
      var childCompChildren = childComponent.children;
      expect(childCompChildren.length, 2);
      expect((childCompChildren[0].nativeElement as Element).classes,
          contains("child"));
      expect((childCompChildren[1].nativeElement as Element).classes,
          contains("child"));
      var childNested = childCompChildren[0].children;
      expect(childNested.length, 1);
      expect((childNested[0].nativeElement as Element).classes,
          contains("childnested"));
    });

    test("should list conditional component child elements", () async {
      var testBed = new NgTestBed<ConditionalParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var childEls = debugElement.children;
      // The root component has 2 elements in its view.
      expect(childEls.length, 2);
      expect(
          (childEls[0].nativeElement as Element).classes, contains("parent"));
      expect((childEls[1].nativeElement as Element).classes,
          contains("cond-content-comp-class"));
      // Since startup condition in false, there should be no children.
      var conditionalContentComp = childEls[1];
      expect(conditionalContentComp.children, hasLength(0));
      await fixture.update((ConditionalParentComp component) {
        ConditionalContentComp childComp =
            conditionalContentComp.componentInstance;
        childComp.myBool = true;
      });
      expect(conditionalContentComp.children, hasLength(1));
    });

    test("should list child elements within viewports", () async {
      var testBed = new NgTestBed<UsingFor>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var childEls = debugElement.children;
      expect(childEls.length, 4);
      // The 4th child is the <ul>.
      var list = childEls[3];
      expect(list.children.length, 3);
    });

    test("should list element attributes", () async {
      var testBed = new NgTestBed<BankAccountApp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var bankElem = debugElement.children[0];
      expect(bankElem.attributes["bank"], "RBC");
      expect(bankElem.attributes["account"], "4747");
    });

    test("should query child elements by css", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var childTestEls = debugElement.queryAll(By.css("child-comp"));
      expect(childTestEls, hasLength(1));
      expect((childTestEls[0].nativeElement as Element).classes,
          contains("child-comp-class"));
    });

    test("should query child elements by directive", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var childTestEls = debugElement.queryAll(By.directive(MessageDir));
      expect(childTestEls, hasLength(4));
      expect((childTestEls[0].nativeElement as Element).classes,
          contains("parent1"));
      expect((childTestEls[1].nativeElement as Element).classes,
          contains("parentnested"));
      expect((childTestEls[2].nativeElement as Element).classes,
          contains("child"));
      expect((childTestEls[3].nativeElement as Element).classes,
          contains("childnested"));
    });

    test("should list providerTokens", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.providerTokens, contains(ParentCompProvider));
    });

    test("should list locals", () async {
      var testBed = new NgTestBed<LocalsComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.children[0].getLocal("alice") is MyDir, true);
    });

    test("should allow injecting from the element injector", () async {
      var testBed = new NgTestBed<ParentComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      var provider = debugElement.children[0].inject(ParentCompProvider);
      expect(provider is ParentCompProvider, true);
    });

    test("should trigger event handler", () async {
      var testBed = new NgTestBed<EventsComp>();
      var fixture = await testBed.create();
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.componentInstance.clicked, false);
      (debugElement.children[0].nativeElement as Element)
          .dispatchEvent(new MouseEvent('click'));
      expect(debugElement.componentInstance.clicked, true);
    });

    test("should list all child nodes even with malformed selector", () async {
      var testBed = new NgTestBed<ParentCompWithBadSelector>();
      var fixture = await testBed.create();
      // The root component has 3 elements.
      DebugElement debugElement = getDebugNode(fixture.rootElement);
      expect(debugElement.childNodes.length, 3);
    });
  });
}

/// Directive that logs bound value.
@Directive(selector: "[message]", inputs: const ["message"])
class MessageDir {
  Logger logger;

  MessageDir() {
    logger = new Logger("debug_element_test_logger");
  }
  set message(newMessage) {
    logger.info(newMessage);
  }
}

@Component(
    selector: 'child-comp',
    template: '''
        <div class="child" message="child">
          <span class="childnested" message="nestedchild">Child</span>
        </div>
        <span class="child" [innerHtml]="childBinding"></span>''',
    directives: const [MessageDir])
class ChildComp {
  final String childBinding = "Original";
}

@Injectable()
class ParentCompProvider {
  final List<String> log = [];
}

@Component(
    selector: "parent-comp",
    viewProviders: const [ParentCompProvider],
    template: '''
        <div class="parent1" message="parent">
          <span class="parentnested" message="nestedparent">Parent</span>
        </div>
        <span class="parent2" [innerHtml]="parentBinding"></span>
        <child-comp class="child-comp-class"></child-comp>''',
    directives: const [ChildComp, MessageDir])
class ParentComp {
  final String parentBinding = "OriginalParent";
}

@Component(
    selector: "parent-comp-no-ws",
    template: '''
        <div class="parent1" message="parent">
          <span class="parentnested" message="nestedparent">Parent</span>
        </div>
        <span class="parent2" [innerHtml]="parentBinding"></span>
        <child-comp class="child-comp-class"></child-comp>''',
    directives: const [ChildComp, MessageDir])
class ParentCompNoWhitespace {
  final String parentBinding = "OriginalParent";
}

@Component(
    selector: "cond-content-comp",
    template: '<div class="child" message="child" *ngIf="myBool">'
        '  <ng-content></ng-content>'
        '</div>',
    directives: const [NgIf, MessageDir])
class ConditionalContentComp {
  bool myBool = false;
}

@Component(
    selector: "conditional-parent-comp",
    template: '''
        <span class="parent" [innerHtml]="parentBinding"></span>
        <cond-content-comp class="cond-content-comp-class">
          <span class="from-parent"></span>
        </cond-content-comp>''',
    directives: const [ConditionalContentComp])
class ConditionalParentComp {
  String parentBinding = "OriginalParent";
}

@Component(
    selector: "using-for",
    viewProviders: const [],
    template: '''
        <span *ngFor="let thing of stuff" [innerHtml]="thing"></span>
        <ul message="list">
           <li *ngFor="let item of stuff" [innerHtml]="item"></li>
        </ul>''',
    directives: const [NgFor, MessageDir])
class UsingFor {
  List<String> stuff;
  UsingFor() {
    stuff = ["one", "two", "three"];
  }
}

@Component(
    selector: "bank-account",
    template: '''
   Bank Name: {{bank}}
   Account Id: {{id}}
 ''')
class BankAccount {
  @Input()
  String bank;

  @Input("account")
  String id;

  String normalizedBankName;
}

@Component(
    selector: "bank-account-app",
    template: '<bank-account bank="RBC" account="4747"></bank-account>',
    directives: const [BankAccount])
class BankAccountApp {}

@Directive(selector: "[mydir]", exportAs: "mydir")
class MyDir {}

@Component(
    selector: "locals-comp",
    template: '<div mydir #alice="mydir"></div>',
    directives: const [MyDir])
class LocalsComp {}

@Directive(selector: "custom-emitter", outputs: const ["myevent"])
class CustomEmitter {
  EventEmitter<dynamic> myevent;
  CustomEmitter() {
    myevent = new EventEmitter();
  }
}

@Component(
    selector: "events-comp",
    template: '''
        <button (click)="handleClick()"></button>''')
class EventsComp {
  bool clicked;
  bool customed;
  EventsComp() {
    clicked = false;
  }
  void handleClick() {
    clicked = true;
  }
}

@Component(
    selector: "    parent-comp-bad-selector",
    viewProviders: const [ParentCompProvider],
    template: '''
        <div class="parent1" message="parent">
          <span class="parentnested" message="nestedparent">Parent</span>
        </div>
        <span class="parent2" [innerHtml]="parentBinding"></span>
        <child-comp class="child-comp-class"></child-comp>''',
    directives: const [ChildComp, MessageDir])
class ParentCompWithBadSelector {
  final String parentBinding = "OriginalParent";
}
