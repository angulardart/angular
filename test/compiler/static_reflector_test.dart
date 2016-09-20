library angular2.test.compiler.static_reflector_test;

import "package:angular2/src/compiler/static_reflector.dart"
    show StaticReflector, StaticReflectorHost;
import 'package:test/test.dart';

void main() {
  group("StaticRefelector", () {
    test("should get annotations for NgFor", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var NgFor = reflector.getStaticType(
          "angular2/src/common/directives/ng_for", "NgFor");
      var annotations = reflector.annotations(NgFor);
      expect(annotations.length, 1);
      var annotation = annotations[0];
      expect(annotation.selector, "[ngFor][ngForOf]");
      expect(annotation.inputs, ["ngForTrackBy", "ngForOf", "ngForTemplate"]);
    });
    test("should get constructor for NgFor", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var NgFor = reflector.getStaticType(
          "angular2/src/common/directives/ng_for", "NgFor");
      var ViewContainerRef = reflector.getStaticType(
          "angular2/src/core/linker/view_container_ref", "ViewContainerRef");
      var TemplateRef = reflector.getStaticType(
          "angular2/src/core/linker/template_ref", "TemplateRef");
      var IterableDiffers = reflector.getStaticType(
          "angular2/src/core/change_detection/differs/iterable_differs",
          "IterableDiffers");
      var ChangeDetectorRef = reflector.getStaticType(
          "angular2/src/core/change_detection/change_detector_ref",
          "ChangeDetectorRef");
      var parameters = reflector.parameters(NgFor);
      expect(parameters,
          [ViewContainerRef, TemplateRef, IterableDiffers, ChangeDetectorRef]);
    });
    test("should get annotations for HeroDetailComponent", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var HeroDetailComponent = reflector.getStaticType(
          "./app/hero-detail.component", "HeroDetailComponent");
      var annotations = reflector.annotations(HeroDetailComponent);
      expect(annotations.length, 1);
      var annotation = annotations[0];
      expect(annotation.selector, "my-hero-detail");
    });
    test("should get and empty annotation list for an unknown class", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var UnknownClass =
          reflector.getStaticType("./app/app.component", "UnknownClass");
      var annotations = reflector.annotations(UnknownClass);
      expect(annotations, []);
    });
    test("should get propMetadata for HeroDetailComponent", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var HeroDetailComponent = reflector.getStaticType(
          "./app/hero-detail.component", "HeroDetailComponent");
      var props = reflector.propMetadata(HeroDetailComponent);
      expect(props["hero"], isNotNull);
    });
    test("should get an empty object from propMetadata for an unknown class",
        () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var UnknownClass =
          reflector.getStaticType("./app/app.component", "UnknownClass");
      var properties = reflector.propMetadata(UnknownClass);
      expect(properties, {});
    });
    test("should get empty parameters list for an unknown class ", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var UnknownClass =
          reflector.getStaticType("./app/app.component", "UnknownClass");
      var parameters = reflector.parameters(UnknownClass);
      expect(parameters, []);
    });
    test("should simplify primitive into itself", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(reflector.simplify("", 1), 1);
      expect(reflector.simplify("", true), isTrue);
      expect(reflector.simplify("", "some value"), "some value");
    });
    test("should simplify an array into a copy of the array", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(reflector.simplify("", [1, 2, 3]), [1, 2, 3]);
    });
    test("should simplify an object to a copy of the object", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var expr = {"a": 1, "b": 2, "c": 3};
      expect(reflector.simplify("", expr), expr);
    });
    test("should simplify &&", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&&",
                "left": true,
                "right": true
              })),
          isTrue);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&&",
                "left": true,
                "right": false
              })),
          isFalse);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&&",
                "left": false,
                "right": true
              })),
          isFalse);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&&",
                "left": false,
                "right": false
              })),
          isFalse);
    });
    test("should simplify ||", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "||",
                "left": true,
                "right": true
              })),
          isTrue);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "||",
                "left": true,
                "right": false
              })),
          isTrue);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "||",
                "left": false,
                "right": true
              })),
          isTrue);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "||",
                "left": false,
                "right": false
              })),
          isFalse);
    });
    test("should simplify &", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&",
                "left": 0x22,
                "right": 0x0F
              })),
          0x22 & 0x0F);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "&",
                "left": 0x22,
                "right": 0xF0
              })),
          0x22 & 0xF0);
    });
    test("should simplify |", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "|",
                "left": 0x22,
                "right": 0x0F
              })),
          0x22 | 0x0F);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "|",
                "left": 0x22,
                "right": 0xF0
              })),
          0x22 | 0xF0);
    });
    test("should simplify ^", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "|",
                "left": 0x22,
                "right": 0x0F
              })),
          0x22 | 0x0F);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "|",
                "left": 0x22,
                "right": 0xF0
              })),
          0x22 | 0xF0);
    });
    test("should simplify ==", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "==",
                "left": 0x22,
                "right": 0x22
              })),
          0x22 == 0x22);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "==",
                "left": 0x22,
                "right": 0xF0
              })),
          0x22 == 0xF0);
    });
    test("should simplify !=", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "!=",
                "left": 0x22,
                "right": 0x22
              })),
          0x22 != 0x22);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "!=",
                "left": 0x22,
                "right": 0xF0
              })),
          0x22 != 0xF0);
    });
    test("should simplify ===", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "===",
                "left": 0x22,
                "right": 0x22
              })),
          identical(0x22, 0x22));
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "===",
                "left": 0x22,
                "right": 0xF0
              })),
          identical(0x22, 0xF0));
    });
    test("should simplify !==", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "!==",
                "left": 0x22,
                "right": 0x22
              })),
          !identical(0x22, 0x22));
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "!==",
                "left": 0x22,
                "right": 0xF0
              })),
          !identical(0x22, 0xF0));
    });
    test("should simplify >", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">",
                "left": 1,
                "right": 1
              })),
          1 > 1);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">",
                "left": 1,
                "right": 0
              })),
          1 > 0);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">",
                "left": 0,
                "right": 1
              })),
          0 > 1);
    });
    test("should simplify >=", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">=",
                "left": 1,
                "right": 1
              })),
          1 >= 1);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">=",
                "left": 1,
                "right": 0
              })),
          1 >= 0);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">=",
                "left": 0,
                "right": 1
              })),
          0 >= 1);
    });
    test("should simplify <=", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<=",
                "left": 1,
                "right": 1
              })),
          1 <= 1);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<=",
                "left": 1,
                "right": 0
              })),
          1 <= 0);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<=",
                "left": 0,
                "right": 1
              })),
          0 <= 1);
    });
    test("should simplify <", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<",
                "left": 1,
                "right": 1
              })),
          1 < 1);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<",
                "left": 1,
                "right": 0
              })),
          1 < 0);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<",
                "left": 0,
                "right": 1
              })),
          0 < 1);
    });
    test("should simplify <<", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "<<",
                "left": 0x55,
                "right": 2
              })),
          0x55 << 2);
    });
    test("should simplify >>", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": ">>",
                "left": 0x55,
                "right": 2
              })),
          0x55 >> 2);
    });
    test("should simplify +", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "+",
                "left": 0x55,
                "right": 2
              })),
          0x55 + 2);
    });
    test("should simplify -", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "-",
                "left": 0x55,
                "right": 2
              })),
          0x55 - 2);
    });
    test("should simplify *", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "*",
                "left": 0x55,
                "right": 2
              })),
          0x55 * 2);
    });
    test("should simplify /", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "/",
                "left": 0x55,
                "right": 2
              })),
          0x55 / 2);
    });
    test("should simplify %", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "binop",
                "operator": "%",
                "left": 0x55,
                "right": 2
              })),
          0x55 % 2);
    });
    test("should simplify prefix -", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "", ({"___symbolic": "pre", "operator": "-", "operand": 2})),
          -2);
    });
    test("should simplify prefix ~", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "", ({"___symbolic": "pre", "operator": "~", "operand": 2})),
          ~2);
    });
    test("should simplify prefix !", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "", ({"___symbolic": "pre", "operator": "!", "operand": true})),
          !true);
      expect(
          reflector.simplify(
              "", ({"___symbolic": "pre", "operator": "!", "operand": false})),
          !false);
    });
    test("should simpify an array index", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "",
              ({
                "___symbolic": "index",
                "expression": [1, 2, 3],
                "index": 2
              })),
          3);
    });
    test("should simplify an object index", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      var expr = {
        "___symbolic": "select",
        "expression": {"a": 1, "b": 2, "c": 3},
        "member": "b"
      };
      expect(reflector.simplify("", expr), 2);
    });
    test("should simplify a module reference", () {
      var host = new MockReflectorHost();
      var reflector = new StaticReflector(host);
      expect(
          reflector.simplify(
              "./cases",
              ({
                "___symbolic": "reference",
                "module": "./extern",
                "name": "s"
              })),
          "s");
    });
  });
}

