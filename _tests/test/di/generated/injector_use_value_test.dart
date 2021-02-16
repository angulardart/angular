import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'injector_use_value_test.template.dart' as ng;

// Tests specifically for @GenerateInjector + useValue: ...
//
// These tend to be complicated and more isolated than other code.
void main() {
  late Injector injector;

  setUp(() => injector = example(Injector.empty()));

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
      final fn = injector.provideToken(intIdentityToken);
      expect(fn(1), 1);
    });

    test('static-level method', () {
      final fn = injector.provideToken(stringIdentityToken);
      expect(fn('a'), 'a');
    });

    test('various strings', () {
      final s1 = injector.provideToken(stringRawToken);
      expect(s1, r'$5.00 USD');
      final s2 = injector.provideToken(singleQuoteToken);
      expect(s2, "It's Mine. My Own. My Precious.");
      final s3 = injector.provideToken(escapeTokenToken);
      expect(s3, 'A new\nline');
      final s4 = injector.provideToken(unicodeToken);
      expect(s4, '\u{0000}');
      final s5 = injector.provideToken(rarerEscapeToken);
      expect(s5, '\t\r\\');
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
  ),
  ValueProvider.forToken(
    singleQuoteToken,
    "It's Mine. My Own. My Precious.",
  ),
  ValueProvider.forToken(
    escapeTokenToken,
    'A new\nline',
  ),
  ValueProvider.forToken(
    unicodeToken,
    '\u{0000}',
  ),
  ValueProvider.forToken(
    rarerEscapeToken,
    '\t\r\\',
  ),
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
const singleQuoteToken = OpaqueToken<String>('singleQuoteToken');
const escapeTokenToken = OpaqueToken<String>('escapeTokenToken');
const unicodeToken = OpaqueToken<String>('unicodeToken');
const rarerEscapeToken = OpaqueToken<String>('rarerEscapeToken');
