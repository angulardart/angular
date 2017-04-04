@Tags(const ['codegen'])
@TestOn('browser')
import 'package:angular2/angular2.dart';
import 'package:angular2/src/core/di/injector.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  test('should fail with a missing provider exception', () async {
    final testBed = new NgTestBed<TestComponent>();
    expect(
      testBed.create(),
      throwsInAngular(const isInstanceOf<MissingProviderError>()),
    );
  });

  // TODO: Move this in to pkg/angular_test.
  // https://github.com/dart-lang/angular_test/issues/52.
  test('should fail and not continue to another expectation', () async {
    final testBed = new NgTestBed<TestComponent>();
    try {
      await testBed.create();
      fail('Should not have continued');
    } catch (_) {}
  });
}

@Injectable()
class InjectableService {}

@Component(
  selector: 'test',
  directives: const [NoProviderComponent],
  template: r'Service: <no-provider></no-provider>',
)
class TestComponent {}

@Component(
  selector: 'no-provider',
  template: r'{{service != null}}',
)
class NoProviderComponent {
  final InjectableService service;

  NoProviderComponent(this.service);
}
