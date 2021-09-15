import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'component_loader_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);
  late Log log;

  setUp(() {
    log = Log();
  });

  Future<NgTestFixture<T>> createFixture<T extends Object>(
    ComponentFactory<T> factory,
  ) async {
    final testBed = NgTestBed(factory,
        rootInjector: (parent) => Injector.map({Log: log}, parent));
    return await testBed.create();
  }

  group('CheckAlways component', () {
    test('should be able to load next to a location', () async {
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      await fixture.update((comp) {
        comp.loader.loadNextToLocation(
          ng.createDynamicCompFactory(),
          comp.location!,
        );
      });
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load into a structural directive', () async {
      final fixture = await createFixture(ng.createCompWithDirectiveFactory());
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load from a service', () async {
      final fixture = await createFixture(ng.createCompWithServiceFactory());
      await fixture.update((comp) {
        final ref = comp.service.loader.loadDetached(
          ng.createDynamicCompFactory(),
          injector: logInjector(comp.context),
        );
        expect(ref.location.text, 'Dynamic');
      });
    });

    test('should run lifecycles', () async {
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(log.toString(), isEmpty);
      await fixture.update((comp) {
        comp.loader.loadNextTo(ng.createDynamicCompFactory());
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
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      late final ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.createDynamicCompFactory(), comp.location!);
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
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      late final ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.createDynamicCompFactory(), comp.location!);
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
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      late final ComponentRef<DynamicComp> ref;
      await fixture.update((comp) {
        ref = comp.loader
            .loadNextToLocation(ng.createDynamicCompFactory(), comp.location!);
      });
      expect(fixture.update((_) {
        ref.update((cmp) => throw IntentionalError());
      }), throwsA(isIntentionalError));
    });
  });

  group('OnPush component', () {
    test('should be able to load next to a location', () async {
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      await fixture.update((comp) {
        comp.loader.loadNextToLocation(
          ng.createDynamicOnPushCompFactory(),
          comp.location!,
        );
      });
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load into a structural directive', () async {
      final fixture = await createFixture(ng.createCompWithDirectiveFactory());
      expect(fixture.text, 'BeforeDynamicAfter');
    });

    test('should be able to load from a service', () async {
      final fixture = await createFixture(ng.createCompWithServiceFactory());
      await fixture.update((comp) {
        final ref = comp.service.loader.loadDetached(
          ng.createDynamicOnPushCompFactory(),
          injector: logInjector(comp.context),
        );
        expect(ref.location.text, 'Dynamic');
      });
    });

    test('should run lifecycles', () async {
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(log.toString(), isEmpty);
      await fixture.update((comp) {
        comp.loader.loadNextTo(ng.createDynamicOnPushCompFactory());
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
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      late final ComponentRef<DynamicOnPushComp> ref;
      await fixture.update((comp) {
        ref = comp.loader.loadNextToLocation(
          ng.createDynamicOnPushCompFactory(),
          comp.location!,
        );
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
        startsWith(
          'ngAfterChanges; '
          'ngAfterContentChecked; '
          'ngAfterViewChecked',
        ),
      );
    });

    test('does not detect changes outside of update', () async {
      final fixture =
          await createFixture(ng.createCompWithCustomLocationFactory());
      expect(fixture.text, 'BeforeAfter');
      late final ComponentRef<DynamicOnPushComp> ref;
      await fixture.update((comp) {
        ref = comp.loader.loadNextToLocation(
          ng.createDynamicOnPushCompFactory(),
          comp.location!,
        );
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
    final fixture =
        await createFixture(ng.createCompWithCustomLocationFactory());
    late final ComponentRef<DynamicOnPushComp> ref;
    await fixture.update((comp) {
      ref = comp.loader.loadNextToLocation(
        ng.createDynamicOnPushCompFactory(),
        comp.location!,
      );
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
  ViewContainerRef? location;
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
    loader.loadNextTo(ng.createDynamicCompFactory());
  }
}

@Component(
  selector: 'comp-with-service',
  providers: [ClassProvider(Service)],
  template: '',
)
class CompWithService {
  final Service service;
  final Injector context;

  CompWithService(this.service, this.context);
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
  String? input;
}

@Component(
  selector: 'dynamic-comp',
  template: 'Dynamic{{input}}',
  changeDetection: ChangeDetectionStrategy.OnPush,
)
class DynamicOnPushComp extends Lifecycles {
  DynamicOnPushComp(Log log) : super(log);

  @Input()
  String? input;
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
  void ngOnInit() {
    _log.add('ngOnInit');
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

class IntentionalError extends Error {}

final isIntentionalError = const TypeMatcher<IntentionalError>();
