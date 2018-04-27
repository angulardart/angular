@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

// ignore: uri_has_not_been_generated
import 'hash_location_test.template.dart' as ng;

void main() {
  setUp(() => reset(platformLocation));
  tearDown(disposeAnyRunningTest);

  test('browser location should match RouterLinkDirective href', () async {
    final testBed = NgTestBed.forComponent<TestComponent>(
        ng.TestComponentNgFactory,
        rootInjector: createInjector);
    final testFixture = await testBed.create();
    final anchor = testFixture.assertOnlyInstance.anchor;
    final expectedUrl = '#/foo';
    expect(anchor.getAttribute('href'), expectedUrl);
    await testFixture.update((_) => anchor.click());
    verify(platformLocation.pushState(any, typed(any), expectedUrl)).called(1);
  });
}

class MockPlatformLocation extends Mock implements BrowserPlatformLocation {}

final platformLocation = new MockPlatformLocation();
PlatformLocation getPlatformLocation() => platformLocation;

/// Provides router dependencies with a mocked [PlatformLocation].
@GenerateInjector([
  routerProvidersHash,
  const FactoryProvider(PlatformLocation, getPlatformLocation),
])
InjectorFactory createInjector = ng.createInjector$Injector;

@Component(
  selector: 'foo',
  template: '',
)
class FooComponent {}

final fooRoute = new RouteDefinition(
  path: '/foo',
  component: ng.FooComponentNgFactory,
);

@Component(
  selector: 'test',
  template: '''
    <a #routerLink [routerLink]="fooPath"></a>
    <router-outlet [routes]="routes"></router-outlet>
  ''',
  directives: const [RouterLink, RouterOutlet],
)
class TestComponent {
  static final String fooPath = fooRoute.toUrl();
  static final List<RouteDefinition> routes = [fooRoute];

  @ViewChild('routerLink')
  AnchorElement anchor;
}
