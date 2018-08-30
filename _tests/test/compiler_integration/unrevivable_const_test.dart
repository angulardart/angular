@TestOn('vm')
import 'package:_tests/compiler.dart';
import 'package:test/test.dart';

void main() {
  test('should fail with an error for private constructor', () async {
    await compilesExpecting('''
      import '$ngImport';

      class TestClass {
        const TestClass._();
      }

      @GenerateInjector([
        ValueProvider(TestClass, TestClass._()),
      ])
      final InjectorFactory example = null;
    ''', errors: [
      allOf([
        // TODO(matanl): Improve after source_gen#374.
        // https://github.com/dart-lang/source_gen/issues/374
        contains('Could not reference const object'),
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
      final InjectorFactory example = null;
    ''', errors: [
      allOf(
        contains('While attempting to resolve a constant value for a '),
        contains('input.dart::_returnHelloWorld'),
      ),
    ]);
  });
}
