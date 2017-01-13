@TestOn('vm')
import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:code_builder/code_builder.dart';
import 'package:code_builder/testing.dart';
import 'package:test/test.dart';

void main() {
  group('NgDepsModel', () {
    test('empty model', () {
      expectSetupMethod(new NgDepsModel(), 'void initReflector() {}');
    });

    group('single reflection model', () {
      var ngDepsModel = new NgDepsModel(
          reflectables: [new ReflectionInfoModel(type: reference('Foo'))]);
      test('local metadata map', () {
        expectLocalMetadataMap(ngDepsModel,
            'const _METADATA = const <dynamic>[Foo, const <dynamic>[]];\n');
      });

      test('setupMethod', () {
        expectSetupMethod(
            ngDepsModel,
            r'''
            var _visited = false;
            void initReflector() {
              if (_visited) {
                return;
              }
              _visited = true;
              reflector.registerType(Foo, new ReflectionInfo(
                const <dynamic> [], const [], () => new Foo()));
            }
            ''');
      });
    });

    group('multiple reflection models', () {
      var ngDepsModel = new NgDepsModel(reflectables: [
        new ReflectionInfoModel(type: reference('Foo')),
        new ReflectionInfoModel(type: reference('Bar'))
      ]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            ngDepsModel,
            r'''
            const _METADATA =
              const <dynamic>[Foo, const <dynamic> [], Bar, const <dynamic> []];
            ''');
      });

      test('setupMethod', () {
        expectSetupMethod(
            ngDepsModel,
            r'''
            var _visited = false;
            void initReflector() {
              if (_visited) {
                return;
              }
              _visited = true;
              reflector.registerType(Foo, new ReflectionInfo(
                const <dynamic> [], const [], () => new Foo()));
              reflector.registerType(Bar, new ReflectionInfo(
                const <dynamic> [], const [], () => new Bar()));
            }
            ''');
      });
    });

    group('is function', () {
      var ngDepsModel = new NgDepsModel(reflectables: [
        new ReflectionInfoModel(type: reference('Foo'), isFunction: true)
      ]);
      test('local metadata map', () {
        expectLocalMetadataMap(ngDepsModel,
            'const _METADATA = const <dynamic>[Foo, const <dynamic>[]];\n');
      });

      test('setupMethod', () {
        expectSetupMethod(
            ngDepsModel,
            r'''
            var _visited = false;
            void initReflector() {
              if (_visited) {
                return;
              }
              _visited = true;
              reflector.registerFunction(
                Foo, new ReflectionInfo(const <dynamic> [], const []));
            }
            ''');
      });
    });

    group('depImports', () {
      var ngDepsModel = new NgDepsModel(depImports: [
        new ImportModel(uri: 'package:foo/foo.dart'),
        new ImportModel(uri: 'package:bar/bar.dart')
      ]);
      test('local metadata map', () {
        expectLocalMetadataMap(
            ngDepsModel, 'const _METADATA = const <dynamic>[];\n');
      });

      test('setupMethod', () {
        expectSetupMethod(
            ngDepsModel,
            r'''
            var _visited = false;
            void initReflector() {
              if (_visited) {
                return;
              }
              _visited = true;
              initReflector();
              initReflector();
            }
            ''');
      });
    });
  });
}

void expectLocalMetadataMap(NgDepsModel model, String expectedOutput) {
  expect(model.localMetadataMap, equalsSource(expectedOutput));
}

expectSetupMethod(NgDepsModel model, String expectedOutput) {
  var library = new LibraryBuilder();
  model.setupMethod.forEach(library.addMember);
  expect(library, equalsSource(expectedOutput));
}
