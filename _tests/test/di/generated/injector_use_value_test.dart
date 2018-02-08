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

  // TODO(matanl): Gradually enable actual test cases as they are supported.
  group('should resolve useValue: targeting a', () {
    test('class with a const constructor', () {
      expect(
        injector.get(ClassWithConstConstructor),
        const isInstanceOf<ClassWithConstConstructor>(),
      );
    });

    test('class with a named const constructor', () {
      expect(
        injector.get(ClassWithNamedConstConstructor),
        const isInstanceOf<ClassWithNamedConstConstructor>(),
      );
    });

    test('class with multiple constructors, at least one const', () {
      expect(
        injector.get(ClassWithMultipleConstructors),
        const isInstanceOf<ClassWithMultipleConstructors>(),
      );
    });

    test('class with a private constructor, but a public static field', () {
      expect(
        injector.get(ClassWithPrivateConstructorAndStaticField),
        const isInstanceOf<ClassWithPrivateConstructorAndStaticField>(),
      );
    });

    test('class with a private constructor, but a public top-level field', () {
      expect(
        injector.get(ClassWithPrivateConstructorAndTopLevelField),
        const isInstanceOf<ClassWithPrivateConstructorAndTopLevelField>(),
      );
    });

    test('class with a redirecting constructor', () {
      expect(
        injector.get(ClassWithRedirectingConstructor),
        const isInstanceOf<ClassWithRedirectingConstructor>(),
      );
    });
  });
}

@GenerateInjector(const [
  const Provider(
    ClassWithConstConstructor,
    useValue: const ClassWithConstConstructor(),
  ),
  const Provider(
    ClassWithNamedConstConstructor,
    useValue: const ClassWithNamedConstConstructor.someName(),
  ),
  const Provider(
    ClassWithMultipleConstructors,
    useValue: const ClassWithMultipleConstructors.isConst(),
  ),
  const Provider(
    ClassWithPrivateConstructorAndStaticField,
    useValue: ClassWithPrivateConstructorAndStaticField.instance,
  ),
  const Provider(
    ClassWithPrivateConstructorAndTopLevelField,
    useValue: topLevelInstance,
  ),
  const Provider(
    ClassWithRedirectingConstructor,
    useValue: const ClassWithRedirectingConstructor(),
  ),
])
Injector example() => ng.example$Injector();

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
  static const instance = const ClassWithPrivateConstructorAndStaticField._();
  const ClassWithPrivateConstructorAndStaticField._();
}

// An example of a class that can't be created in generated files, but has an
// existing (public) instance that can be referenced as a top-level field.
const topLevelInstance = const ClassWithPrivateConstructorAndTopLevelField._();

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
