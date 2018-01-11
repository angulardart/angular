import 'package:analyzer/dart/constant/value.dart';
import 'package:angular_compiler/angular_compiler.dart';
import 'package:test/test.dart';

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
      expect(token, const isInstanceOf<TypeTokenElement>());
      expect(
        (token as TypeTokenElement).link,
        new TypeLink('Example', 'asset:test_lib/lib/test_lib.dart'),
      );
    });

    test('OpaqueToken', () {
      final token = reader.parseTokenObject(tokens[1]);
      expect(token, const isInstanceOf<OpaqueTokenElement>());
      expect(
        '${(token as OpaqueTokenElement).identifier}',
        'exampleToken',
      );
    });

    group('LiteralToken', () {
      test('for a String', () {
        final token = reader.parseTokenObject(tokens[3]);
        expect(token, const isInstanceOf<LiteralTokenElement>());
        expect(
          '${(token as LiteralTokenElement).literal}',
          'r\'someString\'',
        );
      });

      test('for an int', () {
        final token = reader.parseTokenObject(tokens[4]);
        expect(token, const isInstanceOf<LiteralTokenElement>());
        expect(
          '${(token as LiteralTokenElement).literal}',
          '1234',
        );
      });

      test('for an arbitrary class', () {
        final token = reader.parseTokenObject(tokens[5]);
        expect(token, const isInstanceOf<LiteralTokenElement>());
        expect(
          '${(token as LiteralTokenElement).literal}',
          'const Example()',
        );
      });
    });

    test('invalid token type', () {
      expect(() => reader.parseTokenObject(tokens[2]), throwsArgumentError);
    });
  });
}
