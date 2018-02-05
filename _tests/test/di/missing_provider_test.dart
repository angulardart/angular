@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:angular/src/di/injector/injector.dart';
import 'package:test/test.dart';

import 'missing_provider_test.template.dart' as ng;

void main() {
  ng.initReflector();

  test('should throw an error for a single missing token', () {
    final nullInjector = const Injector.empty();
    expect(
      () => nullInjector.get(A),
      throwsA(predicate((e) => '$e'.contains('No provider found for $A'))),
    );
  });

  test('should throw a better error for a path of missing tokens', () {
    final injectorWithAB = new Injector.slowReflective([A]);
    expect(
      () => injectorWithAB.get(A),
      throwsA(
        predicate((e) => '$e'.contains('No provider found for $B: $A -> $B')),
      ),
    );
  }, skip: 'Not yet supported: We need to track the provider chain.');
}

@Injectable()
class A {
  A(B b);
}

@Injectable()
class B {}
