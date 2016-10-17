@TestOn('browser && !js')
library angular2.test.core.reflection.reflector_test;

import "package:angular2/core.dart" show OnInit;
import "package:angular2/src/core/reflection/reflection.dart"
    show Reflector, ReflectionInfo;
import "package:angular2/src/core/reflection/reflection_capabilities.dart"
    show ReflectionCapabilities;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

import "reflector_common.dart"
    show
        ClassDecorator,
        ParamDecorator,
        PropDecorator,
        HasGetterAndSetterDecorators;

class AType {
  var value;
  AType(value) {
    this.value = value;
  }
}

@ClassDecorator("class")
class ClassWithDecorators {
  @PropDecorator("p1")
  @PropDecorator("p2")
  var a;
  var b;
  @PropDecorator("p3")
  set c(value) {}
  ClassWithDecorators(
      @ParamDecorator("a") AType a, @ParamDecorator("b") AType b) {
    this.a = a;
    this.b = b;
  }
}

class ClassWithoutDecorators {
  ClassWithoutDecorators(a, b);
}

class TestObj {
  var a;
  var b;
  TestObj(a, b) {
    this.a = a;
    this.b = b;
  }
  dynamic identity(arg) {
    return arg;
  }
}

class Interface {}

class Interface2 {}

class SuperClassImplementingInterface implements Interface2 {}

class ClassImplementingInterface extends SuperClassImplementingInterface
    implements Interface {}
// Classes used to test our runtime check for classes that implement lifecycle interfaces but do not

// declare them.

// See https://github.com/angular/angular/pull/6879 and https://goo.gl/b07Kii for details.
class ClassDoesNotDeclareOnInit {
  ngOnInit() {}
}

class SuperClassImplementingOnInit implements OnInit {
  ngOnInit() {}
}

class SubClassDoesNotDeclareOnInit extends SuperClassImplementingOnInit {}

