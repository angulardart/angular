@TestOn('vm')
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';
import 'package:angular/src/source_gen/common/annotation_model.dart';
import 'package:angular/src/source_gen/common/parameter_model.dart';
import 'package:angular/src/source_gen/common/reflection_info_model.dart';

void main() {
  group('ReflectionInfoModel', () {
    group('single reflection model', () {
      var reflectionModel =
          new ReflectionInfoModel(type: reference('Foo', 'foo.dart'));
      test('local metadata map', () {
        expectLocalMetadataMap(
            reflectionModel, '[_i1.Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            _i1.reflector.registerSimpleType(_i2.Foo, () => new _i2.Foo());
            ''');
      });
    });

    group('with single annotation', () {
      var reflectionModel = new ReflectionInfoModel(
          type: reference('Foo'),
          annotations: [new AnnotationModel(name: 'Bar')]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            reflectionModel, '[Foo, const <dynamic> [const Bar()]]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            _i1.reflector.registerType(Foo, new _i1.ReflectionInfo(
              const <dynamic> [const Bar()], const [], () => new Foo()));
            ''');
      });
    });

    group('with multiple annotations', () {
      var reflectionModel =
          new ReflectionInfoModel(type: reference('Foo'), annotations: [
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
            _i1.reflector.registerType(Foo, new _i1.ReflectionInfo(
              const <dynamic> [const Bar(), Baz], const [], () => new Foo()));
            ''');
      });
    });

    group('excludes NgFactory annotations', () {
      var reflectionModel = new ReflectionInfoModel(
          type: reference('Foo'),
          annotations: [
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
            _i1.reflector.registerType(Foo, new _i1.ReflectionInfo(
              const <dynamic> [const Bar(), const TestNgFactory()],
              const [],
              () => new Foo()));
            ''');
      });
    });

    group('with single parameter', () {
      var reflectionModel = new ReflectionInfoModel(
          type: reference('Foo'),
          parameters: [new ParameterModel(paramName: 'bar', typeName: 'Bar')]);

      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            _i1.reflector.registerType(Foo, new _i1.ReflectionInfo(
              const <dynamic> [],
              const [const <dynamic> [Bar]],
              (Bar bar) => new Foo(bar)));
            ''');
      });
    });

    group('with multiple parameters', () {
      var reflectionModel =
          new ReflectionInfoModel(type: reference('Foo'), parameters: [
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
            _i1.reflector.registerType(Foo, new _i1.ReflectionInfo(
              const <dynamic> [],
              const [const <dynamic> [Bar], const <dynamic> [Baz]],
              (Bar bar, Baz baz) => new Foo(bar, baz)));
            ''');
      });
    });

    group('is function', () {
      var reflectionModel =
          new ReflectionInfoModel(type: reference('Foo'), isFunction: true);
      test('local metadata map', () {
        expectLocalMetadataMap(reflectionModel, '[Foo, const <dynamic> []]');
      });

      test('writeRegistration', () {
        expectRegistration(
            reflectionModel,
            r'''
            _i1.reflector.registerFunction(
              Foo, new _i1.ReflectionInfo(const <dynamic> [], const []));
            ''');
      });
    });
  });
}

void expectLocalMetadataMap(ReflectionInfoModel models, String expectedOutput) {
  expect(list(models.localMetadataEntry),
      equalsSource(expectedOutput, scope: new Scope()));
}

expectRegistration(ReflectionInfoModel model, String expectedOutput) {
  // In order to force registration to be a statement instead of an expression,
  // and thus parse for the formatter, we wrap in an if statement.
  expect(ifThen(literal(true), [(model.asRegistration)]),
      equalsSource('if (true) {$expectedOutput}', scope: new Scope()));
}
