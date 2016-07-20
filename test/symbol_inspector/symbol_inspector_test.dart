library angular2.test.symbol_inspector.symbol_inspector_test;

import "package:angular2/src/facade/lang.dart" show IS_DART;
import 'package:test/test.dart';

import "symbol_inspector.dart" show getSymbolsFromLibrary;

main() {
  group("symbol inspector", () {
    if (IS_DART) {
      test("should extract symbols (dart)", () {
        var symbols = getSymbolsFromLibrary("simple_library");
        expect(symbols,[
          "A",
          "ClosureParam",
          "ClosureReturn",
          "ConsParamType",
          "FieldType",
          "Generic",
          "GetterType",
          "MethodReturnType",
          "ParamType",
          "SomeInterface",
          "StaticFieldType",
          "TypedefParam",
          "TypedefReturnType"
        ]);
      });
    } else {
      test("should extract symbols (js)", () {
        var symbols = getSymbolsFromLibrary("simple_library");
        expect(symbols,[
          "A",
          "ClosureParam",
          "ClosureReturn",
          "ConsParamType",
          "FieldType",
          "Generic",
          "GetterType",
          "MethodReturnType",
          "ParamType",
          "StaticFieldType",
          "TypedefParam",
          "TypedefReturnType"
        ]);
      });
    }
  });
}
