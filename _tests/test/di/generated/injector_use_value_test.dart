@TestOn('browser')
import 'package:angular/angular.dart';
import 'package:test/test.dart';

import 'injector_use_value_test.template.dart' as ng;

// Tests specifically for @GenerateInjector + useValue: ...
//
// These tend to be complicated and more isolated than other code.
void main() {
  Injector injector;

  setUp(() => injector = example());

  group('should resolve useValue: targeting a', () {
    test('class with a const constructor', () {
      expect(
        injector.get(ClassWithConstConstructor),
        const TypeMatcher<ClassWithConstConstructor>(),
      );
    });

    test('class with a named const constructor', () {
      expect(
        injector.get(ClassWithNamedConstConstructor),
        const TypeMatcher<ClassWithNamedConstConstructor>(),
      );
    });

    test('class with multiple constructors, at least one const', () {
      expect(
        injector.get(ClassWithMultipleConstructors),
        const TypeMatcher<ClassWithMultipleConstructors>(),
      );
    });

    test('class with a private constructor, but a public static field', () {
      expect(
        injector.get(ClassWithPrivateConstructorAndStaticField),
        const TypeMatcher<ClassWithPrivateConstructorAndStaticField>(),
      );
    });

    test('class with a private constructor, but a public top-level field', () {
      expect(
        injector.get(ClassWithPrivateConstructorAndTopLevelField),
        const TypeMatcher<ClassWithPrivateConstructorAndTopLevelField>(),
      );
    });

    test('class with a redirecting constructor', () {
      expect(
        injector.get(ClassWithRedirectingConstructor),
        const TypeMatcher<ClassWithRedirectingConstructor>(),
      );
    });

    test('top-level function', () {
      IntIdentityFn fn = injector.get(intIdentityToken);
      expect(fn(1), 1);
    });

    test('static-level method', () {
      StringIdentityFn fn = injector.get(stringIdentityToken);
      expect(fn('a'), 'a');
    });

    test('raw string', () {
      String raw = injector.get(stringRawToken);
      expect(raw, r'$5.00 USD');
    });
  });
}

typedef IntIdentityFn = int Function(int);
const intIdentityToken = OpaqueToken<IntIdentityFn>();

typedef StringIdentityFn = String Function(String);
const stringIdentityToken = OpaqueToken<StringIdentityFn>();

@GenerateInjector([
  ValueProvider(
    ClassWithConstConstructor,
    ClassWithConstConstructor(),
  ),
  ValueProvider(
    ClassWithNamedConstConstructor,
    ClassWithNamedConstConstructor.someName(),
  ),
  ValueProvider(
    ClassWithMultipleConstructors,
    ClassWithMultipleConstructors.isConst(),
  ),
  ValueProvider(
    ClassWithPrivateConstructorAndStaticField,
    ClassWithPrivateConstructorAndStaticField.instance,
  ),
  ValueProvider(
    ClassWithPrivateConstructorAndTopLevelField,
    topLevelInstance,
  ),
  ValueProvider(
    ClassWithRedirectingConstructor,
    ClassWithRedirectingConstructor(),
  ),
  ValueProvider.forToken(
    intIdentityToken,
    topLevelMethod,
  ),
  ValueProvider.forToken(
    stringIdentityToken,
    StaticClass.staticMethod,
  ),
  ValueProvider.forToken(
    stringRawToken,
    r'$5.00 USD',
  )
])
final InjectorFactory example = ng.example$Injector;

// An example of a class with a single, default, "const" constructor.
class ClassWithConstConstructor {
  const ClassWithConstConstructor();
}

// An example of a class with a single, named, "const" constructor.
class ClassWithNamedConstConstructor {
  const ClassWithNamedConstConstructor.someName();
}

// An example of a class with multiple constructors, at least one const.
class ClassWithMultipleConstructors {
  ClassWithMultipleConstructors.notConst();
  const ClassWithMultipleConstructors.isConst();
}

// An example of a class that can't be created in generated files, but has an
// existing (public) instance that can be referenced as a static field.
class ClassWithPrivateConstructorAndStaticField {
  static const instance = ClassWithPrivateConstructorAndStaticField._();
  const ClassWithPrivateConstructorAndStaticField._();
}

// An example of a class that can't be created in generated files, but has an
// existing (public) instance that can be referenced as a top-level field.
const topLevelInstance = ClassWithPrivateConstructorAndTopLevelField._();

class ClassWithPrivateConstructorAndTopLevelField {
  const ClassWithPrivateConstructorAndTopLevelField._();
}

// An example of a class with a redirecting factory constructor.
abstract class ClassWithRedirectingConstructor {
  const factory ClassWithRedirectingConstructor() = _ConcreteClass;
}

class _ConcreteClass implements ClassWithRedirectingConstructor {
  const _ConcreteClass();
}

int topLevelMethod(int a) => a;

class StaticClass {
  static String staticMethod(String a) => a;
}

const stringRawToken = OpaqueToken<String>('stringRawToken');
