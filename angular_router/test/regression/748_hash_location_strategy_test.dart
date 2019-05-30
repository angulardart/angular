@TestOn('browser')
import 'dart:html';

import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_test/angular_test.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '748_hash_location_strategy_test.template.dart' as ng;

final platformLocation = MockPlatformLocation();

void main() {
  setUp(() {
    reset(platformLocation);
  });

  tearDown(disposeAnyRunningTest);

  test('browser location should match clicked href', () async {
    final testBed = NgTestBed.forComponent(ng.AppComponentNgFactory,
        rootInjector: injectorFactory);
    final testFixture = await testBed.create();
    expect(testFixture.assertOnlyInstance.anchor.getAttribute('href'), '#/foo');
    await testFixture.update((c) {
      c.anchor.click();
    });
    verify(platformLocation.pushState(any, any, '#/foo')).called(1);
  });
}

PlatformLocation platformLocationFactory() => platformLocation;

class MockPlatformLocation extends Mock implements BrowserPlatformLocation {}

@GenerateInjector([
  routerProvidersHash,
  FactoryProvider(PlatformLocation, platformLocationFactory),
])
InjectorFactory injectorFactory = ng.injectorFactory$Injector;

@Component(
  selector: 'app',
  template: '''
    <a #routerLink [routerLink]="fooRoute.toUrl()"></a>
    <router-outlet [routes]="routes"></router-outlet>
  ''',
  directives: [RouterLink, RouterOutlet],
)
class AppComponent {
  static final fooRoute = RouteDefinition(
    path: '/foo',
    component: ng.FooComponentNgFactory,
  );
  static final routes = [fooRoute];

  @ViewChild('routerLink')
  HtmlElement anchor;
}

@Component(selector: 'foo', template: '')
class FooComponent {}
