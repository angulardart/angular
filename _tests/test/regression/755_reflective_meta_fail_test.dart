@Tags(const ['codegen'])
@TestOn('browser')

import 'package:test/test.dart';
import 'package:angular/angular.dart';

import '755_reflective_meta_fail_test.template.dart' as ng_generated;

// Source: https://github.com/dart-lang/angular/issues/755.
void main() {
  ng_generated.initReflector();

  test('should throw ArgumentError on a missing provider', () {
    final injector = new Injector.slowReflective([
      const Provider(ServiceInjectingToken, useClass: ServiceInjectingToken),
      // Intentionally omit a binding for "stringToken".
    ]);

    // Used to return an Object representing the secret "notFound" instead of
    // throwing ArgumentError, which was the expected behavior.
    expect(() => injector.get(ServiceInjectingToken), throwsArgumentError);
  });
}

const stringToken = const OpaqueToken('stringToken');

@Injectable()
class ServiceInjectingToken {
  final String tokenValue;

  ServiceInjectingToken(@Inject(stringToken) this.tokenValue);
}
