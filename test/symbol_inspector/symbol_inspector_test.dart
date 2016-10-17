@TestOn('browser && !js')
library angular2.test.symbol_inspector.symbol_inspector_test;

import 'dart:mirrors';

import 'package:test/test.dart';

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
      expect(commonLib.uri.toString(), 'package:angular2/common.dart');
      expect(compilerLib.uri.toString(), 'package:angular2/compiler.dart');
      expect(coreLib.uri.toString(), 'package:angular2/core.dart');
      expect(instrumentationLib.uri.toString(),
          'package:angular2/instrumentation.dart');
      expect(platformBrowserLib.uri.toString(),
          'package:angular2/platform/browser.dart');
      expect(platformCommonLib.uri.toString(),
          'package:angular2/platform/common.dart');
    });
  });
}