void main() {
  group("Reflector", () {
    var reflector;
    setUp(() {
      reflector = new Reflector(new ReflectionCapabilities());
    });
    group("usage tracking", () {
      setUp(() {
        reflector = new Reflector(null);
      });
      test("should be disabled by default", () {
        expect(() => reflector.listUnusedKeys(),
            throwsWith("Usage tracking is disabled"));
      });
      test("should report unused keys", () {
        reflector.trackUsage();
        expect(reflector.listUnusedKeys(), []);
        reflector.registerType(
            AType, new ReflectionInfo(null, null, () => "AType"));
        reflector.registerType(
            TestObj, new ReflectionInfo(null, null, () => "TestObj"));
        expect(reflector.listUnusedKeys(), [AType, TestObj]);
        reflector.factory(AType);
        expect(reflector.listUnusedKeys(), [TestObj]);
        reflector.factory(TestObj);
        expect(reflector.listUnusedKeys(), []);
      });
    });
    group("factory", () {
      test("should create a factory for the given type", () {
        var obj = reflector.factory(TestObj)(1, 2);
        expect(obj.a, 1);
        expect(obj.b, 2);
      });
      test("should throw when more than 20 arguments", () {
        expect(() => reflector.factory(TestObjWith21Args), throws);
      });
      test("should return a registered factory if available", () {
        reflector.registerType(
            TestObj, new ReflectionInfo(null, null, () => "fake"));
        expect(reflector.factory(TestObj)(), "fake");
      });
    });
    group("parameters", () {
      test("should return an array of parameters for a type", () {
        var p = reflector.parameters(ClassWithDecorators);
        expect(p[0][0], AType);
        expect(p[0][1].value, "a");
        expect(p[1][0], AType);
        expect(p[1][1].value, "b");
      });
      test("should work for a class without annotations", () {
        var p = reflector.parameters(ClassWithoutDecorators);
        expect(p.length, 2);
      });
      test("should return registered parameters if available", () {
        reflector.registerType(
            TestObj,
            new ReflectionInfo(null, [
              [1],
              [2]
            ]));
        expect(reflector.parameters(TestObj), [
          [1],
          [2]
        ]);
      });
      test(
          "should return an empty list when no parameters field in the stored type info",
          () {
        reflector.registerType(TestObj, new ReflectionInfo());
        expect(reflector.parameters(TestObj), []);
      });
    });
    group("propMetadata", () {
      test("should return a string map of prop metadata for the given class",
          () {
        var p = reflector.propMetadata(ClassWithDecorators);
        expect(p["a"][0].value, "p1");
        expect(p["a"][1].value, "p2");
        expect(p["c"][0].value, "p3");
      });
      test("should return registered meta if available", () {
        reflector.registerType(
            TestObj,
            new ReflectionInfo(null, null, null, null, {
              "a": [1, 2]
            }));
        expect(reflector.propMetadata(TestObj), {
          "a": [1, 2]
        });
      });
      test("should merge metadata from getters and setters", () {
        var p = reflector.propMetadata(HasGetterAndSetterDecorators);
        expect(p["a"].map((PropDecorator p) => p.value), ["get", "set"]);
      });
    });
    group("annotations", () {
      test("should return an array of annotations for a type", () {
        var p = reflector.annotations(ClassWithDecorators);
        ClassDecorator dec = p[0];
        expect(dec.value, "class");
      });
      test("should return registered annotations if available", () {
        reflector.registerType(TestObj, new ReflectionInfo([1, 2]));
        expect(reflector.annotations(TestObj), [1, 2]);
      });
      test("should work for a class without annotations", () {
        var p = reflector.annotations(ClassWithoutDecorators);
        expect(p, []);
      });
    });
    group("interfaces", () {
      test("should return an array of interfaces for a type", () {
        var p = reflector.interfaces(ClassImplementingInterface);
        expect(p, [Interface, Interface2]);
      });
      test("should return an empty array otherwise", () {
        var p = reflector.interfaces(ClassWithDecorators);
        expect(p, []);
      });
      test("should throw for undeclared lifecycle interfaces", () {
        expect(() => reflector.interfaces(ClassDoesNotDeclareOnInit), throws);
      });
      test(
          "should throw for class inheriting a lifecycle impl and not declaring the interface",
          () {
        expect(
            () => reflector.interfaces(SubClassDoesNotDeclareOnInit), throws);
      });
    });

    group("getter", () {
      test("returns a function reading a property", () {
        var getA = reflector.getter("a");
        expect(getA(new TestObj(1, 2)), 1);
      });
      test("should return a registered getter if available", () {
        reflector.registerGetters({"abc": (obj) => "fake"});
        expect(reflector.getter("abc")("anything"), "fake");
      });
    });
    group("setter", () {
      test("returns a function setting a property", () {
        var setA = reflector.setter("a");
        var obj = new TestObj(1, 2);
        setA(obj, 100);
        expect(obj.a, 100);
      });
      test("should return a registered setter if available", () {
        var updateMe;
        reflector.registerSetters({
          "abc": (obj, value) {
            updateMe = value;
          }
        });
        reflector.setter("abc")("anything", "fake");
        expect(updateMe, "fake");
      });
    });
    group("method", () {
      test("returns a function invoking a method", () {
        var func = reflector.method("identity");
        var obj = new TestObj(1, 2);
        expect(func(obj, ["value"]), "value");
      });
      test("should return a registered method if available", () {
        reflector.registerMethods({"abc": (obj, args) => args});
        expect(reflector.method("abc")("anything", ["fake"]), ["fake"]);
      });
    });
    group("importUri", () {
      test("should return the importUri for a type", () {
        expect(
            reflector
                .importUri(TestObjWith00Args)
                .endsWith("test/core/reflection/reflector_test.dart"),
            isTrue);
      });
    });
  });
}

class TestObjWith00Args {
  List<dynamic> args;
  TestObjWith00Args() {
    this.args = [];
  }
}

class TestObjWith01Args {
  List<dynamic> args;
  TestObjWith01Args(dynamic a1) {
    this.args = [a1];
  }
}

class TestObjWith02Args {
  List<dynamic> args;
  TestObjWith02Args(dynamic a1, dynamic a2) {
    this.args = [a1, a2];
  }
}

