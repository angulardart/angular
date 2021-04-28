import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v2/context.dart';

import '../../src/resolve.dart';

void main() {
  group('should parse tokens from a constant representing a', () {
    late List<DartObject> tokens;
    final reader = const TokenReader();

    setUpAll(() async {
      tokens = (await resolveClass(r'''
      const tokens = const [
        Example,
        const OpaqueToken('exampleToken'),
        #fooBar,
        'someString',
        1234,
        const Example(),
      ];

      @tokens
      class Example {
        const Example();
      }
    '''))!.metadata.first.computeConstantValue()!.toListValue()!;
    });

    test('Type', () {
      final token = reader.parseTokenObject(tokens[0]);
      expect(token, const TypeMatcher<TypeTokenElement>());
      expect(
        (token as TypeTokenElement).link,
        TypeLink('Example', 'asset:test_lib/lib/test_lib.dart'),
      );
    });

    test('OpaqueToken', () {
      final token = reader.parseTokenObject(tokens[1]);
      expect(token, const TypeMatcher<OpaqueTokenElement>());
      expect(
        '${(token as OpaqueTokenElement).identifier}',
        'exampleToken',
      );
    });

    group('LiteralToken throws', () {
      test('for a String', () {
        expect(() => reader.parseTokenObject(tokens[3]), throwsBuildError);
      });

      test('for an int', () {
        expect(() => reader.parseTokenObject(tokens[4]), throwsBuildError);
      });

      test('for an arbitrary class throws', () {
        expect(() => reader.parseTokenObject(tokens[5]), throwsBuildError);
      });
    });

    test('invalid token type', () {
      expect(() => reader.parseTokenObject(tokens[2]), throwsBuildError);
    });
  });

  group('linkToOpaqueToken', () {
    final linkToOpaqueToken = const TokenReader().linkToOpaqueToken;
    late LibraryElement library;

    setUpAll(() async {
      library = await resolveLibrary(r'''
        // Used as an example of any arbitrary interface.
        abstract class A {}

        abstract class InvalidOpaqueToken_IsAbstract extends OpaqueToken {
          const InvalidOpaqueToken_IsAbstract();
        }

        class _InvalidOpaqueToken_IsPrivate extends OpaqueToken {
          const _InvalidOpaqueToken_IsPrivate();
        }

        class InvalidOpaqueToken_NotConst extends OpaqueToken {
          InvalidOpaqueToken_NotConst();
        }

        class InvalidOpaqueToken_NoUnnammed extends OpaqueToken {
          const InvalidOpaqueToken_NoUnnammed.named();
        }

        class InvalidOpaqueToken_HasTypeParameters<T> extends OpaqueToken<T> {
          const InvalidOpaqueToken_HasTypeParameters();
        }

        class InvalidOpaqueToken_HasParameters extends OpaqueToken {
          const InvalidOpaqueToken_HasParameters(String name);
        }

        class InvalidOpaqueToken_InvalidSubType extends ValidOpaqueToken {
          const InvalidOpaqueToken_InvalidSubType();
        }

        class InvalidOpaquetoken_Implements extends OpaqueToken implements A {}

        class InvalidOpaqueToken_Mixins extends OpaqueToken with A {}

        class ValidOpaqueToken extends OpaqueToken<String> {
          const ValidOpaqueToken();
        }
      ''');
    });

    InterfaceType instantiateClass(String name) {
      final element = library.getType(name)!;
      return element.instantiate(
        typeArguments: List.filled(
          element.typeParameters.length,
          library.typeProvider.dynamicType,
        ),
        nullabilitySuffix: NullabilitySuffix.star,
      );
    }

    test('should fail on an abstract class', () {
      final type = instantiateClass('InvalidOpaqueToken_IsAbstract');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a private class', () {
      final type = instantiateClass('_InvalidOpaqueToken_IsPrivate');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a non-const class', () {
      final type = instantiateClass('InvalidOpaqueToken_NotConst');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class without a default constructor', () {
      final type = instantiateClass('InvalidOpaqueToken_NoUnnammed');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class with type parameters', () {
      final type = instantiateClass('InvalidOpaqueToken_HasTypeParameters');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class with constructor parameters', () {
      final type = instantiateClass('InvalidOpaqueToken_HasParameters');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class not directly extending Opaque/MultiToken', () {
      final type = instantiateClass('InvalidOpaqueToken_InvalidSubType');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class implementing another class', () {
      final type = instantiateClass('InvalidOpaquetoken_Implements');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class mixing in another class', () {
      final type = instantiateClass('InvalidOpaqueToken_Mixins');
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should succeed on a class that directly extends OpaqueToken', () {
      final type = instantiateClass('ValidOpaqueToken');
      final link = linkToOpaqueToken(type);
      expect(link.symbol, 'ValidOpaqueToken');
      expect(link.generics, isEmpty);
    });
  });
}

final throwsBuildError = throwsA(const TypeMatcher<BuildError>());
