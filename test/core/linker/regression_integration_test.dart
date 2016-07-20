@TestOn('browser')
library angular2.test.core.linker.regression_integration_test;

import "dart:async";

import "package:angular2/common.dart" show NgIf, NgClass;
import "package:angular2/core.dart"
    show
        Component,
        Pipe,
        PipeTransform,
        provide,
        ViewMetadata,
        PLATFORM_PIPES,
        OpaqueToken,
        Injector;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  // Place to put reproductions for regressions
  group("regressions", () {
    group("platform pipes", () {
      beforeEachProviders(() => [
            provide(PLATFORM_PIPES, useValue: [PlatformPipe], multi: true)
          ]);
      test("should overwrite them by custom pipes", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template: "{{true | somePipe}}", pipes: [CustomPipe]))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.nativeElement, hasTextContent("someCustomPipe"));
            completer.done();
          });
        });
      });
    });
    group("expressions", () {
      test(
          "should evaluate conditional and boolean operators with right precedence - #8244",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          tcb
              .overrideView(
                  MyComp,
                  new ViewMetadata(
                      template:
                          '''{{\'red\' + (true ? \' border\' : \'\')}}'''))
              .createAsync(MyComp)
              .then((fixture) {
            fixture.detectChanges();
            expect(fixture.nativeElement, hasTextContent("red border"));
            completer.done();
          });
        });
      });
    });
    group("providers", () {
      Future<Injector> createInjector(
          TestComponentBuilder tcb, List<dynamic> providers) {
        return tcb
            .overrideProviders(MyComp, [providers])
            .createAsync(MyComp)
            .then((fixture) => fixture.componentInstance.injector);
      }
      test(
          "should support providers with an OpaqueToken that contains a `.` in the name",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = new OpaqueToken("a.b");
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test("should support providers with string token with a `.` in it",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = "a.b";
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test("should support providers with an anonymous function", () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token = () => true;
          var tokenValue = 1;
          createInjector(tcb, [provide(token, useValue: tokenValue)])
              .then((Injector injector) {
            expect(injector.get(token), tokenValue);
            completer.done();
          });
        });
      });
      test(
          "should support providers with an OpaqueToken that has a StringMap as value",
          () async {
        return inject([TestComponentBuilder, AsyncTestCompleter],
            (TestComponentBuilder tcb, AsyncTestCompleter completer) {
          var token1 = new OpaqueToken("someToken");
          var token2 = new OpaqueToken("someToken");
          var tokenValue1 = {"a": 1};
          var tokenValue2 = {"a": 1};
          createInjector(tcb, [
            provide(token1, useValue: tokenValue1),
            provide(token2, useValue: tokenValue2)
          ]).then((Injector injector) {
            expect(injector.get(token1), tokenValue1);
            expect(injector.get(token2), tokenValue2);
            completer.done();
          });
        });
      });
    });
    test(
        "should allow logging a previous elements class binding via interpolation",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideTemplate(MyComp,
                '''<div [class.a]="true" #el>Class: {{el.className}}</div>''')
            .createAsync(MyComp)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("Class: a"));
          completer.done();
        });
      });
    });
    test(
        "should support ngClass before a component and content projection inside of an ngIf",
        () async {
      return inject([TestComponentBuilder, AsyncTestCompleter],
          (TestComponentBuilder tcb, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MyComp,
                new ViewMetadata(
                    template:
                        '''A<cmp-content *ngIf="true" [ngClass]="\'red\'">B</cmp-content>C''',
                    directives: [NgClass, NgIf, CmpWithNgContent]))
            .createAsync(MyComp)
            .then((fixture) {
          fixture.detectChanges();
          expect(fixture.nativeElement, hasTextContent("ABC"));
          completer.done();
        });
      });
    });
  });
}

@Component(selector: "my-comp", template: "")
class MyComp {
  final Injector injector;
  MyComp(this.injector) {}
}

@Pipe(name: "somePipe", pure: true)
class PlatformPipe implements PipeTransform {
  dynamic transform(dynamic value) {
    return "somePlatformPipe";
  }
}

@Pipe(name: "somePipe", pure: true)
class CustomPipe implements PipeTransform {
  dynamic transform(dynamic value) {
    return "someCustomPipe";
  }
}

@Component(selector: "cmp-content", template: '''<ng-content></ng-content>''')
class CmpWithNgContent {}
