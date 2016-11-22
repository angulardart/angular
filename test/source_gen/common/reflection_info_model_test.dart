import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';

void main() {
  group('ReflectionInfoModel', () {
    group('single reflection model', () {
      var reflectionModel = new ReflectionInfoModel(name: 'Foo');
      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [], const [], () => new Foo()));
            ''');
      });
    });

    group('with single annotation', () {
      var reflectionModel = new ReflectionInfoModel(
          name: 'Foo', annotations: [new AnnotationModel(name: 'Bar')]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            reflectionModel, '[Foo, const <dynamic> [const Bar()]]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [const Bar()], const [], () => new Foo()));
            ''');
      });
    });

    group('with multiple annotations', () {
      var reflectionModel = new ReflectionInfoModel(name: 'Foo', annotations: [
        new AnnotationModel(name: 'Bar'),
        new AnnotationModel(name: 'Baz', isConstObject: true)
      ]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            reflectionModel, '[Foo, const <dynamic> [const Bar(), Baz]]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [const Bar(), Baz], const [], () => new Foo()));
            ''');
      });
    });

    group('excludes NgFactory annotations', () {
      var reflectionModel = new ReflectionInfoModel(name: 'Foo', annotations: [
        new AnnotationModel(name: 'Bar'),
        new AnnotationModel(name: 'TestNgFactory')
      ]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            reflectionModel, '[Foo, const <dynamic> [const Bar()]]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [const Bar(), const TestNgFactory()],
              const [],
              () => new Foo()));
            ''');
      });
    });

    group('with single parameter', () {
      var reflectionModel = new ReflectionInfoModel(
          name: 'Foo',
          parameters: [new ParameterModel(paramName: 'bar', typeName: 'Bar')]);

      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [],
              const [const <dynamic> [Bar]],
              (Bar bar) => new Foo(bar)));
            ''');
      });
    });

    group('with multiple parameters', () {
      var reflectionModel = new ReflectionInfoModel(name: 'Foo', parameters: [
        new ParameterModel(paramName: 'bar', typeName: 'Bar'),
        new ParameterModel(paramName: 'baz', typeName: 'Baz')
      ]);

      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerType(Foo, new ReflectionInfo(
              const <dynamic> [],
              const [const <dynamic> [Bar], const <dynamic> [Baz]],
              (Bar bar, Baz baz) => new Foo(bar, baz)));
            ''');
      });
    });

    group('is function', () {
      var reflectionModel =
          new ReflectionInfoModel(name: 'Foo', isFunction: true);
      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            reflector.registerFunction(
              Foo, new ReflectionInfo(const <dynamic> [], const []));
            ''');
      });
    });
  });
}

void expectLocalMetadataMap(ReflectionInfoModel models, String expectedOutput) {
  expect(list(models.localMetadataEntry), equalsSource(expectedOutput));
}

expectRegistration(ReflectionInfoModel model, String expectedOutput) {
  // In order to force registration to be a statement instead of an expression,
  // and thus parse for the formatter, we wrap in an if statement.
  expect(ifThen(literal(true), [(model.asRegistration)]),
      equalsSource('if (true) {$expectedOutput}'));
}
