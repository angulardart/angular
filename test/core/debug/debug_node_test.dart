@TestOn('browser')
library angular2.test.core.debug.debug_node_test;

import "package:angular2/testing_internal.dart";
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;
import "package:angular2/src/facade/async.dart" show EventEmitter;
import "package:angular2/core.dart" show Injectable;
import "package:angular2/common.dart" show NgFor, NgIf;
import "package:angular2/platform/common_dom.dart" show By;
import "package:angular2/src/core/metadata.dart"
    show Directive, Component, Input;
import 'package:test/test.dart';

@Injectable()
class Logger {
  List<String> log;
  Logger() {
    this.log = [];
  }
  add(String thing) {
    this.log.add(thing);
  }
}

@Directive(selector: "[message]", inputs: const ["message"])
@Injectable()
class MessageDir {
  Logger logger;
  MessageDir(Logger logger) {
    this.logger = logger;
  }
  set message(newMessage) {
    this.logger.add(newMessage);
  }
}

@Component(
    selector: "child-comp",
    template: '''<div class="child" message="child">
               <span class="childnested" message="nestedchild">Child</span>
             </div>
             <span class="child" [innerHtml]="childBinding"></span>''',
    directives: const [MessageDir])
@Injectable()
class ChildComp {
  String childBinding;
  ChildComp() {
    this.childBinding = "Original";
  }
}

@Component(
    selector: "parent-comp",
    viewProviders: const [Logger],
    template: '''<div class="parent" message="parent">
               <span class="parentnested" message="nestedparent">Parent</span>
             </div>
             <span class="parent" [innerHtml]="parentBinding"></span>
             <child-comp class="child-comp-class"></child-comp>''',
    directives: const [ChildComp, MessageDir])
@Injectable()
class ParentComp {
  String parentBinding;
  ParentComp() {
    this.parentBinding = "OriginalParent";
  }
}

@Component(
    selector: "parent-comp2",
    viewProviders: const [Logger],
    template: '''<div class="parent" message="parent">
               <span class="parentnested" message="nestedparent">Parent</span>
             </div>
             <span class="parent" [innerHtml]="parentBinding"></span>
             <child-comp class="child-comp-class"></child-comp>''',
    directives: const [ChildComp, MessageDir],
    preserveWhitespace: true)
@Injectable()
class ParentComp2 {
  String parentBinding;
  ParentComp2() {
    this.parentBinding = "OriginalParent";
  }
}

@Directive(selector: "custom-emitter", outputs: const ["myevent"])
@Injectable()
class CustomEmitter {
  EventEmitter<dynamic> myevent;
  CustomEmitter() {
    this.myevent = new EventEmitter();
  }
}

@Component(
    selector: "events-comp",
    template: '''<button (click)="handleClick()"></button>
             <custom-emitter (myevent)="handleCustom()"></custom-emitter>''',
    directives: const [CustomEmitter])
@Injectable()
class EventsComp {
  bool clicked;
  bool customed;
  EventsComp() {
    this.clicked = false;
    this.customed = false;
  }
  handleClick() {
    this.clicked = true;
  }

  handleCustom() {
    this.customed = true;
  }
}

@Component(
    selector: "cond-content-comp",
    viewProviders: const [Logger],
    template:
        '''<div class="child" message="child" *ngIf="myBool"><ng-content></ng-content></div>''',
    directives: const [NgIf, MessageDir])
@Injectable()
class ConditionalContentComp {
  bool myBool = false;
}

@Component(
    selector: "conditional-parent-comp",
    viewProviders: const [Logger],
    template: '''<span class="parent" [innerHtml]="parentBinding"></span>
            <cond-content-comp class="cond-content-comp-class">
              <span class="from-parent"></span>
            </cond-content-comp>''',
    directives: const [ConditionalContentComp])
@Injectable()
class ConditionalParentComp {
  String parentBinding;
  ConditionalParentComp() {
    this.parentBinding = "OriginalParent";
  }
}

@Component(
    selector: "using-for",
    viewProviders: const [Logger],
    template: '''<span *ngFor="let thing of stuff" [innerHtml]="thing"></span>
            <ul message="list">
              <li *ngFor="let item of stuff" [innerHtml]="item"></li>
            </ul>''',
    directives: const [NgFor, MessageDir])
@Injectable()
class UsingFor {
  List<String> stuff;
  UsingFor() {
    this.stuff = ["one", "two", "three"];
  }
}

@Directive(selector: "[mydir]", exportAs: "mydir")
class MyDir {}

@Component(
    selector: "locals-comp",
    template: '''
   <div mydir #alice="mydir"></div>
 ''',
    directives: const [MyDir])
class LocalsComp {}

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
    selector: "test-app",
    template: '''
   <bank-account bank="RBC" account="4747"></bank-account>
 ''',
    directives: const [BankAccount])
class TestApp {}

