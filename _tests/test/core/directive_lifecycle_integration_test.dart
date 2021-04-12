library angular2.test.core.directive_lifecycle_integration_test;

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'directive_lifecycle_integration_test.template.dart' as ng;

void main() {
  group('directive lifecycle integration spec', () {
    late Log log;
    late NgTestFixture<MyComp> fixture;

    setUp(() async {
      log = Log();

      var testBed = NgTestBed(
        ng.createMyCompFactory(),
        rootInjector: (parent) => Injector.map({Log: log}, parent),
      );
      fixture = await testBed.create();
    });

    test(
        'should invoke lifecycle methods '
        'ngOnInit > ngDoCheck > ngAfterContentChecked', () async {
      var startUp = log.toString();
      expect(
          startUp.startsWith('ngAfterChanges; ngOnInit; ngDoCheck; '
              'ngAfterContentInit; '
              'ngAfterContentChecked; child_ngDoCheck; '
              'ngAfterViewInit; ngAfterViewChecked'),
          isTrue);
      log.clear();
      await fixture.update((MyComp _) {});
      expect(
        log.toString(),
        // We run more than one cycle, but this is what we really care about.
        startsWith('ngDoCheck; ngAfterContentChecked; child_ngDoCheck; '
            'ngAfterViewChecked'),
      );
    });
  });
}

@Injectable()
class Log {
  final logItems = <String>[];

  void add(String value) {
    logItems.add(value);
  }

  void clear() {
    logItems.clear();
  }

  @override
  String toString() => logItems.join('; ');
}

@Directive(
  selector: '[lifecycle-dir]',
)
class LifecycleDir implements DoCheck {
  final Log _log;
  LifecycleDir(this._log);
  @override
  void ngDoCheck() {
    _log.add('child_ngDoCheck');
  }
}

@Component(
  selector: 'lifecycle',
  template: '<div lifecycle-dir></div>',
  directives: [LifecycleDir],
)
class LifecycleCmp
    implements
        OnInit,
        DoCheck,
        AfterChanges,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked {
  final Log _log;
  @Input()
  int? field;

  LifecycleCmp(this._log);

  @override
  void ngOnInit() {
    _log.add('ngOnInit');
  }

  @override
  void ngDoCheck() {
    _log.add('ngDoCheck');
  }

  @override
  void ngAfterChanges() {
    _log.add('ngAfterChanges');
  }

  @override
  void ngAfterContentInit() {
    _log.add('ngAfterContentInit');
  }

  @override
  void ngAfterContentChecked() {
    _log.add('ngAfterContentChecked');
  }

  @override
  void ngAfterViewInit() {
    _log.add('ngAfterViewInit');
  }

  @override
  void ngAfterViewChecked() {
    _log.add('ngAfterViewChecked');
  }
}

@Component(
  selector: 'my-comp',
  template: '<lifecycle [field]="123"></lifecycle>',
  directives: [LifecycleCmp],
)
class MyComp {}
