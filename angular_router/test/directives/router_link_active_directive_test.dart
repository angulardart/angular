import 'dart:async';

import 'package:test/test.dart';
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';

import 'router_link_active_directive_test.template.dart' as ng;

void main() {
  late FakeRouter fakeRouter;
  late InjectorFactory addInjector;

  setUp(() {
    fakeRouter = FakeRouter();
    addInjector = (i) {
      final strategy = MockLocationStrategy();
      return ReflectiveInjector.resolveStaticAndCreate([
        FactoryProvider(Location, () => Location(strategy), deps: []),
        ValueProvider(LocationStrategy, strategy),
        ValueProvider(Router, fakeRouter),
      ], i);
    };
  });

  tearDown(disposeAnyRunningTest);

  test('should add/remove a CSS class as a route is activated', () async {
    final fixture = await NgTestBed(
      ng.createTestRouterLinkActiveFactory(),
    ).addInjector(addInjector).create(beforeChangeDetection: (component) {
      component.link = '/user/bob';
      fakeRouter.current = RouterState('/user/jill', const []);
    });
    final anchor = fixture.rootElement.querySelector('a')!;
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current = RouterState('/user/bob', const []);
    });
    expect(anchor.classes, contains('active-link'));
  });

  test('should validate queryParams and fragment', () async {
    final fixture = await NgTestBed(
      ng.createTestRouterLinkActiveFactory(),
    ).addInjector(addInjector).create(beforeChangeDetection: (component) {
      component.link = '/user/bob?param=1#frag';
      fakeRouter.current = RouterState('/user/bob', const []);
    });
    final anchor = fixture.rootElement.querySelector('a')!;
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current =
          RouterState('/user/bob', const [], queryParameters: {'param': '1'});
    });
    expect(anchor.classes, isEmpty);
    await fixture.update((_) {
      fakeRouter.current = RouterState('/user/bob', const [], fragment: 'frag');
    });
    expect(anchor.classes, isEmpty);

    await fixture.update((_) {
      fakeRouter.current = RouterState('/user/bob', const [],
          queryParameters: {'param': '1'}, fragment: 'frag');
    });
    expect(anchor.classes, contains('active-link'));
  });

  test(
      'should ignore the current urls queryParams and fragment if not '
      'specified in the routerLinks', () async {
    final fixture = await NgTestBed(
      ng.createTestRouterLinkActiveFactory(),
    ).addInjector(addInjector).create(beforeChangeDetection: (component) {
      component.link = '/user/bob';
      fakeRouter.current = RouterState('/user/bob', const [],
          queryParameters: {'param': '1'}, fragment: 'frag');
    });
    final anchor = fixture.rootElement.querySelector('a')!;
    expect(anchor.classes, contains('active-link'));
  });
}

@Component(
  selector: 'test-router-link-active',
  directives: [
    RouterLink,
    RouterLinkActive,
  ],
  template: r'''
    <a [routerLink]="link" routerLinkActive="active-link">Bob</a>
  ''',
)
class TestRouterLinkActive {
  late String link;
}

class FakeRouter implements Router {
  final _streamController = StreamController<RouterState>.broadcast(sync: true);

  late RouterState _current;

  @override
  RouterState get current => _current;
  set current(RouterState current) {
    _streamController.add(current);
    _current = current;
  }

  @override
  dynamic noSuchMethod(i) => super.noSuchMethod(i);

  @override
  Stream<RouterState> get stream => _streamController.stream;
}
