@TestOn('browser && !js')
library angular2.test.symbol_inspector.symbol_inspector_test;

import 'dart:mirrors';

import 'package:test/test.dart';

import '../public_apis.dart';
import 'simple_library.dart';
import 'symbol_inspector.dart';

void main() {
  group('getSymbolsFromLibrary', () {
    test('should extract symbols', () {
      var simpleLib = reflectClass(A).owner as LibraryMirror;
      var symbols = getSymbolsFromLibrary(simpleLib);
      expect(symbols, [
        'A',
        'ClosureParam',
        'ClosureReturn',
        'ConsParamType',
        'FieldType',
        'Generic',
        'GetterType',
        'MethodReturnType',
        'ParamType',
        'SomeInterface',
        'StaticFieldType',
        'TypedefParam',
        'TypedefReturnType'
      ]);
    });
  });
  group('ng2libs', () {
    test('should be available via mirrors', () {
      for (var libPath in publicLibraries.keys) {
        var pkgPath = "package:angular2/$libPath";

        expect(getLibrary(libPath).uri.toString(), pkgPath);
      }
    });
  });
}