class TestObjWith03Args {
  List<dynamic> args;
  TestObjWith03Args(dynamic a1, dynamic a2, dynamic a3) {
    this.args = [a1, a2, a3];
  }
}

class TestObjWith04Args {
  List<dynamic> args;
  TestObjWith04Args(dynamic a1, dynamic a2, dynamic a3, dynamic a4) {
    this.args = [a1, a2, a3, a4];
  }
}

class TestObjWith05Args {
  List<dynamic> args;
  TestObjWith05Args(
      dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5) {
    this.args = [a1, a2, a3, a4, a5];
  }
}

class TestObjWith06Args {
  List<dynamic> args;
  TestObjWith06Args(
      dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5, dynamic a6) {
    this.args = [a1, a2, a3, a4, a5, a6];
  }
}

class TestObjWith07Args {
  List<dynamic> args;
  TestObjWith07Args(dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5,
      dynamic a6, dynamic a7) {
    this.args = [a1, a2, a3, a4, a5, a6, a7];
  }
}

class TestObjWith08Args {
  List<dynamic> args;
  TestObjWith08Args(dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5,
      dynamic a6, dynamic a7, dynamic a8) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8];
  }
}

class TestObjWith09Args {
  List<dynamic> args;
  TestObjWith09Args(dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5,
      dynamic a6, dynamic a7, dynamic a8, dynamic a9) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9];
  }
}

class TestObjWith10Args {
  List<dynamic> args;
  TestObjWith10Args(dynamic a1, dynamic a2, dynamic a3, dynamic a4, dynamic a5,
      dynamic a6, dynamic a7, dynamic a8, dynamic a9, dynamic a10) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10];
  }
}

class TestObjWith11Args {
  List<dynamic> args;
  TestObjWith11Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11];
  }
}

class TestObjWith12Args {
  List<dynamic> args;
  TestObjWith12Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12];
  }
}

class TestObjWith13Args {
  List<dynamic> args;
  TestObjWith13Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13];
  }
}

class TestObjWith14Args {
  List<dynamic> args;
  TestObjWith14Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14) {
    this.args = [a1, a2, a3, a4, a5, a6, a7, a8, a9, a10, a11, a12, a13, a14];
  }
}

class TestObjWith15Args {
  List<dynamic> args;
  TestObjWith15Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15
    ];
  }
}

class TestObjWith16Args {
  List<dynamic> args;
  TestObjWith16Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16
    ];
  }
}

class TestObjWith17Args {
  List<dynamic> args;
  TestObjWith17Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16,
      dynamic a17) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17
    ];
  }
}

class TestObjWith18Args {
  List<dynamic> args;
  TestObjWith18Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16,
      dynamic a17,
      dynamic a18) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18
    ];
  }
}

class TestObjWith19Args {
  List<dynamic> args;
  TestObjWith19Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16,
      dynamic a17,
      dynamic a18,
      dynamic a19) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18,
      a19
    ];
  }
}

class TestObjWith20Args {
  List<dynamic> args;
  TestObjWith20Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16,
      dynamic a17,
      dynamic a18,
      dynamic a19,
      dynamic a20) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18,
      a19,
      a20
    ];
  }
}

class TestObjWith21Args {
  List<dynamic> args;
  TestObjWith21Args(
      dynamic a1,
      dynamic a2,
      dynamic a3,
      dynamic a4,
      dynamic a5,
      dynamic a6,
      dynamic a7,
      dynamic a8,
      dynamic a9,
      dynamic a10,
      dynamic a11,
      dynamic a12,
      dynamic a13,
      dynamic a14,
      dynamic a15,
      dynamic a16,
      dynamic a17,
      dynamic a18,
      dynamic a19,
      dynamic a20,
      dynamic a21) {
    this.args = [
      a1,
      a2,
      a3,
      a4,
      a5,
      a6,
      a7,
      a8,
      a9,
      a10,
      a11,
      a12,
      a13,
      a14,
      a15,
      a16,
      a17,
      a18,
      a19,
      a20,
      a21
    ];
  }
}
