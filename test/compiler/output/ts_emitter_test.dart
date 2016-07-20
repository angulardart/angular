library angular2.test.compiler.output.ts_emitter_test;

import "package:angular2/src/compiler/compile_metadata.dart"
    show CompileIdentifierMetadata;
import "package:angular2/src/compiler/output/output_ast.dart" as o;
import "package:angular2/src/compiler/output/ts_emitter.dart"
    show TypeScriptEmitter;
import "package:angular2/src/facade/lang.dart" show isBlank;
import 'package:test/test.dart';

var someModuleUrl = "asset:somePackage/lib/somePath";
var anotherModuleUrl = "asset:somePackage/lib/someOtherPath";
var sameModuleIdentifier = new CompileIdentifierMetadata(
    name: "someLocalId", moduleUrl: someModuleUrl);
var externalModuleIdentifier = new CompileIdentifierMetadata(
    name: "someExternalId", moduleUrl: anotherModuleUrl);
main() {
  // Note supported features of our OutputAstin TS:

  // - real `const` like in Dart

  // - final fields
  group("TypeScriptEmitter", () {
    TypeScriptEmitter emitter;
    o.ReadVarExpr someVar;
    setUp(() {
      emitter = new TypeScriptEmitter();
      someVar = o.variable("someVar");
    });
    String emitStmt(o.Statement stmt, [List<String> exportedVars = null]) {
      if (isBlank(exportedVars)) {
        exportedVars = [];
      }
      return emitter.emitStatements(someModuleUrl, [stmt], exportedVars);
    }
    test("should declare variables", () {
      expect(
          emitStmt(someVar.set(o.literal(1)).toDeclStmt()), 'var someVar = 1;');
      expect(
          emitStmt(someVar
              .set(o.literal(1))
              .toDeclStmt(null, [o.StmtModifier.Final])),
          'const someVar = 1;');
      expect(emitStmt(someVar.set(o.literal(1)).toDeclStmt(), ["someVar"]),
          'export var someVar = 1;');
      expect(emitStmt(someVar.set(o.literal(1)).toDeclStmt(o.INT_TYPE)),
          'var someVar:number = 1;');
    });
    test("should read and write variables", () {
      expect(emitStmt(someVar.toStmt()), 'someVar;');
      expect(emitStmt(someVar.set(o.literal(1)).toStmt()), 'someVar = 1;');
      expect(
          emitStmt(someVar
              .set(o.variable("someOtherVar").set(o.literal(1)))
              .toStmt()),
          'someVar = (someOtherVar = 1);');
    });
    test("should read and write keys", () {
      expect(
          emitStmt(o.variable("someMap").key(o.variable("someKey")).toStmt()),
          'someMap[someKey];');
      expect(
          emitStmt(o
              .variable("someMap")
              .key(o.variable("someKey"))
              .set(o.literal(1))
              .toStmt()),
          'someMap[someKey] = 1;');
    });
    test("should read and write properties", () {
      expect(emitStmt(o.variable("someObj").prop("someProp").toStmt()),
          'someObj.someProp;');
      expect(
          emitStmt(o
              .variable("someObj")
              .prop("someProp")
              .set(o.literal(1))
              .toStmt()),
          'someObj.someProp = 1;');
    });
    test("should invoke functions and methods and constructors", () {
      expect(emitStmt(o.variable("someFn").callFn([o.literal(1)]).toStmt()),
          "someFn(1);");
      expect(
          emitStmt(o
              .variable("someObj")
              .callMethod("someMethod", [o.literal(1)]).toStmt()),
          "someObj.someMethod(1);");
      expect(
          emitStmt(
              o.variable("SomeClass").instantiate([o.literal(1)]).toStmt()),
          "new SomeClass(1);");
    });
    test("should support builtin methods", () {
      expect(
          emitStmt(o.variable("arr1").callMethod(
              o.BuiltinMethod.ConcatArray, [o.variable("arr2")]).toStmt()),
          "arr1.concat(arr2);");
      expect(
          emitStmt(o.variable("observable").callMethod(
              o.BuiltinMethod.SubscribeObservable,
              [o.variable("listener")]).toStmt()),
          "observable.subscribe(listener);");
      expect(
          emitStmt(o.variable("fn").callMethod(
              o.BuiltinMethod.bind, [o.variable("someObj")]).toStmt()),
          "fn.bind(someObj);");
    });
    test("should support literals", () {
      expect(emitStmt(o.literal(0).toStmt()), "0;");
      expect(emitStmt(o.literal(true).toStmt()), "true;");
      expect(emitStmt(o.literal("someStr").toStmt()), "'someStr';");
      expect(emitStmt(o.literalArr([o.literal(1)]).toStmt()), '[1];');
      expect(
          emitStmt(o.literalMap([
            ["someKey", o.literal(1)]
          ]).toStmt()),
          '{\'someKey\': 1};');
    });
    test("should support external identifiers", () {
      expect(emitStmt(o.importExpr(sameModuleIdentifier).toStmt()),
          "someLocalId;");
      expect(
          emitStmt(o.importExpr(externalModuleIdentifier).toStmt()),
          [
            '''import * as import0 from \'./someOtherPath\';''',
            '''import0.someExternalId;'''
          ].join("\n"));
    });
    test("should support operators", () {
      var lhs = o.variable("lhs");
      var rhs = o.variable("rhs");
      expect(emitStmt(someVar.cast(o.INT_TYPE).toStmt()), "(<number>someVar);");
      expect(emitStmt(o.not(someVar).toStmt()), "!someVar;");
      expect(
          emitStmt(someVar
              .conditional(o.variable("trueCase"), o.variable("falseCase"))
              .toStmt()),
          "(someVar? trueCase: falseCase);");
      expect(emitStmt(lhs.equals(rhs).toStmt()), "(lhs == rhs);");
      expect(emitStmt(lhs.notEquals(rhs).toStmt()), "(lhs != rhs);");
      expect(emitStmt(lhs.identical(rhs).toStmt()), "(lhs === rhs);");
      expect(emitStmt(lhs.notIdentical(rhs).toStmt()), "(lhs !== rhs);");
      expect(emitStmt(lhs.minus(rhs).toStmt()), "(lhs - rhs);");
      expect(emitStmt(lhs.plus(rhs).toStmt()), "(lhs + rhs);");
      expect(emitStmt(lhs.divide(rhs).toStmt()), "(lhs / rhs);");
      expect(emitStmt(lhs.multiply(rhs).toStmt()), "(lhs * rhs);");
      expect(emitStmt(lhs.modulo(rhs).toStmt()), "(lhs % rhs);");
      expect(emitStmt(lhs.and(rhs).toStmt()), "(lhs && rhs);");
      expect(emitStmt(lhs.or(rhs).toStmt()), "(lhs || rhs);");
      expect(emitStmt(lhs.lower(rhs).toStmt()), "(lhs < rhs);");
      expect(emitStmt(lhs.lowerEquals(rhs).toStmt()), "(lhs <= rhs);");
      expect(emitStmt(lhs.bigger(rhs).toStmt()), "(lhs > rhs);");
      expect(emitStmt(lhs.biggerEquals(rhs).toStmt()), "(lhs >= rhs);");
    });
    test("should support function expressions", () {
      expect(
          emitStmt(o.fn([], []).toStmt()), ["():void => {", "};"].join("\n"));
      expect(
          emitStmt(o.fn(
              [], [new o.ReturnStatement(o.literal(1))], o.INT_TYPE).toStmt()),
          ["():number => {", "  return 1;\n};"].join("\n"));
      expect(emitStmt(o.fn([new o.FnParam("param1", o.INT_TYPE)], []).toStmt()),
          ["(param1:number):void => {", "};"].join("\n"));
    });
    test("should support function statements", () {
      expect(emitStmt(new o.DeclareFunctionStmt("someFn", [], [])),
          ["function someFn():void {", "}"].join("\n"));
      expect(emitStmt(new o.DeclareFunctionStmt("someFn", [], []), ["someFn"]),
          ["export function someFn():void {", "}"].join("\n"));
      expect(
          emitStmt(new o.DeclareFunctionStmt(
              "someFn", [], [new o.ReturnStatement(o.literal(1))], o.INT_TYPE)),
          ["function someFn():number {", "  return 1;", "}"].join("\n"));
      expect(
          emitStmt(new o.DeclareFunctionStmt(
              "someFn", [new o.FnParam("param1", o.INT_TYPE)], [])),
          ["function someFn(param1:number):void {", "}"].join("\n"));
    });
    test("should support comments", () {
      expect(emitStmt(new o.CommentStmt("a\nb")), ["// a", "// b"].join("\n"));
    });
    test("should support if stmt", () {
      var trueCase = o.variable("trueCase").callFn([]).toStmt();
      var falseCase = o.variable("falseCase").callFn([]).toStmt();
      expect(emitStmt(new o.IfStmt(o.variable("cond"), [trueCase])),
          ["if (cond) { trueCase(); }"].join("\n"));
      expect(
          emitStmt(new o.IfStmt(o.variable("cond"), [trueCase], [falseCase])),
          ["if (cond) {", "  trueCase();", "} else {", "  falseCase();", "}"]
              .join("\n"));
    });
    test("should support try/catch", () {
      var bodyStmt = o.variable("body").callFn([]).toStmt();
      var catchStmt = o
          .variable("catchFn")
          .callFn([o.CATCH_ERROR_VAR, o.CATCH_STACK_VAR]).toStmt();
      expect(
          emitStmt(new o.TryCatchStmt([bodyStmt], [catchStmt])),
          [
            "try {",
            "  body();",
            "} catch (error) {",
            "  const stack = error.stack;",
            "  catchFn(error,stack);",
            "}"
          ].join("\n"));
    });
    test("should support support throwing", () {
      expect(emitStmt(new o.ThrowStmt(someVar)), "throw someVar;");
    });
    group("classes", () {
      o.Statement callSomeMethod;
      setUp(() {
        callSomeMethod = o.THIS_EXPR.callMethod("someMethod", []).toStmt();
      });
      test("should support declaring classes", () {
        expect(emitStmt(new o.ClassStmt("SomeClass", null, [], [], null, [])),
            ["class SomeClass {", "}"].join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [], null, []),
                ["SomeClass"]),
            ["export class SomeClass {", "}"].join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass", o.variable("SomeSuperClass"), [], [], null, [])),
            ["class SomeClass extends SomeSuperClass {", "}"].join("\n"));
      });
      test("should support declaring constructors", () {
        var superCall = o.SUPER_EXPR.callFn([o.variable("someParam")]).toStmt();
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [],
                new o.ClassMethod(null, [], []), [])),
            ["class SomeClass {", "  constructor() {", "  }", "}"].join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [],
                [],
                new o.ClassMethod(
                    null, [new o.FnParam("someParam", o.INT_TYPE)], []),
                [])),
            [
              "class SomeClass {",
              "  constructor(someParam:number) {",
              "  }",
              "}"
            ].join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [],
                new o.ClassMethod(null, [], [superCall]), [])),
            [
              "class SomeClass {",
              "  constructor() {",
              "    super(someParam);",
              "  }",
              "}"
            ].join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [],
                new o.ClassMethod(null, [], [callSomeMethod]), [])),
            [
              "class SomeClass {",
              "  constructor() {",
              "    this.someMethod();",
              "  }",
              "}"
            ].join("\n"));
      });
      test("should support declaring fields", () {
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null,
                [new o.ClassField("someField")], [], null, [])),
            ["class SomeClass {", "  someField;", "}"].join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null,
                [new o.ClassField("someField", o.INT_TYPE)], [], null, [])),
            ["class SomeClass {", "  someField:number;", "}"].join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [
                  new o.ClassField(
                      "someField", o.INT_TYPE, [o.StmtModifier.Private])
                ],
                [],
                null,
                [])),
            ["class SomeClass {", "  private someField:number;", "}"]
                .join("\n"));
      });
      test("should support declaring getters", () {
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [],
                [new o.ClassGetter("someGetter", [])], null, [])),
            ["class SomeClass {", "  get someGetter() {", "  }", "}"]
                .join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [],
                [new o.ClassGetter("someGetter", [], o.INT_TYPE)], null, [])),
            ["class SomeClass {", "  get someGetter():number {", "  }", "}"]
                .join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [],
                [
                  new o.ClassGetter("someGetter", [callSomeMethod])
                ],
                null,
                [])),
            [
              "class SomeClass {",
              "  get someGetter() {",
              "    this.someMethod();",
              "  }",
              "}"
            ].join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [],
                [
                  new o.ClassGetter(
                      "someGetter", [], null, [o.StmtModifier.Private])
                ],
                null,
                [])),
            ["class SomeClass {", "  private get someGetter() {", "  }", "}"]
                .join("\n"));
      });
      test("should support methods", () {
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [], null,
                [new o.ClassMethod("someMethod", [], [])])),
            ["class SomeClass {", "  someMethod():void {", "  }", "}"]
                .join("\n"));
        expect(
            emitStmt(new o.ClassStmt("SomeClass", null, [], [], null,
                [new o.ClassMethod("someMethod", [], [], o.INT_TYPE)])),
            ["class SomeClass {", "  someMethod():number {", "  }", "}"]
                .join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [],
                [],
                null,
                [
                  new o.ClassMethod("someMethod",
                      [new o.FnParam("someParam", o.INT_TYPE)], [])
                ])),
            [
              "class SomeClass {",
              "  someMethod(someParam:number):void {",
              "  }",
              "}"
            ].join("\n"));
        expect(
            emitStmt(new o.ClassStmt(
                "SomeClass",
                null,
                [],
                [],
                null,
                [
                  new o.ClassMethod("someMethod", [], [callSomeMethod])
                ])),
            [
              "class SomeClass {",
              "  someMethod():void {",
              "    this.someMethod();",
              "  }",
              "}"
            ].join("\n"));
      });
    });
    test("should support builtin types", () {
      var writeVarExpr = o.variable("a").set(o.NULL_EXPR);
      expect(emitStmt(writeVarExpr.toDeclStmt(o.DYNAMIC_TYPE)),
          "var a:any = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(o.BOOL_TYPE)),
          "var a:boolean = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(o.INT_TYPE)),
          "var a:number = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(o.NUMBER_TYPE)),
          "var a:number = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(o.STRING_TYPE)),
          "var a:string = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(o.FUNCTION_TYPE)),
          "var a:Function = null;");
    });
    test("should support external types", () {
      var writeVarExpr = o.variable("a").set(o.NULL_EXPR);
      expect(
          emitStmt(writeVarExpr.toDeclStmt(o.importType(sameModuleIdentifier))),
          "var a:someLocalId = null;");
      expect(
          emitStmt(
              writeVarExpr.toDeclStmt(o.importType(externalModuleIdentifier))),
          [
            '''import * as import0 from \'./someOtherPath\';''',
            '''var a:import0.someExternalId = null;'''
          ].join("\n"));
    });
    test("should support combined types", () {
      var writeVarExpr = o.variable("a").set(o.NULL_EXPR);
      expect(emitStmt(writeVarExpr.toDeclStmt(new o.ArrayType(null))),
          "var a:any[] = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(new o.ArrayType(o.INT_TYPE))),
          "var a:number[] = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(new o.MapType(null))),
          "var a:{[key: string]:any} = null;");
      expect(emitStmt(writeVarExpr.toDeclStmt(new o.MapType(o.INT_TYPE))),
          "var a:{[key: string]:number} = null;");
    });
  });
}