class MockReflectorHost implements StaticReflectorHost {
  Map<String, dynamic> getMetadataFor(String moduleId) {
    return {
      "angular2/src/common/directives/ng_for": {
        "___symbolic": "module",
        "module": "./ng_for",
        "metadata": {
          "NgFor": {
            "___symbolic": "class",
            "decorators": [
              {
                "___symbolic": "call",
                "expression": {
                  "___symbolic": "reference",
                  "name": "Directive",
                  "module": "../../core/metadata"
                },
                "arguments": [
                  {
                    "selector": "[ngFor][ngForOf]",
                    "inputs": ["ngForTrackBy", "ngForOf", "ngForTemplate"]
                  }
                ]
              }
            ],
            "members": {
              "___ctor__": [
                {
                  "___symbolic": "constructor",
                  "parameters": [
                    {
                      "___symbolic": "reference",
                      "module": "../../core/linker/view_container_ref",
                      "name": "ViewContainerRef"
                    },
                    {
                      "___symbolic": "reference",
                      "module": "../../core/linker/template_ref",
                      "name": "TemplateRef"
                    },
                    {
                      "___symbolic": "reference",
                      "module":
                          "../../core/change_detection/differs/iterable_differs",
                      "name": "IterableDiffers"
                    },
                    {
                      "___symbolic": "reference",
                      "module":
                          "../../core/change_detection/change_detector_ref",
                      "name": "ChangeDetectorRef"
                    }
                  ]
                }
              ]
            }
          }
        }
      },
      "angular2/src/core/linker/view_container_ref": {
        "module": "./view_container_ref",
        "metadata": {
          "ViewContainerRef": {"___symbolic": "class"}
        }
      },
      "angular2/src/core/linker/template_ref": {
        "module": "./template_ref",
        "metadata": {
          "TemplateRef": {"___symbolic": "class"}
        }
      },
      "angular2/src/core/change_detection/differs/iterable_differs": {
        "module": "./iterable_differs",
        "metadata": {
          "IterableDiffers": {"___symbolic": "class"}
        }
      },
      "angular2/src/core/change_detection/change_detector_ref": {
        "module": "./change_detector_ref",
        "metadata": {
          "ChangeDetectorRef": {"___symbolic": "class"}
        }
      },
      "./app/hero-detail.component": {
        "___symbolic": "module",
        "module": "./hero-detail.component",
        "metadata": {
          "HeroDetailComponent": {
            "___symbolic": "class",
            "decorators": [
              {
                "___symbolic": "call",
                "expression": {
                  "___symbolic": "reference",
                  "name": "Component",
                  "module": "angular2/src/core/metadata"
                },
                "arguments": [
                  {
                    "selector": "my-hero-detail",
                    "template":
                        "\n  <div *ngIf=\"hero\">\n    <h2>{{hero.name}} details!</h2>\n    <div><label>id: </label>{{hero.id}}</div>\n    <div>\n      <label>name: </label>\n      <input [(ngModel)]=\"hero.name\" placeholder=\"name\"/>\n    </div>\n  </div>\n"
                  }
                ]
              }
            ],
            "members": {
              "hero": [
                {
                  "___symbolic": "property",
                  "decorators": [
                    {
                      "___symbolic": "call",
                      "expression": {
                        "___symbolic": "reference",
                        "name": "Input",
                        "module": "angular2/src/core/metadata"
                      }
                    }
                  ]
                }
              ]
            }
          }
        }
      },
      "./extern": {
        "___symbolic": "module",
        "module": "./extern",
        "metadata": {"s": "s"}
      }
    }[moduleId];
  }
}