main() {
  group("debug element", () {
    test("should list all child nodes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          // The root component has 3 elements and no text node children.
          expect(fixture.debugElement.childNodes.length, 3);
          completer.done();
        });
      });
    });
    test("should list all child nodes including whitespace", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp2).then((fixture) {
          fixture.detectChanges();
          // The root component has 3 elements and no text node children.
          expect(fixture.debugElement.childNodes.length, 5);
          completer.done();
        });
      });
    });
    test("should list all component child elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          var childEls = fixture.debugElement.children;
          // The root component has 3 elements in its view.
          expect(childEls.length, 3);
          expect(DOM.hasClass(childEls[0].nativeElement, "parent"), isTrue);
          expect(DOM.hasClass(childEls[1].nativeElement, "parent"), isTrue);
          expect(DOM.hasClass(childEls[2].nativeElement, "child-comp-class"),
              isTrue);
          var nested = childEls[0].children;
          expect(nested.length, 1);
          expect(DOM.hasClass(nested[0].nativeElement, "parentnested"), isTrue);
          var childComponent = childEls[2];
          var childCompChildren = childComponent.children;
          expect(childCompChildren.length, 2);
          expect(DOM.hasClass(childCompChildren[0].nativeElement, "child"),
              isTrue);
          expect(DOM.hasClass(childCompChildren[1].nativeElement, "child"),
              isTrue);
          var childNested = childCompChildren[0].children;
          expect(childNested.length, 1);
          expect(DOM.hasClass(childNested[0].nativeElement, "childnested"),
              isTrue);
          completer.done();
        });
      });
    });
    test("should list conditional component child elements", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ConditionalParentComp).then((fixture) {
          fixture.detectChanges();
          var childEls = fixture.debugElement.children;
          // The root component has 2 elements in its view.
          expect(childEls.length, 2);
          expect(DOM.hasClass(childEls[0].nativeElement, "parent"), isTrue);
          expect(
              DOM.hasClass(
                  childEls[1].nativeElement, "cond-content-comp-class"),
              isTrue);
          var conditionalContentComp = childEls[1];
          expect(conditionalContentComp.children.length, 0);
          conditionalContentComp.componentInstance.myBool = true;
          fixture.detectChanges();
          expect(conditionalContentComp.children.length, 1);
          completer.done();
        });
      });
    });
    test("should list child elements within viewports", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(UsingFor).then((fixture) {
          fixture.detectChanges();
          var childEls = fixture.debugElement.children;
          expect(childEls.length, 4);
          // The 4th child is the <ul>
          var list = childEls[3];
          expect(list.children.length, 3);
          completer.done();
        });
      });
    });
    test("should list element attributes", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(TestApp).then((fixture) {
          fixture.detectChanges();
          var bankElem = fixture.debugElement.children[0];
          expect(bankElem.attributes["bank"], "RBC");
          expect(bankElem.attributes["account"], "4747");
          completer.done();
        });
      });
    });
    test("should query child elements by css", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          var childTestEls =
              fixture.debugElement.queryAll(By.css("child-comp"));
          expect(childTestEls, hasLength(1));
          expect(
              DOM.hasClass(childTestEls[0].nativeElement, "child-comp-class"),
              isTrue);
          completer.done();
        });
      });
    });
    test("should query child elements by directive", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          var childTestEls =
              fixture.debugElement.queryAll(By.directive(MessageDir));
          expect(childTestEls, hasLength(4));
          expect(DOM.hasClass(childTestEls[0].nativeElement, "parent"), isTrue);
          expect(DOM.hasClass(childTestEls[1].nativeElement, "parentnested"),
              isTrue);
          expect(DOM.hasClass(childTestEls[2].nativeElement, "child"), isTrue);
          expect(DOM.hasClass(childTestEls[3].nativeElement, "childnested"),
              isTrue);
          completer.done();
        });
      });
    });
    test("should list providerTokens", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.providerTokens, contains(Logger));
          completer.done();
        });
      });
    });
    test("should list locals", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(LocalsComp).then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.children[0].getLocal("alice") is MyDir,
              isTrue);
          completer.done();
        });
      });
    });
    test("should allow injecting from the element injector", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(ParentComp).then((fixture) {
          fixture.detectChanges();
          Logger logger = fixture.debugElement.children[0].inject(Logger);
          expect(
              logger.log, ["parent", "nestedparent", "child", "nestedchild"]);
          completer.done();
        });
      });
    });
    test("should list event listeners", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(EventsComp).then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.children[0].listeners, hasLength(1));
          expect(fixture.debugElement.children[1].listeners, hasLength(1));
          completer.done();
        });
      });
    });
    test("should trigger event handlers", () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb.createAsync(EventsComp).then((fixture) {
          fixture.detectChanges();
          expect(fixture.debugElement.componentInstance.clicked, isFalse);
          expect(fixture.debugElement.componentInstance.customed, isFalse);
          fixture.debugElement.children[0]
              .triggerEventHandler("click", ({} as dynamic));
          expect(fixture.debugElement.componentInstance.clicked, isTrue);
          fixture.debugElement.children[1]
              .triggerEventHandler("myevent", ({} as dynamic));
          expect(fixture.debugElement.componentInstance.customed, isTrue);
          completer.done();
        });
      });
    });
  });
}
