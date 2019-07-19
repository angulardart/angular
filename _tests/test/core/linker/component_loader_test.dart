@TestOn('browser')
import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'component_loader_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);
  Log log;

  setUp(() {
    log = Log();
  });

  Future<NgTestFixture<T>> createFixture<T>(ComponentFactory<T> factory) async {
    final testBed = NgTestBed.forComponent(factory,
        rootInjector: ([parent]) => Injector.map({Log: log}, parent));
    return await testBed.create();
  }

  group('CheckAlways component', () {
    test('should be able to load next to a location', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      await fixture.update((comp) {
        comp.loader.loadNextToLocation(
          ng.DynamicCompNgFactory,
          comp.location,
        );
      });
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load into a structural directive', () async {
      final fixture = await createFixture(ng.CompWithDirectiveNgFactory);
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load from a service', () async {
      final fixture = await createFixture(ng.CompWithServiceNgFactory);
      await fixture.update((comp) {
        final ref = comp.service.loader
            .loadDetached(ng.DynamicCompNgFactory, injector: logInjector());
        expect(ref.location.text, 'Dynamic');
      });
    });

    test('should run lifecycles', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(log.toString(), isEmpty);
      await fixture.update((comp) {
        comp.loader.loadNextTo(ng.DynamicCompNgFactory);
      });
      expect(
          log.toString(),
          startsWith('ngOnInit; '
              'ngAfterContentInit; '
              'ngAfterContentChecked; '
              'ngAfterViewInit; '
              'ngAfterViewChecked'));
    });

    test('should detect changes made in update()', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.DynamicCompNgFactory, comp.location);
      });
      expect(fixture.text, 'BeforeDynamicAfter');
      expect(log.toString(), isNot(contains('ngAfterChanges')));
      await fixture.update((_) {
        ref.update((cmp) {
          cmp.input = 'Changed';
        });
      });
      expect(fixture.text, 'BeforeDynamicChangedAfter');
      expect(log.toString(), contains('ngAfterChanges'));
    });

    test('should detect changes outside of update', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.DynamicCompNgFactory, comp.location);
      });
      expect(fixture.text, 'BeforeDynamicAfter');

      log.clear();
      await fixture.update((_) {
        ref.instance.input = 'Changed';
      });
      expect(fixture.text, 'BeforeDynamicChangedAfter');
      expect(log.toString(), isNot(contains('ngAfterChanges')));
    });

    test('does not swallow exceptions', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.DynamicCompNgFactory, comp.location);
      });
      expect(fixture.update((_) {
        ref.update((cmp) => throw IntentionalError());
      }), throwsA(isIntentionalError));
    });
  });

  group('OnPush component', () {
    test('should be able to load next to a location', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      await fixture.update((comp) {
        comp.loader.loadNextToLocation(
          ng.DynamicOnPushCompNgFactory,
          comp.location,
        );
      });
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load into a structural directive', () async {
      final fixture = await createFixture(ng.CompWithDirectiveNgFactory);
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load from a service', () async {
      final fixture = await createFixture(ng.CompWithServiceNgFactory);
      await fixture.update((comp) {
        final ref = comp.service.loader.loadDetached(
            ng.DynamicOnPushCompNgFactory,
            injector: logInjector());
        expect(ref.location.text, 'Dynamic');
      });
    });

    test('should run lifecycles', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(log.toString(), isEmpty);
      await fixture.update((comp) {
        comp.loader.loadNextTo(ng.DynamicOnPushCompNgFactory);
      });
      expect(
          log.toString(),
          startsWith('ngOnInit; '
              'ngAfterContentInit; '
              'ngAfterContentChecked; '
              'ngAfterViewInit; '
              'ngAfterViewChecked'));
    });

    test('should detect changes made in update()', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      ComponentRef<DynamicOnPushComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.DynamicOnPushCompNgFactory, comp.location);
      });
      expect(fixture.text, 'BeforeDynamicAfter');
      log.clear();
      await fixture.update((_) {
        ref.update((cmp) {
          cmp.input = 'Changed';
        });
      });
      expect(fixture.text, 'BeforeDynamicChangedAfter');
      expect(
          log.toString(),
          startsWith('ngAfterChanges; '
              'ngAfterContentChecked; '
              'ngAfterViewChecked'));
    });

    test('does not detect changes outside of update', () async {
      final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
      expect(fixture.text, 'BeforeAfter');
      ComponentRef<DynamicOnPushComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.DynamicOnPushCompNgFactory, comp.location);
      });
      expect(fixture.text, 'BeforeDynamicAfter');
      log.clear();
      await fixture.update((_) {
        ref.instance.input = 'Changed';
      });
      expect(fixture.text, 'BeforeDynamicAfter');
      expect(log.toString(), isNot(contains('ngAfterChanges')));
    });
  });

  test('does not swallow exceptions', () async {
    final fixture = await createFixture(ng.CompWithCustomLocationNgFactory);
    ComponentRef<DynamicOnPushComp> ref;
    await fixture.update((comp) {
      ref = comp.loader
          .loadNextToLocation(ng.DynamicOnPushCompNgFactory, comp.location);
    });
    expect(fixture.update((_) {
      ref.update((cmp) => throw IntentionalError());
    }), throwsA(isIntentionalError));
  });
}

@GenerateInjector([ClassProvider(Log)])
final InjectorFactory logInjector = ng.logInjector$Injector;

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

@Component(
  selector: 'comp-with-custom-location',
  template: r'Before<template #location></template>After',
)
class CompWithCustomLocation {
  final ComponentLoader loader;

  CompWithCustomLocation(this.loader);

  @ViewChild('location', read: ViewContainerRef)
  ViewContainerRef location;
}

@Component(
  selector: 'comp-with-directive',
  directives: [
    DirectiveThatIsLocation,
  ],
  template: r'Before<template location></template>After',
)
class CompWithDirective {}

@Directive(
  selector: '[location]',
)
class DirectiveThatIsLocation {
  DirectiveThatIsLocation(ComponentLoader loader) {
    loader.loadNextTo(ng.DynamicCompNgFactory);
  }
}

@Component(
  selector: 'comp-with-service',
  providers: [ClassProvider(Service)],
  template: '',
)
class CompWithService {
  final Service service;

  CompWithService(this.service);
}

class Service {
  final ComponentLoader loader;

  Service(this.loader);
}

@Component(
  selector: 'dynamic-comp',
  template: 'Dynamic{{input}}',
)
class DynamicComp extends Lifecycles {
  DynamicComp(Log log) : super(log);
  @Input()
  String input;
}

@Component(
  selector: 'dynamic-comp',
  template: 'Dynamic{{input}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DynamicOnPushComp extends Lifecycles {
  DynamicOnPushComp(Log log) : super(log);

  @Input()
  String input;
}

class Lifecycles
    implements
        OnInit,
        AfterChanges,
        AfterContentInit,
        AfterContentChecked,
        AfterViewInit,
        AfterViewChecked {
  Lifecycles(this._log);

  final Log _log;

  @override
  ngOnInit() {
    _log.add('ngOnInit');
  }

  @override
  ngAfterChanges() {
    _log.add('ngAfterChanges');
  }

  @override
  ngAfterContentInit() {
    _log.add('ngAfterContentInit');
  }

  @override
  ngAfterContentChecked() {
    _log.add('ngAfterContentChecked');
  }

  @override
  ngAfterViewInit() {
    _log.add('ngAfterViewInit');
  }

  @override
  ngAfterViewChecked() {
    _log.add('ngAfterViewChecked');
  }
}

class IntentionalError extends Error {}

final isIntentionalError = const TypeMatcher<IntentionalError>();
