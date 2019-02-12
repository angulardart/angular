import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';
import 'package:angular_compiler/cli.dart';

import '../../src/resolve.dart';

void main() {
  group('should parse tokens from a constant representing a', () {
    List<DartObject> tokens;
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
    ''')).metadata.first.computeConstantValue().toListValue();
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
    LibraryElement library;

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

    test('should fail on an abstract class', () {
      final type = library.getType('InvalidOpaqueToken_IsAbstract').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a private class', () {
      final type = library.getType('_InvalidOpaqueToken_IsPrivate').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a non-const class', () {
      final type = library.getType('InvalidOpaqueToken_NotConst').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class without a default constructor', () {
      final type = library.getType('InvalidOpaqueToken_NoUnnammed').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class with type parameters', () {
      final type = library.getType('InvalidOpaqueToken_HasTypeParameters').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class with constructor parameters', () {
      final type = library.getType('InvalidOpaqueToken_HasParameters').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class not directly extending Opaque/MultiToken', () {
      final type = library.getType('InvalidOpaqueToken_InvalidSubType').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class implementing another class', () {
      final type = library.getType('InvalidOpaquetoken_Implements').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should fail on a class mixing in another class', () {
      final type = library.getType('InvalidOpaqueToken_Mixins').type;
      expect(() => linkToOpaqueToken(type), throwsBuildError);
    });

    test('should succeed on a class that directly extends OpaqueToken', () {
      final type = library.getType('ValidOpaqueToken').type;
      final link = linkToOpaqueToken(type);
      expect(link.symbol, 'ValidOpaqueToken');
      expect(link.generics, isEmpty);
    });
  });
}

final throwsBuildError = throwsA(const TypeMatcher<BuildError>());
