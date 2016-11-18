import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';

void main() {
  group('AnnotationModel', () {
    test('const annotation', () {
      expect(new AnnotationModel(name: 'foo', isConstObject: true).asExpression,
          equalsSource('foo'));
    });

    test('no parameters', () {
      expect(new AnnotationModel(name: 'foo').asExpression,
          equalsSource('const foo()'));
    });

    test('has parameters', () {
      expect(
          new AnnotationModel(name: 'foo', parameters: ['bar, baz'])
              .asExpression,
          equalsSource('const foo(bar, baz)'));
    });

    test('has named parameters', () {
      expect(
          new AnnotationModel(
              name: 'foo',
              namedParameters: [new NamedParameter('bar', 'baz')]).asExpression,
          equalsSource('const foo(bar: baz)'));
    });

    test('has positional and named parameters', () {
      expect(
          new AnnotationModel(
                  name: 'foo',
                  parameters: ['bar', 'baz'],
                  namedParameters: [new NamedParameter('fizz', 'buzz')])
              .asExpression,
          equalsSource('const foo(bar, baz, fizz: buzz)'));
    });
  });
}
