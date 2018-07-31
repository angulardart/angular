@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular_router/angular_router.dart';
import 'package:angular_router/testing.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

// ignore: uri_has_not_been_generated
import '1389_empty_path_test.template.dart' as ng;

void main() {
  tearDown(disposeAnyRunningTest);

  test('navigation to empty path should fail', () async {
    final testBed = NgTestBed.forComponent(ng.TestComponentNgFactory);
    final testFixture = await testBed.create();
    final router = testFixture.assertOnlyInstance.router;
    final result = await router.navigate('/');
    expect(result, NavigationResult.INVALID_ROUTE);
  });
}

@Component(
  selector: 'test',
  template: '',
  providers: routerProvidersTest,
)
class TestComponent {
  final Router router;

  TestComponent(this.router);
}
