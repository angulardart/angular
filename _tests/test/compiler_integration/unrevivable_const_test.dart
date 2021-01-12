// @dart=2.9

import 'package:test/test.dart';
import 'package:_tests/compiler.dart';
import 'package:angular_compiler/v2/context.dart';

void main() {
  CompileContext.overrideForTesting();

  test('should fail with an error for private constructor', () async {
    await compilesExpecting('''
      import '$ngImport';

      class TestClass {
        const TestClass._();
      }

      @GenerateInjector([
        ValueProvider(TestClass, TestClass._()),
      ])
      final example = null;
    ''', errors: [
      allOf([
        contains('While attempting to resolve a constant value for a provider'),
        contains('TestClass'),
      ]),
    ]);
  });

  test('should fail with an error for private parameter', () async {
    await compilesExpecting('''
      import '$ngImport';

      String _returnHelloWorld() => 'Hello World';

      class TestClass {
        final returnsString;
        const TestClass(this.returnsString);
      }

      const testInstance = TestClass(_returnHelloWorld);

      @GenerateInjector([
        ValueProvider(TestClass, testInstance),
      ])
      final example = null;
    ''', errors: [
      allOf(
        contains('While attempting to resolve a constant value for a '),
        contains('input.dart::_returnHelloWorld'),
      ),
    ]);
  });

  test('should fail with an error for unresolved provider', () async {
    await compilesExpecting('''
      import '$ngImport';

      const badModule = Module(
        provide: const [
          unknownToken,
        ],
      );

      @GenerateInjector(const [
        badModule,
      ])
      final example = null;
    ''', errors: [
      allOf([
        contains('Expected list for \'provide\' field of Module'),
      ]),
    ]);
  });
}
