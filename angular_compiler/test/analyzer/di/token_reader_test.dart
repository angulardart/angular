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
      ];

      @tokens
      class Example {}
    ''')).metadata.first.computeConstantValue().toListValue();
    });

    test('Type', () {
      final token = reader.parseTokenObject(tokens[0]);
      expect(token, const isInstanceOf<TypeTokenElement>());
      expect(
        '${(token as TypeTokenElement).url}',
        'asset:test_lib/lib/test_lib.dart#Example',
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

    test('invalid token type', () {
      expect(() => reader.parseTokenObject(tokens[2]), throwsArgumentError);
    });
  });
}
