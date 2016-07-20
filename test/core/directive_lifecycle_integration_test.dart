@TestOn('browser')
library angular2.test.core.directive_lifecycle_integration_test;

import "package:angular2/core.dart"
    show
        OnChanges,
        OnInit,
        DoCheck,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked;
import "package:angular2/src/core/metadata.dart"
    show Directive, Component, ViewMetadata;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

main() {
  group("directive lifecycle integration spec", () {
    test(
        'should invoke lifecycle methods ngOnChanges > '
        'ngOnInit > ngDoCheck > ngAfterContentChecked', () async {
      return inject([TestComponentBuilder, Log, AsyncTestCompleter],
          (TestComponentBuilder tcb, Log log, AsyncTestCompleter completer) {
        tcb
            .overrideView(
                MyComp,
                new ViewMetadata(
                    template: "<div [field]=\"123\" lifecycle></div>",
                    directives: [LifecycleCmp]))
            .createAsync(MyComp)
            .then((tc) {
          tc.detectChanges();
          expect(
              log.result(),
              'ngOnChanges; ngOnInit; ngDoCheck; ngAfterContentInit; '
              'ngAfterContentChecked; child_ngDoCheck; '
              'ngAfterViewInit; ngAfterViewChecked');
          log.clear();
          tc.detectChanges();
          expect(
              log.result(),
              'ngDoCheck; ngAfterContentChecked; child_ngDoCheck; '
              'ngAfterViewChecked');
          completer.done();
        });
      });
    });
  });
}

@Directive(selector: "[lifecycle-dir]")
class LifecycleDir implements DoCheck {
  Log _log;
  LifecycleDir(this._log) {}
  ngDoCheck() {
    this._log.add("child_ngDoCheck");
  }
}

@Component(
    selector: "[lifecycle]",
    inputs: const ["field"],
    template: '''<div lifecycle-dir></div>''',
    directives: const [LifecycleDir])
class LifecycleCmp
    implements
        OnChanges,
        OnInit,
        DoCheck,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked {
  Log _log;
  var field;
  LifecycleCmp(this._log) {}
  ngOnChanges(_) {
    this._log.add("ngOnChanges");
  }

  ngOnInit() {
    this._log.add("ngOnInit");
  }

  ngDoCheck() {
    this._log.add("ngDoCheck");
  }

  ngAfterContentInit() {
    this._log.add("ngAfterContentInit");
  }

  ngAfterContentChecked() {
    this._log.add("ngAfterContentChecked");
  }

  ngAfterViewInit() {
    this._log.add("ngAfterViewInit");
  }

  ngAfterViewChecked() {
    this._log.add("ngAfterViewChecked");
  }
}

@Component(selector: "my-comp", directives: const [])
class MyComp {}
