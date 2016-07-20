@TestOn('browser')
library angular2.test.compiler.template_parser_test;

import "package:angular2/src/compiler/compile_metadata.dart";
import "package:angular2/src/compiler/identifiers.dart"
    show identifierToken, Identifiers;
import "package:angular2/src/compiler/schema/element_schema_registry.dart"
    show ElementSchemaRegistry;
import "package:angular2/src/compiler/template_ast.dart";
import "package:angular2/src/compiler/template_parser.dart"
    show TemplateParser, splitClasses, TEMPLATE_TRANSFORMS;
import "package:angular2/src/core/console.dart" show Console;
import "package:angular2/src/core/di.dart" show provide;
import "package:angular2/testing_internal.dart";
import 'package:test/test.dart';

import "expression_parser/unparser.dart" show Unparser;
import "schema_registry_mock.dart" show MockSchemaRegistry;
import "test_bindings.dart" show TEST_PROVIDERS;

var expressionUnparser = new Unparser();
var someModuleUrl = "package:someModule";
var MOCK_SCHEMA_REGISTRY = [
  provide(ElementSchemaRegistry,
      useValue: new MockSchemaRegistry(
          {"invalidProp": false}, {"mappedAttr": "mappedProp"}))
];
main() {
  var ngIf;
  var parse;
  ArrayConsole console = new ArrayConsole();

  var commonSetup = () async {
    await inject([TemplateParser], (parser) {
      var component = CompileDirectiveMetadata.create(
          selector: "root",
          type: new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "Root"),
          isComponent: true);
      ngIf = CompileDirectiveMetadata.create(
          selector: "[ngIf]",
          type: new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "NgIf"),
          inputs: ["ngIf"]);
      parse = /* List < TemplateAst > */ (String template,
          List<CompileDirectiveMetadata> directives,
          [List<CompilePipeMetadata> pipes = null]) {
        if (identical(pipes, null)) {
          pipes = [];
        }
        return parser.parse(component, template, directives, pipes, "TestComp");
      };
    });
  };
  group("TemplateParser template transform", () {
    group("single", () {
      test("should transform TemplateAST", () async {
        beforeEachProviders(() => [
              TEST_PROVIDERS,
              MOCK_SCHEMA_REGISTRY,
              provide(TEMPLATE_TRANSFORMS,
                  useValue: new FooAstTransformer(), multi: true)
            ]);
        await commonSetup();
        expect(humanizeTplAst(parse("<div>", [])), [
          [ElementAst, "foo"]
        ]);
      });
    });

    group("multiple", () {
      test("should compose transformers", () async {
        beforeEachProviders(() => [
              TEST_PROVIDERS,
              MOCK_SCHEMA_REGISTRY,
              provide(TEMPLATE_TRANSFORMS,
                  useValue: new FooAstTransformer(), multi: true),
              provide(TEMPLATE_TRANSFORMS,
                  useValue: new BarAstTransformer(), multi: true)
            ]);
        await commonSetup();
        expect(humanizeTplAst(parse("<div>", [])), [
          [ElementAst, "bar"]
        ]);
      });
    });
  });
  group("TemplateParser", () {
    setUp(() async {
      beforeEachProviders(() => [
            TEST_PROVIDERS,
            MOCK_SCHEMA_REGISTRY,
            provide(Console, useValue: console)
          ]);
      await commonSetup();
    });
    tearDown(() {
      console.clear();
    });
    group("parse", () {
      group("nodes without bindings", () {
        test("should parse text nodes", () {
          expect(humanizeTplAst(parse("a", [])), [
            [TextAst, "a"]
          ]);
        });
        test("should parse elements with attributes", () {
          expect(humanizeTplAst(parse("<div a=b>", [])), [
            [ElementAst, "div"],
            [AttrAst, "a", "b"]
          ]);
        });
      });
      test("should parse ngContent", () {
        var parsed = parse("<ng-content select=\"a\">", []);
        expect(humanizeTplAst(parsed), [
          [NgContentAst]
        ]);
      });
      test("should parse ngContent regardless the namespace", () {
        var parsed = parse("<svg><ng-content></ng-content></svg>", []);
        expect(humanizeTplAst(parsed), [
          [ElementAst, "@svg:svg"],
          [NgContentAst]
        ]);
      });
      test("should parse bound text nodes", () {
        expect(humanizeTplAst(parse("{{a}}", [])), [
          [BoundTextAst, "{{ a }}"]
        ]);
      });
      group("bound properties", () {
        test("should parse mixed case bound properties", () {
          expect(humanizeTplAst(parse("<div [someProp]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "someProp",
              "v",
              null
            ]
          ]);
        });
        test("should parse dash case bound properties", () {
          expect(humanizeTplAst(parse("<div [some-prop]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "some-prop",
              "v",
              null
            ]
          ]);
        });
        test("should normalize property names via the element schema", () {
          expect(humanizeTplAst(parse("<div [mappedAttr]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "mappedProp",
              "v",
              null
            ]
          ]);
        });
        test("should parse mixed case bound attributes", () {
          expect(humanizeTplAst(parse("<div [attr.someAttr]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Attribute,
              "someAttr",
              "v",
              null
            ]
          ]);
        });
        test("should parse and dash case bound classes", () {
          expect(humanizeTplAst(parse("<div [class.some-class]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Class,
              "some-class",
              "v",
              null
            ]
          ]);
        });
        test("should parse mixed case bound classes", () {
          expect(humanizeTplAst(parse("<div [class.someClass]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Class,
              "someClass",
              "v",
              null
            ]
          ]);
        });
        test("should parse mixed case bound styles", () {
          expect(humanizeTplAst(parse("<div [style.someStyle]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Style,
              "someStyle",
              "v",
              null
            ]
          ]);
        });
        test("should report invalid prefixes", () {
          expect(
              () => parse("<p [atTr.foo]>", []),
              throwsWith('Template parse errors:\n'
                  'Invalid property name \'atTr.foo\' '
                  '("<p [ERROR ->][atTr.foo]>"): TestComp@0:3'));
          expect(
              () => parse("<p [sTyle.foo]>", []),
              throwsWith('Template parse errors:\n'
                  'Invalid property name \'sTyle.foo\' '
                  '("<p [ERROR ->][sTyle.foo]>"): TestComp@0:3'));
          expect(
              () => parse("<p [Class.foo]>", []),
              throwsWith('Template parse errors:\n'
                  'Invalid property name \'Class.foo\' '
                  '("<p [ERROR ->][Class.foo]>"): TestComp@0:3'));
          expect(
              () => parse("<p [bar.foo]>", []),
              throwsWith('Template parse errors:\n'
                  'Invalid property name \'bar.foo\' '
                  '("<p [ERROR ->][bar.foo]>"): TestComp@0:3'));
        });
        test(
            'should parse bound properties via [...] and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse("<div [prop]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "prop",
              "v",
              null
            ]
          ]);
        });
        test(
            'should parse bound properties via bind- and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse("<div bind-prop=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "prop",
              "v",
              null
            ]
          ]);
        });
        test(
            'should parse bound properties via {{...}} and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse("<div prop=\"{{v}}\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "prop",
              "{{ v }}",
              null
            ]
          ]);
        });
      });
      group("events", () {
        test("should parse bound events with a target", () {
          expect(humanizeTplAst(parse("<div (window:event)=\"v\">", [])), [
            [ElementAst, "div"],
            [BoundEventAst, "event", "window", "v"]
          ]);
        });
        test(
            'should parse bound events via (...) and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse("<div (event)=\"v\">", [])), [
            [ElementAst, "div"],
            [BoundEventAst, "event", null, "v"]
          ]);
        });
        test("should parse event names case sensitive", () {
          expect(humanizeTplAst(parse("<div (some-event)=\"v\">", [])), [
            [ElementAst, "div"],
            [BoundEventAst, "some-event", null, "v"]
          ]);
          expect(humanizeTplAst(parse("<div (someEvent)=\"v\">", [])), [
            [ElementAst, "div"],
            [BoundEventAst, "someEvent", null, "v"]
          ]);
        });
        test(
            'should parse bound events via on- and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse("<div on-event=\"v\">", [])), [
            [ElementAst, "div"],
            [BoundEventAst, "event", null, "v"]
          ]);
        });
        test(
            'should allow events on explicit embedded templates that are '
            'emitted by a directive', () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "template",
              outputs: ["e"],
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"));
          expect(
              humanizeTplAst(parse("<template (e)=\"f\"></template>", [dirA])),
              [
                [EmbeddedTemplateAst],
                [BoundEventAst, "e", null, "f"],
                [DirectiveAst, dirA]
              ]);
        });
      });
      group("bindon", () {
        test(
            'should parse bound events and properties via [(...)] and not '
            'report them as attributes', () {
          expect(humanizeTplAst(parse("<div [(prop)]=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "prop",
              "v",
              null
            ],
            [BoundEventAst, "propChange", null, "v = \$event"]
          ]);
        });
        test(
            'should parse bound events and properties via bindon- and not '
            'report them as attributes', () {
          expect(humanizeTplAst(parse("<div bindon-prop=\"v\">", [])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "prop",
              "v",
              null
            ],
            [BoundEventAst, "propChange", null, "v = \$event"]
          ]);
        });
      });
      group("directives", () {
        test(
            'should order directives by the directives array in the View '
            'and match them only once', () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"));
          var dirB = CompileDirectiveMetadata.create(
              selector: "[b]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirB"));
          var dirC = CompileDirectiveMetadata.create(
              selector: "[c]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirC"));
          expect(humanizeTplAst(parse("<div a c b a b>", [dirA, dirB, dirC])), [
            [ElementAst, "div"],
            [AttrAst, "a", ""],
            [AttrAst, "c", ""],
            [AttrAst, "b", ""],
            [AttrAst, "a", ""],
            [AttrAst, "b", ""],
            [DirectiveAst, dirA],
            [DirectiveAst, dirB],
            [DirectiveAst, dirC]
          ]);
        });
        test("should locate directives in property bindings", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a=b]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"));
          var dirB = CompileDirectiveMetadata.create(
              selector: "[b]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirB"));
          expect(humanizeTplAst(parse("<div [a]=\"b\">", [dirA, dirB])), [
            [ElementAst, "div"],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "a",
              "b",
              null
            ],
            [DirectiveAst, dirA]
          ]);
        });
        test("should locate directives in event bindings", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirB"));
          expect(humanizeTplAst(parse("<div (a)=\"b\">", [dirA])), [
            [ElementAst, "div"],
            [BoundEventAst, "a", null, "b"],
            [DirectiveAst, dirA]
          ]);
        });
        test("should parse directive host properties", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              host: {"[a]": "expr"});
          expect(humanizeTplAst(parse("<div></div>", [dirA])), [
            [ElementAst, "div"],
            [DirectiveAst, dirA],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              "a",
              "expr",
              null
            ]
          ]);
        });
        test("should parse directive host listeners", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              host: {"(a)": "expr"});
          expect(humanizeTplAst(parse("<div></div>", [dirA])), [
            [ElementAst, "div"],
            [DirectiveAst, dirA],
            [BoundEventAst, "a", null, "expr"]
          ]);
        });
        test("should parse directive properties", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              inputs: ["aProp"]);
          expect(
              humanizeTplAst(parse("<div [aProp]=\"expr\"></div>", [dirA])), [
            [ElementAst, "div"],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, "aProp", "expr"]
          ]);
        });
        test("should parse renamed directive properties", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              inputs: ["b:a"]);
          expect(humanizeTplAst(parse("<div [a]=\"expr\"></div>", [dirA])), [
            [ElementAst, "div"],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, "b", "expr"]
          ]);
        });
        test("should parse literal directive properties", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              inputs: ["a"]);
          expect(humanizeTplAst(parse("<div a=\"literal\"></div>", [dirA])), [
            [ElementAst, "div"],
            [AttrAst, "a", "literal"],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, "a", "\"literal\""]
          ]);
        });
        test("should favor explicit bound properties over literal properties",
            () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              inputs: ["a"]);
          expect(
              humanizeTplAst(parse(
                  "<div a=\"literal\" [a]=\"'literal2'\"></div>", [dirA])),
              [
                [ElementAst, "div"],
                [AttrAst, "a", "literal"],
                [DirectiveAst, dirA],
                [BoundDirectivePropertyAst, "a", "\"literal2\""]
              ]);
        });
        test("should support optional directive properties", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "div",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              inputs: ["a"]);
          expect(humanizeTplAst(parse("<div></div>", [dirA])), [
            [ElementAst, "div"],
            [DirectiveAst, dirA]
          ]);
        });
      });
      group("providers", () {
        var nextProviderId;
        CompileTokenMetadata createToken(String value) {
          var token;
          if (value.startsWith("type:")) {
            token = new CompileTokenMetadata(
                identifier: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: value.substring(5)));
          } else {
            token = new CompileTokenMetadata(value: value);
          }
          return token;
        }
        CompileDiDependencyMetadata createDep(String value) {
          var isOptional = false;
          if (value.startsWith("optional:")) {
            isOptional = true;
            value = value.substring(9);
          }
          var isSelf = false;
          if (value.startsWith("self:")) {
            isSelf = true;
            value = value.substring(5);
          }
          var isHost = false;
          if (value.startsWith("host:")) {
            isHost = true;
            value = value.substring(5);
          }
          return new CompileDiDependencyMetadata(
              token: createToken(value),
              isOptional: isOptional,
              isSelf: isSelf,
              isHost: isHost);
        }
        CompileProviderMetadata createProvider(String token,
            {bool multi: false, List<String> deps: const []}) {
          return new CompileProviderMetadata(
              token: createToken(token),
              multi: multi,
              useClass: new CompileTypeMetadata(
                  name: '''provider${ nextProviderId ++}'''),
              deps: deps.map(createDep).toList());
        }
        CompileDirectiveMetadata createDir(String selector,
            {List<CompileProviderMetadata> providers: null,
            List<CompileProviderMetadata> viewProviders: null,
            List<String> deps: const [],
            List<String> queries: const []}) {
          var isComponent = !selector.startsWith("[");
          return CompileDirectiveMetadata.create(
              selector: selector,
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl,
                  name: selector,
                  diDeps: deps.map(createDep).toList()),
              isComponent: isComponent,
              template: new CompileTemplateMetadata(ngContentSelectors: []),
              providers: providers,
              viewProviders: viewProviders,
              queries: queries
                  .map((value) =>
                      new CompileQueryMetadata(selectors: [createToken(value)]))
                  .toList());
        }
        setUp(() {
          nextProviderId = 0;
        });
        test("should provide a component", () {
          var comp = createDir("my-comp");
          ElementAst elAst = parse("<my-comp>", [comp])[0] as ElementAst;
          expect(elAst.providers, hasLength(1));
          expect(elAst.providers[0].providerType, ProviderAstType.Component);
          expect(elAst.providers[0].providers[0].useClass, comp.type);
        });
        test("should provide a directive", () {
          var dirA = createDir("[dirA]");
          ElementAst elAst = (parse("<div dirA>", [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(1));
          expect(elAst.providers[0].providerType, ProviderAstType.Directive);
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
        });
        test("should use the public providers of a directive", () {
          var provider = createProvider("service");
          var dirA = createDir("[dirA]", providers: [provider]);
          ElementAst elAst = (parse("<div dirA>", [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(
              elAst.providers[1].providerType, ProviderAstType.PublicService);
          expect(compareProviderList(elAst.providers[1].providers, [provider]),
              isTrue);
        });
        test("should use the private providers of a component", () {
          var provider = createProvider("service");
          var comp = createDir("my-comp", viewProviders: [provider]);
          ElementAst elAst = (parse("<my-comp>", [comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(
              elAst.providers[1].providerType, ProviderAstType.PrivateService);
          expect(compareProviderList(elAst.providers[1].providers, [provider]),
              isTrue);
        });
        test("should support multi providers", () {
          var provider0 = createProvider("service0", multi: true);
          var provider1 = createProvider("service1", multi: true);
          var provider2 = createProvider("service0", multi: true);
          var dirA = createDir("[dirA]", providers: [provider0, provider1]);
          var dirB = createDir("[dirB]", providers: [provider2]);
          ElementAst elAst =
              (parse("<div dirA dirB>", [dirA, dirB])[0] as ElementAst);
          expect(elAst.providers, hasLength(4));
          expect(
              compareProviderList(
                  elAst.providers[2].providers, [provider0, provider2]),
              isTrue);
          expect(compareProviderList(elAst.providers[3].providers, [provider1]),
              isTrue);
        });
        test("should overwrite non multi providers", () {
          var provider1 = createProvider("service0");
          var provider2 = createProvider("service1");
          var provider3 = createProvider("service0");
          var dirA = createDir("[dirA]", providers: [provider1, provider2]);
          var dirB = createDir("[dirB]", providers: [provider3]);
          ElementAst elAst =
              (parse("<div dirA dirB>", [dirA, dirB])[0] as ElementAst);
          expect(elAst.providers, hasLength(4));
          expect(compareProviderList(elAst.providers[2].providers, [provider3]),
              isTrue);
          expect(compareProviderList(elAst.providers[3].providers, [provider2]),
              isTrue);
        });
        test("should overwrite component providers by directive providers", () {
          var compProvider = createProvider("service0");
          var dirProvider = createProvider("service0");
          var comp = createDir("my-comp", providers: [compProvider]);
          var dirA = createDir("[dirA]", providers: [dirProvider]);
          ElementAst elAst =
              (parse("<my-comp dirA>", [dirA, comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(
              compareProviderList(elAst.providers[2].providers, [dirProvider]),
              isTrue);
        });
        test("should overwrite view providers by directive providers", () {
          var viewProvider = createProvider("service0");
          var dirProvider = createProvider("service0");
          var comp = createDir("my-comp", viewProviders: [viewProvider]);
          var dirA = createDir("[dirA]", providers: [dirProvider]);
          ElementAst elAst =
              (parse("<my-comp dirA>", [dirA, comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(
              compareProviderList(elAst.providers[2].providers, [dirProvider]),
              isTrue);
        });
        test("should overwrite directives by providers", () {
          var dirProvider = createProvider("type:my-comp");
          var comp = createDir("my-comp", providers: [dirProvider]);
          ElementAst elAst = (parse("<my-comp>", [comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(1));
          expect(
              compareProviderList(elAst.providers[0].providers, [dirProvider]),
              isTrue);
        });
        test("should throw if mixing multi and non multi providers", () {
          var provider0 = createProvider("service0");
          var provider1 = createProvider("service0", multi: true);
          var dirA = createDir("[dirA]", providers: [provider0]);
          var dirB = createDir("[dirB]", providers: [provider1]);
          expect(
              () => parse("<div dirA dirB>", [dirA, dirB]),
              throwsWith('Template parse errors:\n'
                  'Mixing multi and non multi provider is not possible for '
                  'token service0 ("[ERROR ->]<div dirA dirB>"): '
                  'TestComp@0:0'));
        });
        test("should sort providers by their DI order", () {
          var provider0 = createProvider("service0", deps: ["type:[dir2]"]);
          var provider1 = createProvider("service1");
          var dir2 = createDir("[dir2]", deps: ["service1"]);
          var comp = createDir("my-comp", providers: [provider0, provider1]);
          ElementAst elAst =
              parse("<my-comp dir2>", [comp, dir2])[0] as ElementAst;
          expect(elAst.providers, hasLength(4));
          expect(elAst.providers[0].providers[0].useClass, comp.type);
          expect(compareProviderList(elAst.providers[1].providers, [provider1]),
              isTrue);
          expect(elAst.providers[2].providers[0].useClass, dir2.type);
          expect(compareProviderList(elAst.providers[3].providers, [provider0]),
              isTrue);
        });
        test("should sort directives by their DI order", () {
          var dir0 = createDir("[dir0]", deps: ["type:my-comp"]);
          var dir1 = createDir("[dir1]", deps: ["type:[dir0]"]);
          var dir2 = createDir("[dir2]", deps: ["type:[dir1]"]);
          var comp = createDir("my-comp");
          ElementAst elAst =
              parse("<my-comp dir2 dir0 dir1>", [comp, dir2, dir0, dir1])[0]
              as ElementAst;
          expect(elAst.providers, hasLength(4));
          expect(elAst.directives[0].directive, comp);
          expect(elAst.directives[1].directive, dir0);
          expect(elAst.directives[2].directive, dir1);
          expect(elAst.directives[3].directive, dir2);
        });
        test("should mark directives and dependencies of directives as eager",
            () {
          var provider0 = createProvider("service0");
          var provider1 = createProvider("service1");
          var dirA = createDir("[dirA]",
              providers: [provider0, provider1], deps: ["service0"]);
          ElementAst elAst = parse("<div dirA>", [dirA])[0] as ElementAst;
          expect(elAst.providers, hasLength(3));
          expect(compareProviderList(elAst.providers[0].providers, [provider0]),
              isTrue);
          expect(elAst.providers[0].eager, isTrue);
          expect(elAst.providers[1].providers[0].useClass, dirA.type);
          expect(elAst.providers[1].eager, isTrue);
          expect(compareProviderList(elAst.providers[2].providers, [provider1]),
              isTrue);
          expect(elAst.providers[2].eager, isFalse);
        });
        test("should mark dependencies on parent elements as eager", () {
          var provider0 = createProvider("service0");
          var provider1 = createProvider("service1");
          var dirA = createDir("[dirA]", providers: [provider0, provider1]);
          var dirB = createDir("[dirB]", deps: ["service0"]);
          ElementAst elAst =
              (parse("<div dirA><div dirB></div></div>", [dirA, dirB])[0]
                  as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, isTrue);
          expect(compareProviderList(elAst.providers[1].providers, [provider0]),
              isTrue);
          expect(elAst.providers[1].eager, isTrue);
          expect(compareProviderList(elAst.providers[2].providers, [provider1]),
              isTrue);
          expect(elAst.providers[2].eager, isFalse);
        });
        test("should mark queried providers as eager", () {
          var provider0 = createProvider("service0");
          var provider1 = createProvider("service1");
          var dirA = createDir("[dirA]",
              providers: [provider0, provider1], queries: ["service0"]);
          ElementAst elAst =
              (parse("<div dirA></div>", [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, isTrue);
          expect(compareProviderList(elAst.providers[1].providers, [provider0]),
              isTrue);
          expect(elAst.providers[1].eager, isTrue);
          expect(compareProviderList(elAst.providers[2].providers, [provider1]),
              isTrue);
          expect(elAst.providers[2].eager, isFalse);
        });
        test("should not mark dependencies accross embedded views as eager",
            () {
          var provider0 = createProvider("service0");
          var dirA = createDir("[dirA]", providers: [provider0]);
          var dirB = createDir("[dirB]", deps: ["service0"]);
          ElementAst elAst =
              (parse("<div dirA><div *ngIf dirB></div></div>", [dirA, dirB])[0]
                  as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, isTrue);
          expect(compareProviderList(elAst.providers[1].providers, [provider0]),
              isTrue);
          expect(elAst.providers[1].eager, isFalse);
        });
        test("should report missing @Self() deps as errors", () {
          var dirA = createDir("[dirA]", deps: ["self:provider0"]);
          expect(
              () => parse("<div dirA></div>", [dirA]),
              throwsWith('No provider for provider0 (\"[ERROR ->]'
                  '<div dirA></div>\"): TestComp@0:0'));
        });
        test("should change missing @Self() that are optional to nulls", () {
          var dirA = createDir("[dirA]", deps: ["optional:self:provider0"]);
          ElementAst elAst =
              (parse("<div dirA></div>", [dirA])[0] as ElementAst);
          expect(elAst.providers[0].providers[0].deps[0].isValue, isTrue);
          expect(elAst.providers[0].providers[0].deps[0].value, isNull);
        });
        test("should report missing @Host() deps as errors", () {
          var dirA = createDir("[dirA]", deps: ["host:provider0"]);
          expect(
              () => parse("<div dirA></div>", [dirA]),
              throwsWith('No provider for provider0 (\"[ERROR ->]'
                  '<div dirA></div>\"): TestComp@0:0'));
        });
        test("should change missing @Host() that are optional to nulls", () {
          var dirA = createDir("[dirA]", deps: ["optional:host:provider0"]);
          ElementAst elAst =
              (parse("<div dirA></div>", [dirA])[0] as ElementAst);
          expect(elAst.providers[0].providers[0].deps[0].isValue, isTrue);
          expect(elAst.providers[0].providers[0].deps[0].value, isNull);
        });
      });
      group("references", () {
        test(
            'should parse references via #... and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse("<div #a>", [])), [
            [ElementAst, "div"],
            [ReferenceAst, "a", null]
          ]);
        });
        test(
            'should parse references via ref-... and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse("<div ref-a>", [])), [
            [ElementAst, "div"],
            [ReferenceAst, "a", null]
          ]);
        });
        test(
            "should parse references via var-... and report them as deprecated",
            () {
          expect(humanizeTplAst(parse("<div var-a>", [])), [
            [ElementAst, "div"],
            [ReferenceAst, "a", null]
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:',
              '"var-" on non <template> elements is deprecated. Use "ref-" '
                  'instead! (\"<div [ERROR ->]var-a>\"): TestComp@0:5'
            ].join("\n")
          ]);
        });
        test("should parse camel case references", () {
          expect(humanizeTplAst(parse("<div ref-someA>", [])), [
            [ElementAst, "div"],
            [ReferenceAst, "someA", null]
          ]);
        });
        test("should assign references with empty value to the element", () {
          expect(humanizeTplAst(parse("<div #a></div>", [])), [
            [ElementAst, "div"],
            [ReferenceAst, "a", null]
          ]);
        });
        test("should assign references to directives via exportAs", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              exportAs: "dirA");
          expect(
              humanizeTplAst(parse("<div a #a=\"dirA\"></div>", [dirA]))
                  .toString(),
              [
                [ElementAst, "div"],
                [AttrAst, "a", ""],
                [ReferenceAst, "a", identifierToken(dirA.type)],
                [DirectiveAst, dirA]
              ].toString());
        });
        test(
            'should report references with values that dont match a '
            'directive as errors', () {
          expect(
              () => parse("<div #a=\"dirA\"></div>", []),
              throwsWith('Template parse errors:\n'
                  'There is no directive with "exportAs" set to "dirA" '
                  '("<div [ERROR ->]#a="dirA"></div>"): TestComp@0:5'));
        });
        test("should report invalid reference names", () {
          expect(
              () => parse("<div #a-b></div>", []),
              throwsWith('Template parse errors:\n'
                  '"-" is not allowed in reference names '
                  '("<div [ERROR ->]#a-b></div>"): TestComp@0:5'));
        });
        test("should report variables as errors", () {
          expect(
              () => parse("<div let-a></div>", []),
              throwsWith('Template parse errors:\n'
                  '"let-" is only supported on template elements. '
                  '("<div [ERROR ->]let-a></div>"): TestComp@0:5'));
        });
        test("should assign references with empty value to components", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              isComponent: true,
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"),
              exportAs: "dirA",
              template: new CompileTemplateMetadata(ngContentSelectors: []));
          expect(
              humanizeTplAst(parse("<div a #a></div>", [dirA])).toString(),
              [
                [ElementAst, "div"],
                [AttrAst, "a", ""],
                [ReferenceAst, "a", identifierToken(dirA.type)],
                [DirectiveAst, dirA]
              ].toString());
        });
        test("should not locate directives in references", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"));
          expect(
              humanizeTplAst(parse("<div ref-a>", [dirA])).toString(),
              [
                [ElementAst, "div"],
                [ReferenceAst, "a", null]
              ].toString());
        });
      });
      group("explicit templates", () {
        test("should create embedded templates for <template> elements", () {
          expect(humanizeTplAst(parse("<template></template>", [])), [
            [EmbeddedTemplateAst]
          ]);
          expect(humanizeTplAst(parse("<TEMPLATE></TEMPLATE>", [])), [
            [EmbeddedTemplateAst]
          ]);
        });
        test(
            'should create embedded templates for <template> elements '
            'regardless the namespace', () {
          expect(
              humanizeTplAst(parse("<svg><template></template></svg>", [])), [
            [ElementAst, "@svg:svg"],
            [EmbeddedTemplateAst]
          ]);
        });
        test("should support references via #...", () {
          expect(
              humanizeTplAst(parse("<template #a>", [])).toString(),
              [
                [EmbeddedTemplateAst],
                [ReferenceAst, "a", identifierToken(Identifiers.TemplateRef)]
              ].toString());
        });
        test("should support references via ref-...", () {
          expect(
              humanizeTplAst(parse("<template ref-a>", [])).toString(),
              [
                [EmbeddedTemplateAst],
                [ReferenceAst, "a", identifierToken(Identifiers.TemplateRef)]
              ].toString());
        });
        test("should parse variables via let-...", () {
          expect(humanizeTplAst(parse("<template let-a=\"b\">", [])), [
            [EmbeddedTemplateAst],
            [VariableAst, "a", "b"]
          ]);
        });
        test("should parse variables via var-... and report them as deprecated",
            () {
          expect(humanizeTplAst(parse("<template var-a=\"b\">", [])), [
            [EmbeddedTemplateAst],
            [VariableAst, "a", "b"]
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:',
              '"var-" on <template> elements is deprecated. Use "let-" '
                  'instead! ("<template [ERROR ->]var-a="b">"): TestComp@0:10'
            ].join("\n")
          ]);
        });
        test("should not locate directives in variables", () {
          var dirA = CompileDirectiveMetadata.create(
              selector: "[a]",
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: "DirA"));
          expect(
              humanizeTplAst(
                  parse("<template let-a=\"b\"></template>", [dirA])),
              [
                [EmbeddedTemplateAst],
                [VariableAst, "a", "b"]
              ]);
        });
      });
      group("inline templates", () {
        test("should wrap the element into an EmbeddedTemplateAST", () {
          expect(humanizeTplAst(parse("<div template>", [])), [
            [EmbeddedTemplateAst],
            [ElementAst, "div"]
          ]);
        });
        test("should parse bound properties", () {
          expect(
              humanizeTplAst(parse("<div template=\"ngIf test\">", [ngIf]))
                  .toString(),
              [
                [EmbeddedTemplateAst],
                [DirectiveAst, ngIf],
                [BoundDirectivePropertyAst, "ngIf", "test"],
                [ElementAst, "div"]
              ].toString());
        });
        test("should parse variables via #... and report them as deprecated",
            () {
          expect(
              humanizeTplAst(parse("<div *ngIf=\"#a=b\">", [])).toString(),
              [
                [EmbeddedTemplateAst],
                [VariableAst, "a", "b"],
                [ElementAst, "div"]
              ].toString());
          expect(console.warnings, [
            [
              'Template parse warnings:',
              '"#" inside of expressions is deprecated. Use "let" '
                  'instead! ("<div [ERROR ->]*ngIf="#a=b">"): TestComp@0:5'
            ].join("\n")
          ]);
        });
        test("should parse variables via var ... and report them as deprecated",
            () {
          expect(
              humanizeTplAst(parse("<div *ngIf=\"var a=b\">", [])).toString(),
              [
                [EmbeddedTemplateAst],
                [VariableAst, "a", "b"],
                [ElementAst, "div"]
              ].toString());
          expect(console.warnings, [
            [
              'Template parse warnings:',
              '"var" inside of expressions is deprecated. Use "let" instead!'
                  ' ("<div [ERROR ->]*ngIf="var a=b">"): TestComp@0:5'
            ].join("\n")
          ]);
        });
        test("should parse variables via let ...", () {
          expect(humanizeTplAst(parse("<div *ngIf=\"let a=b\">", [])), [
            [EmbeddedTemplateAst],
            [VariableAst, "a", "b"],
            [ElementAst, "div"]
          ]);
        });
        group("directives", () {
          test("should locate directives in property bindings", () {
            var dirA = CompileDirectiveMetadata.create(
                selector: "[a=b]",
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: "DirA"),
                inputs: ["a"]);
            var dirB = CompileDirectiveMetadata.create(
                selector: "[b]",
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: "DirB"));
            expect(
                humanizeTplAst(parse("<div template=\"a b\" b>", [dirA, dirB])),
                [
                  [EmbeddedTemplateAst],
                  [DirectiveAst, dirA],
                  [BoundDirectivePropertyAst, "a", "b"],
                  [ElementAst, "div"],
                  [AttrAst, "b", ""],
                  [DirectiveAst, dirB]
                ]);
          });
          test("should not locate directives in variables", () {
            var dirA = CompileDirectiveMetadata.create(
                selector: "[a]",
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: "DirA"));
            expect(
                humanizeTplAst(parse("<div template=\"let a=b\">", [dirA])), [
              [EmbeddedTemplateAst],
              [VariableAst, "a", "b"],
              [ElementAst, "div"]
            ]);
          });
          test("should not locate directives in references", () {
            var dirA = CompileDirectiveMetadata.create(
                selector: "[a]",
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: "DirA"));
            expect(humanizeTplAst(parse("<div ref-a>", [dirA])), [
              [ElementAst, "div"],
              [ReferenceAst, "a", null]
            ]);
          });
        });
        test(
            'should work with *... and use the attribute name as '
            'property binding name', () {
          expect(humanizeTplAst(parse("<div *ngIf=\"test\">", [ngIf])), [
            [EmbeddedTemplateAst],
            [DirectiveAst, ngIf],
            [BoundDirectivePropertyAst, "ngIf", "test"],
            [ElementAst, "div"]
          ]);
        });
        test("should work with *... and empty value", () {
          expect(humanizeTplAst(parse("<div *ngIf>", [ngIf])), [
            [EmbeddedTemplateAst],
            [DirectiveAst, ngIf],
            [BoundDirectivePropertyAst, "ngIf", "null"],
            [ElementAst, "div"]
          ]);
        });
      });
    });
    group("content projection", () {
      var compCounter;
      setUp(() {
        compCounter = 0;
      });
      CompileDirectiveMetadata createComp(
          String selector, List<String> ngContentSelectors) {
        return CompileDirectiveMetadata.create(
            selector: selector,
            isComponent: true,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl,
                name: '''SomeComp${ compCounter ++}'''),
            template: new CompileTemplateMetadata(
                ngContentSelectors: ngContentSelectors));
      }
      CompileDirectiveMetadata createDir(String selector) {
        return CompileDirectiveMetadata.create(
            selector: selector,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl,
                name: '''SomeDir${ compCounter ++}'''));
      }
      group("project text nodes", () {
        test("should project text nodes with wildcard selector", () {
          expect(
              humanizeContentProjection(parse("<div>hello</div>", [
                createComp("div", ["*"])
              ])),
              [
                ["div", null],
                ["#text(hello)", 0]
              ]);
        });
      });
      group("project elements", () {
        test("should project elements with wildcard selector", () {
          expect(
              humanizeContentProjection(parse("<div><span></span></div>", [
                createComp("div", ["*"])
              ])),
              [
                ["div", null],
                ["span", 0]
              ]);
        });
        test("should project elements with css selector", () {
          expect(
              humanizeContentProjection(parse("<div><a x></a><b></b></div>", [
                createComp("div", ["a[x]"])
              ])),
              [
                ["div", null],
                ["a", 0],
                ["b", null]
              ]);
        });
      });
      group("embedded templates", () {
        test("should project embedded templates with wildcard selector", () {
          expect(
              humanizeContentProjection(
                  parse("<div><template></template></div>", [
                createComp("div", ["*"])
              ])),
              [
                ["div", null],
                ["template", 0]
              ]);
        });
        test("should project embedded templates with css selector", () {
          expect(
              humanizeContentProjection(parse(
                  "<div><template x></template><template></template></div>", [
                createComp("div", ["template[x]"])
              ])),
              [
                ["div", null],
                ["template", 0],
                ["template", null]
              ]);
        });
      });
      group("ng-content", () {
        test("should project ng-content with wildcard selector", () {
          expect(
              humanizeContentProjection(
                  parse("<div><ng-content></ng-content></div>", [
                createComp("div", ["*"])
              ])),
              [
                ["div", null],
                ["ng-content", 0]
              ]);
        });
        test("should project ng-content with css selector", () {
          expect(
              humanizeContentProjection(parse(
                  "<div><ng-content x></ng-content><ng-content></ng-content></div>",
                  [
                    createComp("div", ["ng-content[x]"])
                  ])),
              [
                ["div", null],
                ["ng-content", 0],
                ["ng-content", null]
              ]);
        });
      });
      test("should project into the first matching ng-content", () {
        expect(
            humanizeContentProjection(parse("<div>hello<b></b><a></a></div>", [
              createComp("div", ["a", "b", "*"])
            ])),
            [
              ["div", null],
              ["#text(hello)", 2],
              ["b", 1],
              ["a", 0]
            ]);
      });
      test("should project into wildcard ng-content last", () {
        expect(
            humanizeContentProjection(parse("<div>hello<a></a></div>", [
              createComp("div", ["*", "a"])
            ])),
            [
              ["div", null],
              ["#text(hello)", 0],
              ["a", 1]
            ]);
      });
      test("should only project direct child nodes", () {
        expect(
            humanizeContentProjection(
                parse("<div><span><a></a></span><a></a></div>", [
              createComp("div", ["a"])
            ])),
            [
              ["div", null],
              ["span", null],
              ["a", null],
              ["a", 0]
            ]);
      });
      test("should project nodes of nested components", () {
        expect(
            humanizeContentProjection(parse("<a><b>hello</b></a>", [
              createComp("a", ["*"]),
              createComp("b", ["*"])
            ])),
            [
              ["a", null],
              ["b", 0],
              ["#text(hello)", 0]
            ]);
      });
      test("should project children of components with ngNonBindable", () {
        expect(
            humanizeContentProjection(
                parse("<div ngNonBindable>{{hello}}<span></span></div>", [
              createComp("div", ["*"])
            ])),
            [
              ["div", null],
              ["#text({{hello}})", 0],
              ["span", 0]
            ]);
      });
      test("should match the element when there is an inline template", () {
        expect(
            humanizeContentProjection(
                parse("<div><b *ngIf=\"cond\"></b></div>", [
              createComp("div", ["a", "b"]),
              ngIf
            ])),
            [
              ["div", null],
              ["template", 1],
              ["b", null]
            ]);
      });
      group("ngProjectAs", () {
        test("should override elements", () {
          expect(
              humanizeContentProjection(
                  parse("<div><a ngProjectAs=\"b\"></a></div>", [
                createComp("div", ["a", "b"])
              ])),
              [
                ["div", null],
                ["a", 1]
              ]);
        });
        test("should override <ng-content>", () {
          expect(
              humanizeContentProjection(parse(
                  "<div><ng-content ngProjectAs=\"b\"></ng-content></div>", [
                createComp("div", ["ng-content", "b"])
              ])),
              [
                ["div", null],
                ["ng-content", 1]
              ]);
        });
        test("should override <template>", () {
          expect(
              humanizeContentProjection(
                  parse("<div><template ngProjectAs=\"b\"></template></div>", [
                createComp("div", ["template", "b"])
              ])),
              [
                ["div", null],
                ["template", 1]
              ]);
        });
        test("should override inline templates", () {
          expect(
              humanizeContentProjection(
                  parse("<div><a *ngIf=\"cond\" ngProjectAs=\"b\"></a></div>", [
                createComp("div", ["a", "b"]),
                ngIf
              ])),
              [
                ["div", null],
                ["template", 1],
                ["a", null]
              ]);
        });
      });
      test("should support other directives before the component", () {
        expect(
            humanizeContentProjection(parse("<div>hello</div>", [
              createDir("div"),
              createComp("div", ["*"])
            ])),
            [
              ["div", null],
              ["#text(hello)", 0]
            ]);
      });
    });
    group("splitClasses", () {
      test("should keep an empty class", () {
        expect(splitClasses("a"), ["a"]);
      });
      test("should split 2 classes", () {
        expect(splitClasses("a b"), ["a", "b"]);
      });
      test("should trim classes", () {
        expect(splitClasses(" a  b "), ["a", "b"]);
      });
    });
    group("error cases", () {
      test("should report when ng-content has content", () {
        expect(
            () => parse("<ng-content>content</ng-content>", []),
            throwsWith('Template parse errors:\n'
                '<ng-content> element cannot have content. <ng-content> '
                'must be immediately followed by </ng-content> ("[ERROR ->]'
                '<ng-content>content</ng-content>"): TestComp@0:0'));
      });
      test("should report invalid property names", () {
        expect(
            () => parse("<div [invalidProp]></div>", []),
            throwsWith('Template parse errors:\n'
                'Can\'t bind to \'invalidProp\' since it isn\'t a known '
                'native property ("<div [ERROR ->][invalidProp]></div>"): '
                'TestComp@0:5'));
      });
      test("should report errors in expressions", () {
        expect(
            () => parse("<div [prop]=\"a b\"></div>", []),
            throwsWith('Template parse errors:\n'
                'Parser Error: Unexpected token \'b\' at column 3 in [a b] in '
                'TestComp@0:5 ("<div [ERROR ->][prop]="a b"></div>"): '
                'TestComp@0:5'));
      });
      test(
          'should not throw on invalid property names if the property is '
          'used by a directive', () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "div",
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirA"),
            inputs: ["invalidProp"]);
        // Should not throw:
        parse("<div [invalid-prop]></div>", [dirA]);
      });
      test("should not allow more than 1 component per element", () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "div",
            isComponent: true,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirA"),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        var dirB = CompileDirectiveMetadata.create(
            selector: "div",
            isComponent: true,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirB"),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse("<div>", [dirB, dirA]),
            throwsWith('Template parse errors:\n'
                'More than one component: DirB,DirA ("[ERROR ->]<div>"): '
                'TestComp@0:0'));
      });
      test(
          'should not allow components or element bindings nor dom events '
          'on explicit embedded templates', () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "[a]",
            isComponent: true,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirA"),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse("<template [a]=\"b\" (e)=\"f\"></template>", [dirA]),
            throwsWith('Template parse errors:\n'
                'Event binding e not emitted by any directive on an embedded '
                'template ("<template [a]="b" [ERROR ->](e)="f"></template>")'
                ': TestComp@0:18\n'
                'Components on an embedded template: DirA ("[ERROR ->]'
                '<template [a]="b" (e)="f"></template>"): TestComp@0:0\n'
                'Property binding a not used by any directive on an embedded '
                'template ("[ERROR ->]<template [a]="b" '
                '(e)="f"></template>"): TestComp@0:0'));
      });
      test(
          'should not allow components or element bindings on inline '
          'embedded templates', () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "[a]",
            isComponent: true,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirA"),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse("<div *a=\"b\"></div>", [dirA]),
            throwsWith('Template parse errors:\n'
                'Components on an embedded template: DirA ("[ERROR ->]'
                '<div *a="b"></div>"): TestComp@0:0\n'
                'Property binding a not used by any directive on an embedded '
                'template ("[ERROR ->]<div *a="b"></div>"): TestComp@0:0'));
      });
    });
    group("ignore elements", () {
      test("should ignore <script> elements", () {
        expect(humanizeTplAst(parse("<script></script>a", [])), [
          [TextAst, "a"]
        ]);
      });
      test("should ignore <style> elements", () {
        expect(humanizeTplAst(parse("<style></style>a", [])), [
          [TextAst, "a"]
        ]);
      });
      group("<link rel=\"stylesheet\">", () {
        test(
            'should keep <link rel=\"stylesheet\"> elements if they '
            'have an absolute non package: url', () {
          expect(
              humanizeTplAst(parse(
                  "<link rel=\"stylesheet\" href=\"http://someurl\">a", [])),
              [
                [ElementAst, "link"],
                [AttrAst, "rel", "stylesheet"],
                [AttrAst, "href", "http://someurl"],
                [TextAst, "a"]
              ]);
        });
        test(
            'should keep <link rel=\"stylesheet\"> elements if they '
            'have no uri', () {
          expect(humanizeTplAst(parse("<link rel=\"stylesheet\">a", [])), [
            [ElementAst, "link"],
            [AttrAst, "rel", "stylesheet"],
            [TextAst, "a"]
          ]);
          expect(humanizeTplAst(parse("<link REL=\"stylesheet\">a", [])), [
            [ElementAst, "link"],
            [AttrAst, "REL", "stylesheet"],
            [TextAst, "a"]
          ]);
        });
        test(
            'should ignore <link rel=\"stylesheet\"> elements if they have '
            'a relative uri', () {
          expect(
              humanizeTplAst(
                  parse("<link rel=\"stylesheet\" href=\"./other.css\">a", [])),
              [
                [TextAst, "a"]
              ]);
          expect(
              humanizeTplAst(
                  parse("<link rel=\"stylesheet\" HREF=\"./other.css\">a", [])),
              [
                [TextAst, "a"]
              ]);
        });
        test(
            'should ignore <link rel=\"stylesheet\"> elements if they '
            'have a package: uri', () {
          expect(
              humanizeTplAst(parse(
                  "<link rel=\"stylesheet\" href=\"package:somePackage\">a",
                  [])),
              [
                [TextAst, "a"]
              ]);
        });
      });
      test('should ignore bindings on children of elements with ngNonBindable',
          () {
        expect(humanizeTplAst(parse("<div ngNonBindable>{{b}}</div>", [])), [
          [ElementAst, "div"],
          [AttrAst, "ngNonBindable", ""],
          [TextAst, "{{b}}"]
        ]);
      });
      test("should keep nested children of elements with ngNonBindable", () {
        expect(
            humanizeTplAst(
                parse("<div ngNonBindable><span>{{b}}</span></div>", [])),
            [
              [ElementAst, "div"],
              [AttrAst, "ngNonBindable", ""],
              [ElementAst, "span"],
              [TextAst, "{{b}}"]
            ]);
      });
      test(
          'should ignore <script> elements inside of elements with '
          'ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse("<div ngNonBindable><script></script>a</div>", [])),
            [
              [ElementAst, "div"],
              [AttrAst, "ngNonBindable", ""],
              [TextAst, "a"]
            ]);
      });
      test(
          'should ignore <style> elements inside of elements with '
          'ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse("<div ngNonBindable><style></style>a</div>", [])),
            [
              [ElementAst, "div"],
              [AttrAst, "ngNonBindable", ""],
              [TextAst, "a"]
            ]);
      });
      test(
          'should ignore <link rel=\"stylesheet\"> elements inside of '
          'elements with ngNonBindable', () {
        expect(
            humanizeTplAst(parse(
                "<div ngNonBindable><link rel=\"stylesheet\">a</div>", [])),
            [
              [ElementAst, "div"],
              [AttrAst, "ngNonBindable", ""],
              [TextAst, "a"]
            ]);
      });
      test(
          'should convert <ng-content> elements into regular elements '
          'inside of elements with ngNonBindable', () {
        expect(
            humanizeTplAst(parse(
                "<div ngNonBindable><ng-content></ng-content>a</div>", [])),
            [
              [ElementAst, "div"],
              [AttrAst, "ngNonBindable", ""],
              [ElementAst, "ng-content"],
              [TextAst, "a"]
            ]);
      });
    });
    group("source spans", () {
      test("should support ng-content", () {
        var parsed = parse("<ng-content select=\"a\">", []);
        expect(humanizeTplAstSourceSpans(parsed), [
          [NgContentAst, "<ng-content select=\"a\">"]
        ]);
      });
      test("should support embedded template", () {
        expect(humanizeTplAstSourceSpans(parse("<template></template>", [])), [
          [EmbeddedTemplateAst, "<template>"]
        ]);
      });
      test("should support element and attributes", () {
        expect(humanizeTplAstSourceSpans(parse("<div key=value>", [])), [
          [ElementAst, "div", "<div key=value>"],
          [AttrAst, "key", "value", "key=value"]
        ]);
      });
      test("should support references", () {
        expect(humanizeTplAstSourceSpans(parse("<div #a></div>", [])), [
          [ElementAst, "div", "<div #a>"],
          [ReferenceAst, "a", null, "#a"]
        ]);
      });
      test("should support variables", () {
        expect(
            humanizeTplAstSourceSpans(
                parse("<template let-a=\"b\"></template>", [])),
            [
              [EmbeddedTemplateAst, "<template let-a=\"b\">"],
              [VariableAst, "a", "b", "let-a=\"b\""]
            ]);
      });
      test("should support events", () {
        expect(
            humanizeTplAstSourceSpans(parse("<div (window:event)=\"v\">", [])),
            [
              [ElementAst, "div", "<div (window:event)=\"v\">"],
              [BoundEventAst, "event", "window", "v", "(window:event)=\"v\""]
            ]);
      });
      test("should support element property", () {
        expect(humanizeTplAstSourceSpans(parse("<div [someProp]=\"v\">", [])), [
          [ElementAst, "div", "<div [someProp]=\"v\">"],
          [
            BoundElementPropertyAst,
            PropertyBindingType.Property,
            "someProp",
            "v",
            null,
            "[someProp]=\"v\""
          ]
        ]);
      });
      test("should support bound text", () {
        expect(humanizeTplAstSourceSpans(parse("{{a}}", [])), [
          [BoundTextAst, "{{ a }}", "{{a}}"]
        ]);
      });
      test("should support text nodes", () {
        expect(humanizeTplAstSourceSpans(parse("a", [])), [
          [TextAst, "a", "a"]
        ]);
      });
      test("should support directive", () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "[a]",
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: "DirA"));
        var comp = CompileDirectiveMetadata.create(
            selector: "div",
            isComponent: true,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: "ZComp"),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(humanizeTplAstSourceSpans(parse("<div a>", [dirA, comp])), [
          [ElementAst, "div", "<div a>"],
          [AttrAst, "a", "", "a"],
          [DirectiveAst, dirA, "<div a>"],
          [DirectiveAst, comp, "<div a>"]
        ]);
      });
      test("should support directive in namespace", () {
        var tagSel = CompileDirectiveMetadata.create(
            selector: "circle",
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: "elDir"));
        var attrSel = CompileDirectiveMetadata.create(
            selector: "[href]",
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: "attrDir"));
        expect(
            humanizeTplAstSourceSpans(parse(
                "<svg><circle /><use xlink:href=\"Port\" /></svg>",
                [tagSel, attrSel])),
            [
              [ElementAst, "@svg:svg", "<svg>"],
              [ElementAst, "@svg:circle", "<circle />"],
              [DirectiveAst, tagSel, "<circle />"],
              [ElementAst, "@svg:use", "<use xlink:href=\"Port\" />"],
              [AttrAst, "@xlink:href", "Port", "xlink:href=\"Port\""],
              [DirectiveAst, attrSel, "<use xlink:href=\"Port\" />"]
            ]);
      });
      test("should support directive property", () {
        var dirA = CompileDirectiveMetadata.create(
            selector: "div",
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: "DirA"),
            inputs: ["aProp"]);
        expect(
            humanizeTplAstSourceSpans(
                parse("<div [aProp]=\"foo\"></div>", [dirA])),
            [
              [ElementAst, "div", "<div [aProp]=\"foo\">"],
              [DirectiveAst, dirA, "<div [aProp]=\"foo\">"],
              [BoundDirectivePropertyAst, "aProp", "foo", "[aProp]=\"foo\""]
            ]);
      });
    });
    group("pipes", () {
      test("should allow pipes that have been defined as dependencies", () {
        var testPipe = new CompilePipeMetadata(
            name: "test",
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: "DirA"));
        // Should not throw.
        parse("{{a | test}}", [], [testPipe]);
      });
      test(
          'should report pipes as error that have not been defined '
          'as dependencies', () {
        expect(
            () => parse("{{a | test}}", []),
            throwsWith('Template parse errors:\n'
                'The pipe \'test\' could not be found '
                '("[ERROR ->]{{a | test}}"): TestComp@0:0'));
      });
    });
  });
}

