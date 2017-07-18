@TestOn('browser && !js')
library angular2.test.core.reflection.reflector_test;

import 'package:test/test.dart';
import "package:angular/core.dart" show OnInit;
import "package:angular/src/core/reflection/reflection.dart"
    show Reflector, ReflectionInfo;
import "package:angular/src/core/reflection/reflection_capabilities.dart"
    show ReflectionCapabilities;

import "reflector_common.dart"
    show ClassDecorator, ParamDecorator, PropDecorator;

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
    group("factory", () {
      test("should create a factory for the given type", () {
        var obj = reflector.factory(TestObj)(1, 2);
        expect(obj.a, 1);
        expect(obj.b, 2);
      });
      test("should throw when more than 20 arguments", () {
        expect(() => reflector.factory(TestObjWith21Args),
            throwsA(contains("Cannot create a factory for")));
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
