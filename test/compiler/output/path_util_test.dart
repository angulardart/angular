@TestOn('browser')
library angular2.test.compiler.output.path_util_test;

import 'package:angular2/src/compiler/output/path_util.dart'
    show getImportModulePath;
import 'package:angular2/testing_internal.dart';
import 'package:test/test.dart';

void main() {
  group('PathUtils getImportModulePath', () {
    test('should calculate relative paths', () {
      expect(
          getImportModulePath(
              'asset:somePkg/lib/modPath', 'asset:somePkg/lib/impPath'),
          'impPath');
    });
    test('should calculate absolute paths', () {
      expect(
          getImportModulePath(
              'asset:somePkg/lib/modPath', 'asset:someOtherPkg/lib/impPath'),
          'package:someOtherPkg/impPath');
    });
    test('should not allow absolute imports of non lib modules', () {
      expect(
          () => getImportModulePath(
              'asset:somePkg/lib/modPath', 'asset:somePkg/test/impPath'),
          throwsWith("Can't import url asset:somePkg/test/impPath from "
              "asset:somePkg/lib/modPath"));
    });
    test('should not allow non asset urls as base url', () {
      expect(
          () => getImportModulePath(
              'http:somePkg/lib/modPath', 'asset:somePkg/test/impPath'),
          throwsWith('Url http:somePkg/lib/modPath is not a valid asset: url'));
    });
    test('should allow non asset urls as import urls and pass them through',
        () {
      expect(getImportModulePath('asset:somePkg/lib/modPath', 'dart:html'),
          'dart:html');
    });
  });
}
