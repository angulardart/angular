@TestOn('browser')
library angular2.test.compiler.output.output_emitter_test;

import "package:angular2/testing_internal.dart";
import "output_emitter_codegen_typed.dart" as typed;
import "package:angular2/src/compiler/output/output_interpreter.dart"
    show interpretStatements;
import "output_emitter_util.dart"
    show codegenStmts, ExternalClass, DynamicClassInstanceFactory;
import "package:angular2/src/facade/async.dart" show EventEmitter;
import "package:angular2/src/core/linker/view_type.dart" show ViewType;
import "package:angular2/src/facade/exceptions.dart" show BaseException;
import "package:test/test.dart";

main() {
  var outputDefs = [];
  outputDefs.add({
    "getExpressions": () => interpretStatements(
        codegenStmts, "getExpressions", new DynamicClassInstanceFactory()),
    "name": "interpreted"
  });
  outputDefs
      .add({"getExpressions": () => typed.getExpressions, "name": "typed"});
  group("output emitter", () {
    outputDefs.forEach((outputDef) {
      group('''${ outputDef [ "name" ]}''', () {
        var expressions;
        setUp(() async {
          await inject([], () {});
          expressions = outputDef["getExpressions"]()();
        });
        test("should support literals", () {
          expect(expressions["stringLiteral"], "Hello World!");
          expect(expressions["intLiteral"], 42);
          expect(expressions["boolLiteral"], true);
          expect(expressions["arrayLiteral"], [0]);
          expect(expressions["mapLiteral"], {"key0": 0});
        });
        test("should support reading vars/keys/props", () {
          expect(expressions["readVar"], "someValue");
          expect(expressions["readKey"], "someValue");
          expect(expressions["readPropExternalInstance"], "someValue");
          expect(expressions["readPropDynamicInstance"], "dynamicValue");
          expect(expressions["readGetterDynamicInstance"],
              {"data": "someValue", "dynamicProp": "dynamicValue"});
        });
        test("should support writing to vars / keys / props", () {
          expect(expressions["changedVar"], "changedValue");
          expect(expressions["changedKey"], "changedValue");
          expect(expressions["changedPropExternalInstance"], "changedValue");
          expect(expressions["changedPropDynamicInstance"], "changedValue");
        });
        test("should support declaring functions with parameters and return",
            () {
          expect(expressions["fn"]("someParam"), {"param": "someParam"});
          expect(expressions["closureInDynamicInstance"]("someParam"), {
            "param": "someParam",
            "data": "someValue",
            "dynamicProp": "dynamicValue"
          });
        });
        test("should support invoking functions and methods", () {
          expect(expressions["invokeFn"], {"param": "someParam"});
          expect(expressions["concatedArray"], [0, 1]);
          expect(expressions["invokeMethodExternalInstance"],
              {"data": "someValue", "param": "someParam"});
          expect(expressions["invokeMethodExternalInstanceViaBind"],
              {"data": "someValue", "param": "someParam"});
          expect(expressions["invokeMethodDynamicInstance"], {
            "data": "someValue",
            "dynamicProp": "dynamicValue",
            "param": "someParam"
          });
          expect(expressions["invokeMethodDynamicInstanceViaBind"], {
            "data": "someValue",
            "dynamicProp": "dynamicValue",
            "param": "someParam"
          });
        });
        test("should support conditionals", () {
          expect(expressions["conditionalTrue"], "true");
          expect(expressions["conditionalFalse"], "false");
        });
        test("should support not", () {
          expect(expressions["not"], true);
        });
        test("should support reading external identifiers", () {
          expect(expressions["externalTestIdentifier"], ExternalClass);
          expect(expressions["externalSrcIdentifier"], EventEmitter);
          expect(expressions["externalEnumIdentifier"], ViewType.HOST);
        });
        test("should support instantiating classes", () {
          expect(expressions["externalInstance"] is ExternalClass, isTrue);
          expect(expressions["dynamicInstance"] is ExternalClass, isTrue);
        });
        test("should support reading metadataMap", () {
          if (outputDef["name"] == "typed") {
            expect(expressions["metadataMap"], ["someKey", "someValue"]);
          } else {
            expect(expressions["metadataMap"], isNull);
          }
        });
        group("operators", () {
          var ops;
          var aObj, bObj;
          setUp(() {
            ops = expressions["operators"];
            aObj = new Object();
            bObj = new Object();
          });
          test("should support ==", () {
            expect(ops["=="](aObj, aObj), isTrue);
            expect(ops["=="](aObj, bObj), isFalse);
            expect(ops["=="](1, 1), isTrue);
            expect(ops["=="](0, 1), isFalse);
            expect(ops["=="]("a", "a"), isTrue);
            expect(ops["=="]("a", "b"), isFalse);
          });
          test("should support !=", () {
            expect(ops["!="](aObj, aObj), isFalse);
            expect(ops["!="](aObj, bObj), isTrue);
            expect(ops["!="](1, 1), isFalse);
            expect(ops["!="](0, 1), isTrue);
            expect(ops["!="]("a", "a"), isFalse);
            expect(ops["!="]("a", "b"), isTrue);
          });
          test("should support ===", () {
            expect(ops["==="](aObj, aObj), isTrue);
            expect(ops["==="](aObj, bObj), isFalse);
            expect(ops["==="](1, 1), isTrue);
            expect(ops["==="](0, 1), isFalse);
          });
          test("should support !==", () {
            expect(ops["!=="](aObj, aObj), isFalse);
            expect(ops["!=="](aObj, bObj), isTrue);
            expect(ops["!=="](1, 1), isFalse);
            expect(ops["!=="](0, 1), isTrue);
          });
          test("should support -", () {
            expect(ops["-"](3, 2), 1);
          });
          test("should support +", () {
            expect(ops["+"](1, 2), 3);
          });
          test("should support /", () {
            expect(ops["/"](6, 2), 3);
          });
          test("should support *", () {
            expect(ops["*"](2, 3), 6);
          });
          test("should support %", () {
            expect(ops["%"](3, 2), 1);
          });
          test("should support &&", () {
            expect(ops["&&"](true, true), isTrue);
            expect(ops["&&"](true, false), isFalse);
          });
          test("should support ||", () {
            expect(ops["||"](true, false), isTrue);
            expect(ops["||"](false, false), isFalse);
          });
          test("should support <", () {
            expect(ops["<"](1, 2), isTrue);
            expect(ops["<"](1, 1), isFalse);
          });
          test("should support <=", () {
            expect(ops["<="](1, 2), isTrue);
            expect(ops["<="](1, 1), isTrue);
          });
          test("should support >", () {
            expect(ops[">"](2, 1), isTrue);
            expect(ops[">"](1, 1), isFalse);
          });
          test("should support >=", () {
            expect(ops[">="](2, 1), isTrue);
            expect(ops[">="](1, 1), isTrue);
          });
        });
        test("should support throwing errors", () {
          expect(expressions["throwError"], throwsWith("someError"));
        });
        test("should support catching errors", () {
          someOperation() {
            throw new BaseException("Boom!");
          }
          var errorAndStack = expressions["catchError"](someOperation);
          expect(errorAndStack[0].message, "Boom!");
          // Somehow we don't get stacktraces on ios7...
          if (!browserDetection.isIOS7 && !browserDetection.isIE) {
            expect(errorAndStack[1].toString(), contains("someOperation"));
          }
        });
      });
    });
  });
}
