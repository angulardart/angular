@TestOn('vm')
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ParameterModel', () {
    group('for list', () {
      test('empty model', () {
        expect(new ParameterModel().asList, equalsSource('const <dynamic> []'));
      });

      test('has type name', () {
        expect(new ParameterModel(typeName: 'Foo').asList,
            equalsSource('const <dynamic> [Foo]'));
      });

      test('has metadata', () {
        expect(new ParameterModel(metadata: ['foo', 'bar', 'baz']).asList,
            equalsSource('const <dynamic> [foo, bar, baz]'));
      });

      test('has type name and metadata', () {
        expect(
            new ParameterModel(typeName: 'Foo', metadata: ['bar', 'baz'])
                .asList,
            equalsSource('const <dynamic> [Foo, bar, baz]'));
      });
    });

    group('for declaration', () {
      test('has type name and param name', () {
        expect(new ParameterModel(typeName: 'Foo', paramName: 'foo').asBuilder,
            equalsSource('Foo foo'));
      });

      test('has type name, type args, and param name', () {
        expect(
            new ParameterModel(
                    typeName: 'Foo', typeArgs: ['Bar'], paramName: 'foo')
                .asBuilder,
            equalsSource('Foo<Bar> foo'));
      });
    });
  });
}
