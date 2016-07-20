@TestOn('browser')
library angular2.test.compiler.output.path_util_test;

import 'package:angular2/src/compiler/output/path_util.dart'
    show getImportModulePath, ImportEnv;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

main() {
  group('PathUtils getImportModulePath', () {
    test('should calculate relative paths for JS and Dart', () {
      expect(
          getImportModulePath('asset:somePkg/lib/modPath',
              'asset:somePkg/lib/impPath', ImportEnv.JS),
          './impPath');
      expect(
          getImportModulePath('asset:somePkg/lib/modPath',
              'asset:somePkg/lib/impPath', ImportEnv.Dart),
          'impPath');
    });
    test('should calculate relative paths for different constellations', () {
      expect(
          getImportModulePath('asset:somePkg/test/modPath',
              'asset:somePkg/test/impPath', ImportEnv.JS),
          './impPath');
      expect(
          getImportModulePath('asset:somePkg/lib/modPath',
              'asset:somePkg/lib/dir2/impPath', ImportEnv.JS),
          './dir2/impPath');
      expect(
          getImportModulePath('asset:somePkg/lib/dir1/modPath',
              'asset:somePkg/lib/impPath', ImportEnv.JS),
          '../impPath');
      expect(
          getImportModulePath('asset:somePkg/lib/dir1/modPath',
              'asset:somePkg/lib/dir2/impPath', ImportEnv.JS),
          '../dir2/impPath');
    });
    test('should calculate absolute paths for JS and Dart', () {
      expect(
          getImportModulePath('asset:somePkg/lib/modPath',
              'asset:someOtherPkg/lib/impPath', ImportEnv.JS),
          'someOtherPkg/impPath');
      expect(
          getImportModulePath('asset:somePkg/lib/modPath',
              'asset:someOtherPkg/lib/impPath', ImportEnv.Dart),
          'package:someOtherPkg/impPath');
    });
    test('should not allow absolute imports of non lib modules', () {
      expect(
          () => getImportModulePath('asset:somePkg/lib/modPath',
              'asset:somePkg/test/impPath', ImportEnv.Dart),
          throwsWith(
              'Can\'t import url asset:somePkg/test/impPath from asset:somePkg/lib/modPath'));
    });
    test('should not allow non asset urls as base url', () {
      expect(
          () => getImportModulePath('http:somePkg/lib/modPath',
              'asset:somePkg/test/impPath', ImportEnv.Dart),
          throwsWith('Url http:somePkg/lib/modPath is not a valid asset: url'));
    });
    test('should allow non asset urls as import urls and pass them through',
        () {
      expect(
          getImportModulePath(
              'asset:somePkg/lib/modPath', 'dart:html', ImportEnv.Dart),
          'dart:html');
    });
  });
}
