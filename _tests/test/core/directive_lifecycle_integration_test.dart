@Tags(const ['codegen'])
@TestOn('browser && !js')
library angular2.test.core.directive_lifecycle_integration_test;

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

void main() {
  group("directive lifecycle integration spec", () {
    Log log;
    var fixture;

    setUp(() async {
      log = new Log();

      var testBed = new NgTestBed<MyComp>();
      testBed = testBed.addProviders([new Provider(Log, useValue: log)]);
      fixture = await testBed.create();
    });

    test(
        'should invoke lifecycle methods ngOnChanges > '
        'ngOnInit > ngDoCheck > ngAfterContentChecked', () async {
      String startUp = log.toString();
      expect(
          startUp.startsWith(
              'ngOnChanges; ngOnInit; ngDoCheck; ngAfterContentInit; '
              'ngAfterContentChecked; child_ngDoCheck; '
              'ngAfterViewInit; ngAfterViewChecked'),
          isTrue);
      log.clear();
      await fixture.update((MyComp _) {});
      expect(
          log.toString(),
          'ngDoCheck; ngAfterContentChecked; child_ngDoCheck; '
          'ngAfterViewChecked');
    });
  });
}

@Injectable()
class Log {
  final List logItems = new List();

  void add(value) {
    logItems.add(value);
  }

  void clear() {
    logItems.clear();
  }

  @override
  String toString() => logItems.join('; ');
}

@Directive(selector: "[lifecycle-dir]")
class LifecycleDir implements DoCheck {
  Log _log;
  LifecycleDir(this._log);
  ngDoCheck() {
    _log.add("child_ngDoCheck");
  }
}

@Component(
  selector: "lifecycle",
  template: '<div lifecycle-dir></div>',
  directives: const [LifecycleDir],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
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
  @Input()
  var field;

  LifecycleCmp(this._log);

  ngOnChanges(_) {
    _log.add("ngOnChanges");
  }

  ngOnInit() {
    _log.add("ngOnInit");
  }

  ngDoCheck() {
    _log.add("ngDoCheck");
  }

  ngAfterContentInit() {
    _log.add("ngAfterContentInit");
  }

  ngAfterContentChecked() {
    _log.add("ngAfterContentChecked");
  }

  ngAfterViewInit() {
    _log.add("ngAfterViewInit");
  }

  ngAfterViewChecked() {
    _log.add("ngAfterViewChecked");
  }
}

@Component(
  selector: "my-comp",
  template: '<lifecycle [field]="123"></lifecycle>',
  directives: const [LifecycleCmp],
  // TODO(b/65383776): Change preserveWhitespace to false to improve codesize.
  preserveWhitespace: true,
)
class MyComp {}