List<dynamic> humanizeTplAst(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateHumanizer(false);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

List<dynamic> humanizeTplAstSourceSpans(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateHumanizer(true);
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

class TemplateHumanizer implements TemplateAstVisitor {
  bool includeSourceSpan;
  List<dynamic> result = [];
  TemplateHumanizer(this.includeSourceSpan) {}
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    var res = [NgContentAst];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    var res = [EmbeddedTemplateAst];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.variables);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    var res = [ElementAst, ast.name];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.attrs);
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.outputs);
    templateVisitAll(this, ast.references);
    templateVisitAll(this, ast.directives);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    var res = [ReferenceAst, ast.name, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    var res = [VariableAst, ast.name, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    var res = [
      BoundEventAst,
      ast.name,
      ast.target,
      expressionUnparser.unparse(ast.handler)
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    var res = [
      BoundElementPropertyAst,
      ast.type,
      ast.name,
      expressionUnparser.unparse(ast.value),
      ast.unit
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    var res = [AttrAst, ast.name, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    var res = [BoundTextAst, expressionUnparser.unparse(ast.value)];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitText(TextAst ast, dynamic context) {
    var res = [TextAst, ast.value];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    var res = [DirectiveAst, ast.directive];
    this.result.add(this._appendContext(ast, res));
    templateVisitAll(this, ast.inputs);
    templateVisitAll(this, ast.hostProperties);
    templateVisitAll(this, ast.hostEvents);
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    var res = [
      BoundDirectivePropertyAst,
      ast.directiveName,
      expressionUnparser.unparse(ast.value)
    ];
    this.result.add(this._appendContext(ast, res));
    return null;
  }

  List<dynamic> _appendContext(TemplateAst ast, List<dynamic> input) {
    if (!this.includeSourceSpan) return input;
    input.add(ast.sourceSpan.toString());
    return input;
  }
}

String sourceInfo(TemplateAst ast) {
  return '''${ ast . sourceSpan}: ${ ast . sourceSpan . start}''';
}

List<dynamic> humanizeContentProjection(List<TemplateAst> templateAsts) {
  var humanizer = new TemplateContentProjectionHumanizer();
  templateVisitAll(humanizer, templateAsts);
  return humanizer.result;
}

class TemplateContentProjectionHumanizer implements TemplateAstVisitor {
  List<dynamic> result = [];
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    this.result.add(["ng-content", ast.ngContentIndex]);
    return null;
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    this.result.add(["template", ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    this.result.add([ast.name, ast.ngContentIndex]);
    templateVisitAll(this, ast.children);
    return null;
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    return null;
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    return null;
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    return null;
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    return null;
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    return null;
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    this.result.add([
      '''#text(${ expressionUnparser . unparse ( ast . value )})''',
      ast.ngContentIndex
    ]);
    return null;
  }

  dynamic visitText(TextAst ast, dynamic context) {
    this.result.add(['''#text(${ ast . value})''', ast.ngContentIndex]);
    return null;
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    return null;
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    return null;
  }
}

class FooAstTransformer implements TemplateAstVisitor {
  dynamic visitNgContent(NgContentAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitEmbeddedTemplate(EmbeddedTemplateAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitElement(ElementAst ast, dynamic context) {
    if (ast.name != "div") return ast;
    return new ElementAst("foo", [], [], [], [], [], [], false, [],
        ast.ngContentIndex, ast.sourceSpan);
  }

  dynamic visitReference(ReferenceAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitVariable(VariableAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitEvent(BoundEventAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitElementProperty(BoundElementPropertyAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitAttr(AttrAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitBoundText(BoundTextAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitText(TextAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitDirective(DirectiveAst ast, dynamic context) {
    throw "not implemented";
  }

  dynamic visitDirectiveProperty(
      BoundDirectivePropertyAst ast, dynamic context) {
    throw "not implemented";
  }
}

class BarAstTransformer extends FooAstTransformer {
  dynamic visitElement(ElementAst ast, dynamic context) {
    if (ast.name != "foo") return ast;
    return new ElementAst("bar", [], [], [], [], [], [], false, [],
        ast.ngContentIndex, ast.sourceSpan);
  }
}

bool compareProviderList(List a, List b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i]?.toJson()?.toString() != b[i]?.toJson()?.toString()) {
      print('a> ${a[i]?.toJson()}');
      print('b> ${b[i]?.toJson()}');
      return false;
    }
  }
  return true;
}

class ArrayConsole implements Console {
  List<String> logs = [];
  List<String> warnings = [];
  log(String msg) {
    this.logs.add(msg);
  }

  warn(String msg) {
    this.warnings.add(msg);
  }

  clear() {
    logs.clear();
    warnings.clear();
  }
}
