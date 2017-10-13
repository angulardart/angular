@TestOn('vm')
import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:_tests/test_util.dart';
import 'package:angular/src/compiler/ast_template_parser.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/compiler_utils.dart';
import 'package:angular/src/compiler/expression_parser/lexer.dart';
import 'package:angular/src/compiler/expression_parser/parser.dart';
import 'package:angular/src/compiler/identifiers.dart'
    show identifierToken, Identifiers;
import 'package:angular/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular/src/compiler/schema/element_schema_registry.dart'
    show ElementSchemaRegistry;
import 'package:angular/src/compiler/template_ast.dart';

import 'schema_registry_mock.dart' show MockSchemaRegistry;
import 'template_humanizer_util.dart';

const someModuleUrl = 'package:someModule';

typedef List<TemplateAst> ParseTemplate(
  String template,
  List<CompileDirectiveMetadata> directives, [
  List<CompilePipeMetadata> pipes,
]);

class ArrayConsole {
  List<String> logs = [];
  List<String> warnings = [];

  ArrayConsole() {
    Logger.root.onRecord.listen((LogRecord rec) {
      if (rec.level == Level.WARNING) {
        warn(rec.message);
      } else {
        log(rec.message);
      }
    });
  }

  void log(String msg) {
    this.logs.add(msg);
  }

  void warn(String msg) {
    this.warnings.add(msg);
  }

  void clear() {
    logs.clear();
    warnings.clear();
  }
}

void main() {
  final console = new ArrayConsole();
  final ngIf = createCompileDirectiveMetadata(
      selector: '[ngIf]',
      type: new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'NgIf'),
      inputs: ['ngIf']);
  final component = createCompileDirectiveMetadata(
      selector: 'root',
      type: new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'Root'),
      metadataType: CompileDirectiveMetadataType.Component);

  ParseTemplate parse;

  void setUpParser({ElementSchemaRegistry elementSchemaRegistry}) {
    elementSchemaRegistry ??= new MockSchemaRegistry(
        {'invalidProp': false}, {'mappedAttr': 'mappedProp'});
    final parser =
        new AstTemplateParser(elementSchemaRegistry, new Parser(new Lexer()));
    parse = (template, directives, [pipes]) =>
        parser.parse(component, template, directives, pipes ?? [], 'TestComp');
  }

  group('TemplateParser', () {
    setUp(() {
      setUpParser();
    });

    tearDown(() {
      console.clear();
    });

    group('parse', () {
      group('nodes without bindings', () {
        test('should parse text nodes', () {
          expect(humanizeTplAst(parse('a', [])), [
            [TextAst, 'a']
          ]);
        });

        test('should parse elements with attributes', () {
          expect(humanizeTplAst(parse('<div a="b"></div>', [])), [
            [ElementAst, 'div'],
            [AttrAst, 'a', 'b']
          ]);
        });
      });

      test('should parse ngContent', () {
        var parsed = parse('<ng-content select="a"></ng-content>', []);
        expect(humanizeTplAst(parsed), [
          [NgContentAst]
        ]);
      });

      test('should parse ngContent regardless the namespace', () {
        var parsed = parse('<svg><ng-content></ng-content></svg>', []);
        expect(humanizeTplAst(parsed), [
          [ElementAst, '@svg:svg'],
          [NgContentAst]
        ]);
      }, skip: 'Doesn\'t namespace yet.');

      test('should parse bound text nodes', () {
        expect(humanizeTplAst(parse('{{a}}', [])), [
          [BoundTextAst, '{{ a }}']
        ]);
      });

      group('bound properties', () {
        test('should parse mixed case bound properties', () {
          expect(humanizeTplAst(parse('<div [someProp]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'someProp',
              'v',
              null
            ]
          ]);
        });

        test('should parse dash case bound properties', () {
          expect(humanizeTplAst(parse('<div [some-prop]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'some-prop',
              'v',
              null
            ]
          ]);
        });

        test('should normalize property names via the element schema', () {
          expect(humanizeTplAst(parse('<div [mappedAttr]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'mappedProp',
              'v',
              null
            ]
          ]);
        });

        test('should parse mixed case bound attributes', () {
          expect(humanizeTplAst(parse('<div [attr.someAttr]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Attribute,
              'someAttr',
              'v',
              null
            ]
          ]);
        });

        test('should parse and dash case bound classes', () {
          expect(
              humanizeTplAst(parse('<div [class.some-class]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Class,
              'some-class',
              'v',
              null
            ]
          ]);
        });

        test('should parse mixed case bound classes', () {
          expect(
              humanizeTplAst(parse('<div [class.someClass]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Class,
              'someClass',
              'v',
              null
            ]
          ]);
        });

        test('should parse mixed case bound styles', () {
          expect(
              humanizeTplAst(parse('<div [style.someStyle]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Style,
              'someStyle',
              'v',
              null
            ]
          ]);
        });

        test('should report invalid prefixes', () {
          expect(
              () => parse('<p [atTr.foo]></p>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 4 of TestComp: ParseErrorLevel.FATAL: Invalid property name \'atTr.foo\'\n'
                  '[atTr.foo]\n'
                  '^^^^^^^^^^'));
          expect(
              () => parse('<p [sTyle.foo]></p>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 4 of TestComp: ParseErrorLevel.FATAL: Invalid property name \'sTyle.foo\'\n'
                  '[sTyle.foo]\n'
                  '^^^^^^^^^^^'));
          expect(
              () => parse('<p [Class.foo]></p>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 4 of TestComp: ParseErrorLevel.FATAL: Invalid property name \'Class.foo\'\n'
                  '[Class.foo]\n'
                  '^^^^^^^^^^^'));
          expect(
              () => parse('<p [bar.foo]></p>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 4 of TestComp: ParseErrorLevel.FATAL: Invalid property name \'bar.foo\'\n'
                  '[bar.foo]\n'
                  '^^^^^^^^^'));
        }, skip: 'Error handing doesn\t match yet.');

        test(
            'should parse bound properties via [...] and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse('<div [prop]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'prop',
              'v',
              null
            ]
          ]);
        });

        test(
            'should parse bound properties via bind- and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse('<div bind-prop="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'prop',
              'v',
              null
            ]
          ]);
        });

        test(
            'should parse bound properties via {{...}} and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse('<div prop="{{v}}"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'prop',
              '{{ v }}',
              null
            ]
          ]);
        }, skip: 'angular_ast reports this as an attribute.');
      });

      group('events', () {
        test('should parse bound events with a target', () {
          expect(
              () => parse('<div (window:event)="v"></div>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: ":" is not allowed in event names: window:event\n'
                  '(window:event)="v"\n'
                  '^^^^^^^^^^^^^^^^^^'));
        }, skip: 'does not throw');

        test(
            'should parse bound events via (...) and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse('<div (event)="v"></div>', [])), [
            [ElementAst, 'div'],
            [BoundEventAst, 'event', null, 'v']
          ]);
        });

        test('should parse event names case sensitive', () {
          expect(humanizeTplAst(parse('<div (some-event)="v"></div>', [])), [
            [ElementAst, 'div'],
            [BoundEventAst, 'some-event', null, 'v']
          ]);
          expect(humanizeTplAst(parse('<div (someEvent)="v"></div>', [])), [
            [ElementAst, 'div'],
            [BoundEventAst, 'someEvent', null, 'v']
          ]);
        });

        test(
            'should parse bound events via on- and not report them '
            'as attributes', () {
          expect(humanizeTplAst(parse('<div on-event="v"></div>', [])), [
            [ElementAst, 'div'],
            [BoundEventAst, 'event', null, 'v']
          ]);
        });

        test(
            'should allow events on explicit embedded templates that are '
            'emitted by a directive', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'template',
              outputs: ['e'],
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'));
          expect(
              humanizeTplAst(parse('<template (e)="f"></template>', [dirA])), [
            [EmbeddedTemplateAst],
            [BoundEventAst, 'e', null, 'f'],
            [DirectiveAst, dirA]
          ]);
        }, skip: 'Don\'t handle directives yet');
      });

      group('bindon', () {
        test(
            'should parse bound events and properties via [(...)] and not '
            'report them as attributes', () {
          expect(humanizeTplAst(parse('<div [(prop)]="v"></div>', [])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'prop',
              'v',
              null
            ],
            [BoundEventAst, 'propChange', null, 'v = \$event']
          ]);
        });

        test(
            'should parse bound events and properties via bindon- and not '
            'report them as attributes', () {
          expect(humanizeTplAst(parse('<div bindon-prop="v"></div>', [])), [
            [ElementAst, 'div'],
            [AttrAst, 'bindon-prop', 'v']
          ]);

          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.WARNING: "bindon-" for properties/events is no longer supported. Use "[()]" instead!\n'
                  'bindon-prop="v"\n'
                  '^^^^^'
            ].join('\n')
          ]);
        }, skip: 'Don\'t have warning yet.');
      });

      group('directives', () {
        test(
            'should order directives by the directives array in the View '
            'and match them only once', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'));
          var dirB = createCompileDirectiveMetadata(
              selector: '[b]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirB'));
          var dirC = createCompileDirectiveMetadata(
              selector: '[c]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirC'));
          expect(
              humanizeTplAst(
                  parse('<div a c b a b></div>', [dirA, dirB, dirC])),
              [
                [ElementAst, 'div'],
                [AttrAst, 'a', ''],
                [AttrAst, 'c', ''],
                [AttrAst, 'b', ''],
                [AttrAst, 'a', ''],
                [AttrAst, 'b', ''],
                [DirectiveAst, dirA],
                [DirectiveAst, dirB],
                [DirectiveAst, dirC]
              ]);
        });

        test('should locate directives in property bindings', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a=b]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'));
          var dirB = createCompileDirectiveMetadata(
              selector: '[b]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirB'));
          expect(humanizeTplAst(parse('<div [a]="b"></div>', [dirA, dirB])), [
            [ElementAst, 'div'],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'a',
              'b',
              null
            ],
            [DirectiveAst, dirA]
          ]);
        });

        test('should locate directives in event bindings', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirB'));
          expect(humanizeTplAst(parse('<div (a)="b"></div>', [dirA])), [
            [ElementAst, 'div'],
            [BoundEventAst, 'a', null, 'b'],
            [DirectiveAst, dirA]
          ]);
        });

        test('should parse directive host properties', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              host: {'[a]': 'expr'});
          expect(humanizeTplAst(parse('<div></div>', [dirA])), [
            [ElementAst, 'div'],
            [DirectiveAst, dirA],
            [
              BoundElementPropertyAst,
              PropertyBindingType.Property,
              'a',
              'expr',
              null
            ]
          ]);
        });

        test('should parse directive host listeners', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              host: {'(a)': 'expr'});
          expect(humanizeTplAst(parse('<div></div>', [dirA])), [
            [ElementAst, 'div'],
            [DirectiveAst, dirA],
            [BoundEventAst, 'a', null, 'expr']
          ]);
        });

        test('should parse directive properties', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              inputs: ['aProp']);
          expect(humanizeTplAst(parse('<div [aProp]="expr"></div>', [dirA])), [
            [ElementAst, 'div'],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, 'aProp', 'expr']
          ]);
        });

        test('should parse renamed directive properties', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              inputs: ['b:a']);
          expect(humanizeTplAst(parse('<div [a]="expr"></div>', [dirA])), [
            [ElementAst, 'div'],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, 'b', 'expr']
          ]);
        });

        test('should parse literal directive properties', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              inputs: ['a']);
          expect(humanizeTplAst(parse('<div a="literal"></div>', [dirA])), [
            [ElementAst, 'div'],
            [AttrAst, 'a', 'literal'],
            [DirectiveAst, dirA],
            [BoundDirectivePropertyAst, 'a', '"literal"']
          ]);
        });

        test('should favor explicit bound properties over literal properties',
            () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              inputs: ['a']);
          expect(
              humanizeTplAst(
                  parse('<div a="literal" [a]="\'literal2\'"></div>', [dirA])),
              [
                [ElementAst, 'div'],
                [AttrAst, 'a', 'literal'],
                [DirectiveAst, dirA],
                [BoundDirectivePropertyAst, 'a', '"literal2"']
              ]);
        });

        test('should support optional directive properties', () {
          var dirA = createCompileDirectiveMetadata(
              selector: 'div',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              inputs: ['a']);
          expect(humanizeTplAst(parse('<div></div>', [dirA])), [
            [ElementAst, 'div'],
            [DirectiveAst, dirA]
          ]);
        });
      }, skip: 'Don\'t yet handle directives.');

      group('providers', () {
        var nextProviderId;
        CompileTokenMetadata createToken(String value) {
          var token;
          if (value.startsWith('type:')) {
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
          if (value.startsWith('optional:')) {
            isOptional = true;
            value = value.substring(9);
          }
          var isSelf = false;
          if (value.startsWith('self:')) {
            isSelf = true;
            value = value.substring(5);
          }
          var isHost = false;
          if (value.startsWith('host:')) {
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
            {List<CompileProviderMetadata> providers,
            List<CompileProviderMetadata> viewProviders,
            List<String> deps: const [],
            List<String> queries: const []}) {
          var isComponent = !selector.startsWith('[');
          return createCompileDirectiveMetadata(
              selector: selector,
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl,
                  name: selector,
                  diDeps: deps.map(createDep).toList()),
              metadataType: isComponent
                  ? CompileDirectiveMetadataType.Component
                  : CompileDirectiveMetadataType.Directive,
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

        test('should provide a component', () {
          var comp = createDir('my-comp');
          ElementAst elAst = parse('<my-comp>', [comp])[0] as ElementAst;
          expect(elAst.providers, hasLength(1));
          expect(elAst.providers[0].providerType, ProviderAstType.Component);
          expect(elAst.providers[0].providers[0].useClass, comp.type);
        });

        test('should provide a directive', () {
          var dirA = createDir('[dirA]');
          ElementAst elAst = (parse('<div dirA>', [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(1));
          expect(elAst.providers[0].providerType, ProviderAstType.Directive);
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
        });

        test('should use the public providers of a directive', () {
          var provider = createProvider('service');
          var dirA = createDir('[dirA]', providers: [provider]);
          ElementAst elAst = (parse('<div dirA>', [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(
              elAst.providers[1].providerType, ProviderAstType.PublicService);
          expect(elAst.providers[1].providers, orderedEquals([provider]));
        });

        test('should use the private providers of a component', () {
          var provider = createProvider('service');
          var comp = createDir('my-comp', viewProviders: [provider]);
          ElementAst elAst = (parse('<my-comp>', [comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(
              elAst.providers[1].providerType, ProviderAstType.PrivateService);
          expect(elAst.providers[1].providers, orderedEquals([provider]));
        });

        test('should support multi providers', () {
          var provider0 = createProvider('service0', multi: true);
          var provider1 = createProvider('service1', multi: true);
          var provider2 = createProvider('service0', multi: true);
          var dirA = createDir('[dirA]', providers: [provider0, provider1]);
          var dirB = createDir('[dirB]', providers: [provider2]);
          ElementAst elAst =
              (parse('<div dirA dirB>', [dirA, dirB])[0] as ElementAst);
          expect(elAst.providers, hasLength(4));
          expect(elAst.providers[2].providers,
              orderedEquals([provider0, provider2]));
          expect(elAst.providers[3].providers, orderedEquals([provider1]));
        });

        test('should overwrite non multi providers', () {
          var provider1 = createProvider('service0');
          var provider2 = createProvider('service1');
          var provider3 = createProvider('service0');
          var dirA = createDir('[dirA]', providers: [provider1, provider2]);
          var dirB = createDir('[dirB]', providers: [provider3]);
          ElementAst elAst =
              (parse('<div dirA dirB>', [dirA, dirB])[0] as ElementAst);
          expect(elAst.providers, hasLength(4));
          expect(elAst.providers[2].providers, orderedEquals([provider3]));
          expect(elAst.providers[3].providers, orderedEquals([provider2]));
        });

        test('should overwrite component providers by directive providers', () {
          var compProvider = createProvider('service0');
          var dirProvider = createProvider('service0');
          var comp = createDir('my-comp', providers: [compProvider]);
          var dirA = createDir('[dirA]', providers: [dirProvider]);
          ElementAst elAst =
              (parse('<my-comp dirA>', [dirA, comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[2].providers, orderedEquals([dirProvider]));
        });

        test('should overwrite view providers by directive providers', () {
          var viewProvider = createProvider('service0');
          var dirProvider = createProvider('service0');
          var comp = createDir('my-comp', viewProviders: [viewProvider]);
          var dirA = createDir('[dirA]', providers: [dirProvider]);
          ElementAst elAst =
              (parse('<my-comp dirA>', [dirA, comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[2].providers, orderedEquals([dirProvider]));
        });

        test('should overwrite directives by providers', () {
          var dirProvider = createProvider('type:my-comp');
          var comp = createDir('my-comp', providers: [dirProvider]);
          ElementAst elAst = (parse('<my-comp>', [comp])[0] as ElementAst);
          expect(elAst.providers, hasLength(1));
          expect(elAst.providers[0].providers, orderedEquals([dirProvider]));
        });

        test('should throw if mixing multi and non multi providers', () {
          var provider0 = createProvider('service0');
          var provider1 = createProvider('service0', multi: true);
          var dirA = createDir('[dirA]', providers: [provider0]);
          var dirB = createDir('[dirB]', providers: [provider1]);
          expect(
              () => parse('<div dirA dirB>', [dirA, dirB]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: Mixing multi and non multi provider is not possible for token service0\n'
                  '<div dirA dirB>\n'
                  '^^^^^^^^^^^^^^^'));
        });

        test('should sort providers by their DI order', () {
          var provider0 = createProvider('service0', deps: ['type:[dir2]']);
          var provider1 = createProvider('service1');
          var dir2 = createDir('[dir2]', deps: ['service1']);
          var comp = createDir('my-comp', providers: [provider0, provider1]);
          ElementAst elAst =
              parse('<my-comp dir2>', [comp, dir2])[0] as ElementAst;
          expect(elAst.providers, hasLength(4));
          expect(elAst.providers[0].providers[0].useClass, comp.type);
          expect(elAst.providers[1].providers, orderedEquals([provider1]));
          expect(elAst.providers[2].providers[0].useClass, dir2.type);
          expect(elAst.providers[3].providers, orderedEquals([provider0]));
        });

        test('should sort directives by their DI order', () {
          var dir0 = createDir('[dir0]', deps: ['type:my-comp']);
          var dir1 = createDir('[dir1]', deps: ['type:[dir0]']);
          var dir2 = createDir('[dir2]', deps: ['type:[dir1]']);
          var comp = createDir('my-comp');
          ElementAst elAst =
              parse('<my-comp dir2 dir0 dir1>', [comp, dir2, dir0, dir1])[0]
                  as ElementAst;
          expect(elAst.providers, hasLength(4));
          expect(elAst.directives[0].directive, comp);
          expect(elAst.directives[1].directive, dir0);
          expect(elAst.directives[2].directive, dir1);
          expect(elAst.directives[3].directive, dir2);
        });

        test('should mark directives and dependencies of directives as eager',
            () {
          var provider0 = createProvider('service0');
          var provider1 = createProvider('service1');
          var dirA = createDir('[dirA]',
              providers: [provider0, provider1], deps: ['service0']);
          ElementAst elAst = parse('<div dirA>', [dirA])[0] as ElementAst;
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[0].providers, orderedEquals([provider0]));
          expect(elAst.providers[0].eager, true);
          expect(elAst.providers[1].providers[0].useClass, dirA.type);
          expect(elAst.providers[1].eager, true);
          expect(elAst.providers[2].providers, orderedEquals([provider1]));
          expect(elAst.providers[2].eager, false);
        });

        test('should mark dependencies on parent elements as eager', () {
          var provider0 = createProvider('service0');
          var provider1 = createProvider('service1');
          var dirA = createDir('[dirA]', providers: [provider0, provider1]);
          var dirB = createDir('[dirB]', deps: ['service0']);
          ElementAst elAst =
              (parse('<div dirA><div dirB></div></div>', [dirA, dirB])[0]
                  as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, true);
          expect(elAst.providers[1].providers, orderedEquals([provider0]));
          expect(elAst.providers[1].eager, true);
          expect(elAst.providers[2].providers, orderedEquals([provider1]));
          expect(elAst.providers[2].eager, false);
        });

        test('should mark queried providers as eager', () {
          var provider0 = createProvider('service0');
          var provider1 = createProvider('service1');
          var dirA = createDir('[dirA]',
              providers: [provider0, provider1], queries: ['service0']);
          ElementAst elAst =
              (parse('<div dirA></div>', [dirA])[0] as ElementAst);
          expect(elAst.providers, hasLength(3));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, true);
          expect(elAst.providers[1].providers, orderedEquals([provider0]));
          expect(elAst.providers[1].eager, true);
          expect(elAst.providers[2].providers, orderedEquals([provider1]));
          expect(elAst.providers[2].eager, false);
        });

        test('should not mark dependencies accross embedded views as eager',
            () {
          var provider0 = createProvider('service0');
          var dirA = createDir('[dirA]', providers: [provider0]);
          var dirB = createDir('[dirB]', deps: ['service0']);
          ElementAst elAst =
              (parse('<div dirA><div *ngIf dirB></div></div>', [dirA, dirB])[0]
                  as ElementAst);
          expect(elAst.providers, hasLength(2));
          expect(elAst.providers[0].providers[0].useClass, dirA.type);
          expect(elAst.providers[0].eager, true);
          expect(elAst.providers[1].providers, orderedEquals([provider0]));
          expect(elAst.providers[1].eager, false);
        });

        test('should report missing @Self() deps as errors', () {
          var dirA = createDir('[dirA]', deps: ['self:provider0']);
          expect(
              () => parse('<div dirA></div>', [dirA]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: No provider for provider0\n'
                  '<div dirA>\n'
                  '^^^^^^^^^^'));
        });

        test('should change missing @Self() that are optional to nulls', () {
          var dirA = createDir('[dirA]', deps: ['optional:self:provider0']);
          ElementAst elAst =
              (parse('<div dirA></div>', [dirA])[0] as ElementAst);
          expect(elAst.providers[0].providers[0].deps[0].isValue, true);
          expect(elAst.providers[0].providers[0].deps[0].value, isNull);
        });

        test('should report missing @Host() deps as errors', () {
          var dirA = createDir('[dirA]', deps: ['host:provider0']);
          expect(
              () => parse('<div dirA></div>', [dirA]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: No provider for provider0\n'
                  '<div dirA>\n'
                  '^^^^^^^^^^'));
        });

        test('should change missing @Host() that are optional to nulls', () {
          var dirA = createDir('[dirA]', deps: ['optional:host:provider0']);
          ElementAst elAst =
              (parse('<div dirA></div>', [dirA])[0] as ElementAst);
          expect(elAst.providers[0].providers[0].deps[0].isValue, true);
          expect(elAst.providers[0].providers[0].deps[0].value, isNull);
        });

        test('should report cyclic dependencies as errors', () {
          var cycle =
              createDir('[cycleDirective]', deps: ['type:[cycleDirective]']);
          expect(
              () => parse('<div cycleDirective></div>', [cycle]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: '
                  'Cannot instantiate cyclic dependency! [cycleDirective]\n'
                  '<div cycleDirective>\n'));
        });

        test('should report missing @Host() deps in providers as errors', () {
          var needsHost = createDir('[needsHost]', deps: ['host:service']);
          expect(
              () => parse('<div needsHost></div>', [needsHost]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 1 of TestComp: '
                  'ParseErrorLevel.FATAL: No provider for service\n'
                  '<div needsHost>\n'));
        });

        test('should report missing @Self() deps as errors', () {
          var needsDirectiveFromSelf = createDir('[needsDirectiveFromSelf]',
              deps: ['self:type:[simpleDirective]']);
          var simpleDirective = createDir('[simpleDirective]');
          expect(
              () => parse(
                  '<div simpleDirective>'
                  '<div needsDirectiveFromSelf></div>'
                  '</div>',
                  [needsDirectiveFromSelf, simpleDirective]),
              throwsWith('Template parse errors:\n'
                  'line 1, column 22 of TestComp: '
                  'ParseErrorLevel.FATAL: No provider for [simpleDirective]\n'
                  '<div needsDirectiveFromSelf>\n'));
        });
      }, skip: 'Don\'t yet handle proviers');

      group('references', () {
        test(
            'should parse references via #... and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse('<div #a></div>', [])), [
            [ElementAst, 'div'],
            [ReferenceAst, 'a', null]
          ]);
        });

        test(
            'should parse references via ref-... and not report '
            'them as attributes', () {
          expect(humanizeTplAst(parse('<div ref-a></div>', [])), [
            [ElementAst, 'div'],
            [AttrAst, 'ref-a', null]
          ]);

          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.WARNING: Using "ref-" for references is no longer supported. Use "#" instead!\n'
                  'ref-a\n'
                  '^^^^^'
            ].join('\n')
          ]);
        }, skip: 'Don\'t handle errors yet.');

        test(
            'should parse references via var-... and report them as deprecated',
            () {
          expect(humanizeTplAst(parse('<div var-a></div>', [])), [
            [ElementAst, 'div'],
            [AttrAst, 'var-a', null]
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.WARNING: "var-" on non <template> elements is deprecated. Use "ref-" instead!\n'
                  'var-a\n'
                  '^^^^^'
            ].join('\n')
          ]);
        }, skip: 'Don\'t handle errors yet.');

        test('should parse camel case references', () {
          expect(humanizeTplAst(parse('<div #someA></div>', [])), [
            [ElementAst, 'div'],
            [ReferenceAst, 'someA', null]
          ]);
        });

        test('should assign references with empty value to the element', () {
          expect(humanizeTplAst(parse('<div #a></div>', [])), [
            [ElementAst, 'div'],
            [ReferenceAst, 'a', null]
          ]);
        });

        test('should assign references to directives via exportAs', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              exportAs: 'dirA');
          expect(humanizeTplAst(parse('<div a #a="dirA"></div>', [dirA])), [
            [ElementAst, 'div'],
            [AttrAst, 'a', ''],
            [ReferenceAst, 'a', identifierToken(dirA.type)],
            [DirectiveAst, dirA]
          ]);
        }, skip: 'Don\'t handle directives yet.');

        test(
            'should report references with values that dont match a '
            'directive as errors', () {
          expect(
              () => parse('<div #a="dirA"></div>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: There is no directive with "exportAs" set to "dirA"\n'
                  '#a="dirA"\n'
                  '^^^^^^^^^'));
        }, skip: 'Don\'t handle errors yet.');

        test('should report invalid reference names', () {
          expect(
              () => parse('<div #a-b></div>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: "-" is not allowed in reference names\n'
                  '#a-b\n'
                  '^^^^'));
        }, skip: 'Don\'t handle errors yet.');

        test('should report variables as errors', () {
          expect(
              () => parse('<div let-a></div>', []),
              throwsWith('Template parse errors:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: "let-" is only supported on template elements.\n'
                  'let-a\n'
                  '^^^^^'));
        }, skip: 'Don\'t handle errors yet.');

        test('should assign references with empty value to components', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              metadataType: CompileDirectiveMetadataType.Component,
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'),
              exportAs: 'dirA',
              template: new CompileTemplateMetadata(ngContentSelectors: []));
          expect(humanizeTplAst(parse('<div a #a></div>', [dirA])), [
            [ElementAst, 'div'],
            [AttrAst, 'a', ''],
            [ReferenceAst, 'a', identifierToken(dirA.type)],
            [DirectiveAst, dirA]
          ]);
        }, skip: 'Don\'t handle directives yet.');

        test('should not locate directives in references', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'));
          expect(humanizeTplAst(parse('<div ref-a></div>', [dirA])), [
            [ElementAst, 'div'],
            [ReferenceAst, 'a', null]
          ]);
        }, skip: 'Don\'t handle directives yet.');
      });

      group('explicit templates', () {
        test('should create embedded templates for <template> elements', () {
          expect(humanizeTplAst(parse('<template></template>', [])), [
            [EmbeddedTemplateAst]
          ]);
          expect(humanizeTplAst(parse('<TEMPLATE></TEMPLATE>', [])), [
            [EmbeddedTemplateAst]
          ]);
        }, skip: 'Don\'t handle TEMPLATE properly');

        test(
            'should create embedded templates for <template> elements '
            'regardless the namespace', () {
          expect(
              humanizeTplAst(parse('<svg><template></template></svg>', [])), [
            [ElementAst, '@svg:svg'],
            [EmbeddedTemplateAst]
          ]);
        }, skip: 'Don\'t handle namespaces yet.');

        test('should support references via #...', () {
          expect(humanizeTplAst(parse('<template #a></template>', [])), [
            [EmbeddedTemplateAst],
            [ReferenceAst, 'a', identifierToken(Identifiers.TemplateRef)]
          ]);
        }, skip: 'Don\'t yet support identifiers.');

        test('should support references via ref-...', () {
          expect(humanizeTplAst(parse('<template ref-a></template>', [])), [
            [EmbeddedTemplateAst],
            [AttrAst, 'ref-a', '']
          ]);
        });

        test('should parse variables via let-...', () {
          expect(humanizeTplAst(parse('<template let-a="b"></template>', [])), [
            [EmbeddedTemplateAst],
            [VariableAst, 'a', 'b']
          ]);
        });

        test('should parse variables via var-... and report them as deprecated',
            () {
          expect(humanizeTplAst(parse('<template var-a="b"></template>', [])), [
            [EmbeddedTemplateAst],
            [AttrAst, 'var-a', 'b']
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 11 of TestComp: ParseErrorLevel.WARNING: "var-" on <template> elements is deprecated. Use "let-" instead!\n'
                  'var-a="b"\n'
                  '^^^^^^^^^'
            ].join('\n')
          ]);
        }, skip: 'Don\'t handle errors yet.');

        test('should not locate directives in variables', () {
          var dirA = createCompileDirectiveMetadata(
              selector: '[a]',
              type: new CompileTypeMetadata(
                  moduleUrl: someModuleUrl, name: 'DirA'));
          expect(
              humanizeTplAst(parse('<template let-a="b"></template>', [dirA])),
              [
                [EmbeddedTemplateAst],
                [VariableAst, 'a', 'b']
              ]);
        });
      });

      group('inline templates', () {
        test('should wrap the element into an EmbeddedTemplateAST', () {
          expect(humanizeTplAst(parse('<div template></div>', [])), [
            [EmbeddedTemplateAst],
            [ElementAst, 'div']
          ]);
        });

        test('should parse bound properties', () {
          expect(
              humanizeTplAst(parse('<div template="ngIf test"></div>', [ngIf])),
              [
                [EmbeddedTemplateAst],
                [DirectiveAst, ngIf],
                [BoundDirectivePropertyAst, 'ngIf', 'test'],
                [ElementAst, 'div']
              ]);
        });

        test('should parse variables via #... and report them as deprecated',
            () {
          expect(humanizeTplAst(parse('<div *ngIf="#a=b"></div>', [])), [
            [EmbeddedTemplateAst],
            [VariableAst, 'a', 'b'],
            [ElementAst, 'div']
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.WARNING: "#" inside of expressions is deprecated. Use "let" instead!\n'
                  '*ngIf="#a=b"\n'
                  '^^^^^^^^^^^^'
            ].join('\n')
          ]);
        });

        test('should parse variables via var ... and report them as deprecated',
            () {
          expect(humanizeTplAst(parse('<div *ngIf="var a=b"></div>', [])), [
            [EmbeddedTemplateAst],
            [VariableAst, 'a', 'b'],
            [ElementAst, 'div']
          ]);
          expect(console.warnings, [
            [
              'Template parse warnings:\n'
                  'line 1, column 6 of TestComp: ParseErrorLevel.WARNING: "var" inside of expressions is deprecated. Use "let" instead!\n'
                  '*ngIf="var a=b"\n'
                  '^^^^^^^^^^^^^^^'
            ].join('\n')
          ]);
        });

        test('should parse variables via let ...', () {
          expect(humanizeTplAst(parse('<div *ngIf="let a=b"></div>', [])), [
            [EmbeddedTemplateAst],
            [VariableAst, 'a', 'b'],
            [ElementAst, 'div']
          ]);
        });

        group('directives', () {
          test('should locate directives in property bindings', () {
            var dirA = createCompileDirectiveMetadata(
                selector: '[a=b]',
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: 'DirA'),
                inputs: ['a']);
            var dirB = createCompileDirectiveMetadata(
                selector: '[b]',
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: 'DirB'));
            expect(
                humanizeTplAst(
                    parse('<div template="a b" b></div>', [dirA, dirB])),
                [
                  [EmbeddedTemplateAst],
                  [DirectiveAst, dirA],
                  [BoundDirectivePropertyAst, 'a', 'b'],
                  [ElementAst, 'div'],
                  [AttrAst, 'b', ''],
                  [DirectiveAst, dirB]
                ]);
          });

          test('should not locate directives in variables', () {
            var dirA = createCompileDirectiveMetadata(
                selector: '[a]',
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: 'DirA'));
            expect(
                humanizeTplAst(parse('<div template="let a=b"></div>', [dirA])),
                [
                  [EmbeddedTemplateAst],
                  [VariableAst, 'a', 'b'],
                  [ElementAst, 'div']
                ]);
          });

          test('should not locate directives in references', () {
            var dirA = createCompileDirectiveMetadata(
                selector: '[a]',
                type: new CompileTypeMetadata(
                    moduleUrl: someModuleUrl, name: 'DirA'));
            expect(humanizeTplAst(parse('<div ref-a></div>', [dirA])), [
              [ElementAst, 'div'],
              [ReferenceAst, 'a', null]
            ]);
          });
        });

        test(
            'should work with *... and use the attribute name as '
            'property binding name', () {
          expect(humanizeTplAst(parse('<div *ngIf="test"></div>', [ngIf])), [
            [EmbeddedTemplateAst],
            [DirectiveAst, ngIf],
            [BoundDirectivePropertyAst, 'ngIf', 'test'],
            [ElementAst, 'div']
          ]);
        });

        test('should work with *... and empty value', () {
          expect(humanizeTplAst(parse('<div *ngIf></div>', [ngIf])), [
            [EmbeddedTemplateAst],
            [DirectiveAst, ngIf],
            [BoundDirectivePropertyAst, 'ngIf', 'null'],
            [ElementAst, 'div']
          ]);
        });
      }, skip: 'Don\'t support inline templates yet.');
    });

    group('content projection', () {
      var compCounter;
      setUp(() {
        compCounter = 0;
      });

      CompileDirectiveMetadata createComp(
          String selector, List<String> ngContentSelectors) {
        return createCompileDirectiveMetadata(
            selector: selector,
            metadataType: CompileDirectiveMetadataType.Component,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl,
                name: '''SomeComp${ compCounter ++}'''),
            template: new CompileTemplateMetadata(
                ngContentSelectors: ngContentSelectors));
      }

      CompileDirectiveMetadata createDir(String selector) {
        return createCompileDirectiveMetadata(
            selector: selector,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl,
                name: '''SomeDir${ compCounter ++}'''));
      }

      group('project text nodes', () {
        test('should project text nodes with wildcard selector', () {
          expect(
              humanizeContentProjection(parse('<div>hello</div>', [
                createComp('div', ['*'])
              ])),
              [
                ['div', null],
                ['#text(hello)', 0]
              ]);
        });
      });

      group('project elements', () {
        test('should project elements with wildcard selector', () {
          expect(
              humanizeContentProjection(parse('<div><span></span></div>', [
                createComp('div', ['*'])
              ])),
              [
                ['div', null],
                ['span', 0]
              ]);
        });

        test('should project elements with css selector', () {
          expect(
              humanizeContentProjection(parse('<div><a x></a><b></b></div>', [
                createComp('div', ['a[x]'])
              ])),
              [
                ['div', null],
                ['a', 0],
                ['b', null]
              ]);
        });
      });

      group('embedded templates', () {
        test('should project embedded templates with wildcard selector', () {
          expect(
              humanizeContentProjection(
                  parse('<div><template></template></div>', [
                createComp('div', ['*'])
              ])),
              [
                ['div', null],
                ['template', 0]
              ]);
        });

        test('should project embedded templates with css selector', () {
          expect(
              humanizeContentProjection(parse(
                  '<div><template x></template><template></template></div>', [
                createComp('div', ['template[x]'])
              ])),
              [
                ['div', null],
                ['template', 0],
                ['template', null]
              ]);
        });
      });

      group('ng-content', () {
        test('should project ng-content with wildcard selector', () {
          expect(
              humanizeContentProjection(
                  parse('<div><ng-content></ng-content></div>', [
                createComp('div', ['*'])
              ])),
              [
                ['div', null],
                ['ng-content', 0]
              ]);
        });

        test('should project ng-content with css selector', () {
          expect(
              humanizeContentProjection(parse(
                  '<div><ng-content x></ng-content><ng-content></ng-content></div>',
                  [
                    createComp('div', ['ng-content[x]'])
                  ])),
              [
                ['div', null],
                ['ng-content', 0],
                ['ng-content', null]
              ]);
        });
      });

      test('should project into the first matching ng-content', () {
        expect(
            humanizeContentProjection(parse('<div>hello<b></b><a></a></div>', [
              createComp('div', ['a', 'b', '*'])
            ])),
            [
              ['div', null],
              ['#text(hello)', 2],
              ['b', 1],
              ['a', 0]
            ]);
      });

      test('should project into wildcard ng-content last', () {
        expect(
            humanizeContentProjection(parse('<div>hello<a></a></div>', [
              createComp('div', ['*', 'a'])
            ])),
            [
              ['div', null],
              ['#text(hello)', 0],
              ['a', 1]
            ]);
      });

      test('should only project direct child nodes', () {
        expect(
            humanizeContentProjection(
                parse('<div><span><a></a></span><a></a></div>', [
              createComp('div', ['a'])
            ])),
            [
              ['div', null],
              ['span', null],
              ['a', null],
              ['a', 0]
            ]);
      });

      test('should project nodes of nested components', () {
        expect(
            humanizeContentProjection(parse('<a><b>hello</b></a>', [
              createComp('a', ['*']),
              createComp('b', ['*'])
            ])),
            [
              ['a', null],
              ['b', 0],
              ['#text(hello)', 0]
            ]);
      });

      test('should project children of components with ngNonBindable', () {
        expect(
            humanizeContentProjection(
                parse('<div ngNonBindable>{{hello}}<span></span></div>', [
              createComp('div', ['*'])
            ])),
            [
              ['div', null],
              ['#text({{hello}})', 0],
              ['span', 0]
            ]);
      });

      test('should match the element when there is an inline template', () {
        expect(
            humanizeContentProjection(parse('<div><b *ngIf="cond"></b></div>', [
              createComp('div', ['a', 'b']),
              ngIf
            ])),
            [
              ['div', null],
              ['template', 1],
              ['b', null]
            ]);
      });

      group('ngProjectAs', () {
        test('should override elements', () {
          expect(
              humanizeContentProjection(
                  parse('<div><a ngProjectAs="b"></a></div>', [
                createComp('div', ['a', 'b'])
              ])),
              [
                ['div', null],
                ['a', 1]
              ]);
        });

        test('should override <ng-content>', () {
          expect(
              humanizeContentProjection(parse(
                  '<div><ng-content ngProjectAs="b"></ng-content></div>', [
                createComp('div', ['ng-content', 'b'])
              ])),
              [
                ['div', null],
                ['ng-content', 1]
              ]);
        });

        test('should override <template>', () {
          expect(
              humanizeContentProjection(
                  parse('<div><template ngProjectAs="b"></template></div>', [
                createComp('div', ['template', 'b'])
              ])),
              [
                ['div', null],
                ['template', 1]
              ]);
        });

        test('should override inline templates', () {
          expect(
              humanizeContentProjection(
                  parse('<div><a *ngIf="cond" ngProjectAs="b"></a></div>', [
                createComp('div', ['a', 'b']),
                ngIf
              ])),
              [
                ['div', null],
                ['template', 1],
                ['a', null]
              ]);
        });
      });

      test('should support other directives before the component', () {
        expect(
            humanizeContentProjection(parse('<div>hello</div>', [
              createDir('div'),
              createComp('div', ['*'])
            ])),
            [
              ['div', null],
              ['#text(hello)', 0]
            ]);
      });
    }, skip: 'Don\'t support content projection yet.');

    group('error cases', () {
      test('should report when ng-content has content', () {
        expect(
            () => parse('<ng-content>content</ng-content>', []),
            throwsWith('Template parse errors:\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: <ng-content> element cannot have content. <ng-content> must be immediately followed by </ng-content>\n'
                '<ng-content>\n'
                '^^^^^^^^^^^^'));
      });

      test('should report invalid property names', () {
        expect(
            () => parse('<div [invalidProp]></div>', []),
            throwsWith('Template parse errors:\n'
                'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: Can\'t bind to \'invalidProp\' since it isn\'t a known native property or known directive. Please fix typo or add to directives list.\n'
                '[invalidProp]\n'
                '^^^^^^^^^^^^^'));
      });

      test('should report errors in expressions', () {
        expect(
            () => parse('<div [prop]="a b"></div>', []),
            throwsWith('Template parse errors:\n'
                'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: Parser Error: Unexpected token \'b\' at column 3 in [a b] in <FileLocation: 5 TestComp:1:6>\n'
                '[prop]="a b"\n'
                '^^^^^^^^^^^^'));
      });

      test(
          'should not throw on invalid property names if the property is '
          'used by a directive', () {
        var dirA = createCompileDirectiveMetadata(
            selector: 'div',
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirA'),
            inputs: ['invalidProp']);
        // Should not throw:
        parse('<div [invalid-prop]></div>', [dirA]);
      });

      test('should not allow more than 1 component per element', () {
        var dirA = createCompileDirectiveMetadata(
            selector: 'div',
            metadataType: CompileDirectiveMetadataType.Component,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirA'),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        var dirB = createCompileDirectiveMetadata(
            selector: 'div',
            metadataType: CompileDirectiveMetadataType.Component,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirB'),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse('<div>', [dirB, dirA]),
            throwsWith('Template parse errors:\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: More than one component: DirB,DirA\n'
                '<div>\n'
                '^^^^^'));
      });

      test(
          'should not allow components or element bindings nor dom events '
          'on explicit embedded templates', () {
        var dirA = createCompileDirectiveMetadata(
            selector: '[a]',
            metadataType: CompileDirectiveMetadataType.Component,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirA'),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse('<template [a]="b" (e)="f"></template>', [dirA]),
            throwsWith('Template parse errors:\n'
                'line 1, column 19 of TestComp: ParseErrorLevel.FATAL: Event binding e not emitted by any directive on an embedded template\n'
                '(e)="f"\n'
                '^^^^^^^\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: Components on an embedded template: DirA\n'
                '<template [a]="b" (e)="f">\n'
                '^^^^^^^^^^^^^^^^^^^^^^^^^^\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: Property binding a not used by any directive on an embedded template\n'
                '<template [a]="b" (e)="f">\n'
                '^^^^^^^^^^^^^^^^^^^^^^^^^^'));
      });

      test(
          'should not allow components or element bindings on inline '
          'embedded templates', () {
        var dirA = createCompileDirectiveMetadata(
            selector: '[a]',
            metadataType: CompileDirectiveMetadataType.Component,
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirA'),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            () => parse('<div *a="b"></div>', [dirA]),
            throwsWith('Template parse errors:\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: Components on an embedded template: DirA\n'
                '<div *a="b">\n'
                '^^^^^^^^^^^^\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: Property binding a not used by any directive on an embedded template\n'
                '<div *a="b">\n'
                '^^^^^^^^^^^^'));
      });

      test('should prevent binding event attributes', () async {
        final template = '<div [attr.onclick]="onClick()"></div>';
        expect(
            () => parse(template, []),
            throwsWith('Template parse errors:\n'
                'line 1, column 6 of TestComp: ParseErrorLevel.FATAL: '
                'Binding to event attribute \'onclick\' is disallowed for '
                'security reasons, please use (click)=...\n'
                '[attr.onclick]="onClick()"\n'
                '^^^^^^^^^^^^^^^^^^^^^^^^^^'));
      });

      test('should prevent binding to unsafe SVG attributes', () async {
        // This test requires that DomElementSchemaRegistry is used instead
        // of a mock implementation of ElementSchemaRegistry.
        setUpParser(elementSchemaRegistry: new DomElementSchemaRegistry());
        final template = '<svg:circle [xlink:href]="url"></svg:circle>';
        expect(
            () => parse(template, []),
            throwsWith('Template parse errors:\n'
                'line 1, column 13 of TestComp: ParseErrorLevel.FATAL: '
                "Can't bind to 'xlink:href' since it isn't a known native "
                'property or known directive. Please fix typo or add to '
                'directives list.\n'
                '[xlink:href]="url"\n'
                '^^^^^^^^^^^^^^^^^^'));
      });
    }, skip: 'Don\'t support error cases yet.');

    group('ignore elements', () {
      test('should ignore <script> elements', () {
        expect(humanizeTplAst(parse('<script></script>a', [])), [
          [TextAst, 'a']
        ]);
      });

      test('should ignore <style> elements', () {
        expect(humanizeTplAst(parse('<style></style>a', [])), [
          [TextAst, 'a']
        ]);
      });

      group('<link rel="stylesheet">', () {
        test(
            'should keep <link rel="stylesheet"> elements if they '
            'have an absolute non package: url', () {
          expect(
              humanizeTplAst(
                  parse('<link rel="stylesheet" href="http://someurl">a', [])),
              [
                [ElementAst, 'link'],
                [AttrAst, 'rel', 'stylesheet'],
                [AttrAst, 'href', 'http://someurl'],
                [TextAst, 'a']
              ]);
        });

        test(
            'should keep <link rel="stylesheet"> elements if they '
            'have no uri', () {
          expect(humanizeTplAst(parse('<link rel="stylesheet">a', [])), [
            [ElementAst, 'link'],
            [AttrAst, 'rel', 'stylesheet'],
            [TextAst, 'a']
          ]);
          expect(humanizeTplAst(parse('<link REL="stylesheet">a', [])), [
            [ElementAst, 'link'],
            [AttrAst, 'REL', 'stylesheet'],
            [TextAst, 'a']
          ]);
        });

        test(
            'should ignore <link rel="stylesheet"> elements if they have '
            'a relative uri', () {
          expect(
              humanizeTplAst(
                  parse('<link rel="stylesheet" href="./other.css">a', [])),
              [
                [TextAst, 'a']
              ]);
          expect(
              humanizeTplAst(
                  parse('<link rel="stylesheet" HREF="./other.css">a', [])),
              [
                [TextAst, 'a']
              ]);
        });

        test(
            'should ignore <link rel="stylesheet"> elements if they '
            'have a package: uri', () {
          expect(
              humanizeTplAst(parse(
                  '<link rel="stylesheet" href="package:somePackage">a', [])),
              [
                [TextAst, 'a']
              ]);
        });
      });

      test('should ignore bindings on children of elements with ngNonBindable',
          () {
        expect(humanizeTplAst(parse('<div ngNonBindable>{{b}}</div>', [])), [
          [ElementAst, 'div'],
          [AttrAst, 'ngNonBindable', ''],
          [TextAst, '{{b}}']
        ]);
      });

      test('should keep nested children of elements with ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse('<div ngNonBindable><span>{{b}}</span></div>', [])),
            [
              [ElementAst, 'div'],
              [AttrAst, 'ngNonBindable', ''],
              [ElementAst, 'span'],
              [TextAst, '{{b}}']
            ]);
      });

      test(
          'should ignore <script> elements inside of elements with '
          'ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse('<div ngNonBindable><script></script>a</div>', [])),
            [
              [ElementAst, 'div'],
              [AttrAst, 'ngNonBindable', ''],
              [TextAst, 'a']
            ]);
      });

      test(
          'should ignore <style> elements inside of elements with '
          'ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse('<div ngNonBindable><style></style>a</div>', [])),
            [
              [ElementAst, 'div'],
              [AttrAst, 'ngNonBindable', ''],
              [TextAst, 'a']
            ]);
      });

      test(
          'should ignore <link rel="stylesheet"> elements inside of '
          'elements with ngNonBindable', () {
        expect(
            humanizeTplAst(
                parse('<div ngNonBindable><link rel="stylesheet">a</div>', [])),
            [
              [ElementAst, 'div'],
              [AttrAst, 'ngNonBindable', ''],
              [TextAst, 'a']
            ]);
      });

      test(
          'should convert <ng-content> elements into regular elements '
          'inside of elements with ngNonBindable', () {
        expect(
            humanizeTplAst(parse(
                '<div ngNonBindable><ng-content></ng-content>a</div>', [])),
            [
              [ElementAst, 'div'],
              [AttrAst, 'ngNonBindable', ''],
              [ElementAst, 'ng-content'],
              [TextAst, 'a']
            ]);
      });
    });

    group('source spans', () {
      test('should support ng-content', () {
        var parsed = parse('<ng-content select="a"></ng-content>', []);
        expect(humanizeTplAstSourceSpans(parsed), [
          [NgContentAst, '<ng-content select="a">']
        ]);
      });

      test('should support embedded template', () {
        expect(humanizeTplAstSourceSpans(parse('<template></template>', [])), [
          [EmbeddedTemplateAst, '<template>']
        ]);
      });

      test('should support element and attributes', () {
        expect(
            humanizeTplAstSourceSpans(parse('<div key="value"></div>', [])), [
          [ElementAst, 'div', '<div key="value">'],
          [AttrAst, 'key', 'value', 'key="value"']
        ]);
      });

      test('should support references', () {
        expect(humanizeTplAstSourceSpans(parse('<div #a></div>', [])), [
          [ElementAst, 'div', '<div #a>'],
          [ReferenceAst, 'a', null, '#a']
        ]);
      });

      test('should support variables', () {
        expect(
            humanizeTplAstSourceSpans(
                parse('<template let-a="b"></template>', [])),
            [
              [EmbeddedTemplateAst, '<template let-a="b">'],
              [VariableAst, 'a', 'b', 'let-a="b"']
            ]);
      });

      test('should support element property', () {
        expect(
            humanizeTplAstSourceSpans(parse('<div [someProp]="v"></div>', [])),
            [
              [ElementAst, 'div', '<div [someProp]="v">'],
              [
                BoundElementPropertyAst,
                PropertyBindingType.Property,
                'someProp',
                'v',
                null,
                '[someProp]="v"'
              ]
            ]);
      });

      test('should support bound text', () {
        expect(humanizeTplAstSourceSpans(parse('{{a}}', [])), [
          [BoundTextAst, '{{ a }}', '{{a}}']
        ]);
      });

      test('should support text nodes', () {
        expect(humanizeTplAstSourceSpans(parse('a', [])), [
          [TextAst, 'a', 'a']
        ]);
      });

      test('should support directive', () {
        var dirA = createCompileDirectiveMetadata(
            selector: '[a]',
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: 'DirA'));
        var comp = createCompileDirectiveMetadata(
            selector: 'div',
            metadataType: CompileDirectiveMetadataType.Component,
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: 'ZComp'),
            template: new CompileTemplateMetadata(ngContentSelectors: []));
        expect(
            humanizeTplAstSourceSpans(parse('<div a></div>', [dirA, comp])), [
          [ElementAst, 'div', '<div a>'],
          [AttrAst, 'a', '', 'a'],
          [DirectiveAst, dirA, '<div a>'],
          [DirectiveAst, comp, '<div a>']
        ]);
      }, skip: 'Don\'t yet support directives.');

      test('should support directive in namespace', () {
        var tagSel = createCompileDirectiveMetadata(
            selector: 'circle',
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: 'elDir'));
        var attrSel = createCompileDirectiveMetadata(
            selector: '[href]',
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: 'attrDir'));
        expect(
            humanizeTplAstSourceSpans(parse(
                '<svg><circle /><use xlink:href="Port" /></svg>',
                [tagSel, attrSel])),
            [
              [ElementAst, '@svg:svg', '<svg>'],
              [ElementAst, '@svg:circle', '<circle />'],
              [DirectiveAst, tagSel, '<circle />'],
              [ElementAst, '@svg:use', '<use xlink:href="Port" />'],
              [AttrAst, '@xlink:href', 'Port', 'xlink:href="Port"'],
              [DirectiveAst, attrSel, '<use xlink:href="Port" />']
            ]);
      }, skip: 'Don\'t yet support namespaces.');

      test('should support directive property', () {
        var dirA = createCompileDirectiveMetadata(
            selector: 'div',
            type:
                new CompileTypeMetadata(moduleUrl: someModuleUrl, name: 'DirA'),
            inputs: ['aProp']);
        expect(
            humanizeTplAstSourceSpans(
                parse('<div [aProp]="foo"></div>', [dirA])),
            [
              [ElementAst, 'div', '<div [aProp]="foo">'],
              [DirectiveAst, dirA, '<div [aProp]="foo">'],
              [BoundDirectivePropertyAst, 'aProp', 'foo', '[aProp]="foo"']
            ]);
      }, skip: 'Don\'t yet support directives.');
    });

    group('pipes', () {
      test('should allow pipes that have been defined as dependencies', () {
        var testPipe = new CompilePipeMetadata(
            name: 'test',
            type: new CompileTypeMetadata(
                moduleUrl: someModuleUrl, name: 'DirA'));
        // Should not throw.
        parse('{{a | test}}', [], [testPipe]);
      });

      test(
          'should report pipes as error that have not been defined '
          'as dependencies', () {
        expect(
            () => parse('{{a | test}}', []),
            throwsWith('Template parse errors:\n'
                'line 1, column 1 of TestComp: ParseErrorLevel.FATAL: The pipe \'test\' could not be found\n'
                '{{a | test}}\n'
                '^^^^^^^^^^^^'));
      }, skip: 'Don\'t handle errors yet.');
    });

    group('deferred', () {
      test('should successfully parse', () {
        expect(
            humanizeTplAstSourceSpans(
                parse('<component @deferred></component>', [])),
            [
              [EmbeddedTemplateAst, '<component @deferred>'],
              [ElementAst, 'component', '<component @deferred>']
            ]);
      }, skip: 'angular_ast doesn\'t handle @deferred yet.');

      test('should report invalid binding', () {
        expect(
            () => parse('<component @deferred="true"></component>', []),
            throwsWith('Template parse errors:\n'
                'line 1, column 12 of TestComp: ParseErrorLevel.FATAL: '
                '"@deferred" on elements can\'t be bound to an expression.'));
      }, skip: 'Re-enable. Does not throw.');
    });
  });
}

CompileDirectiveMetadata createCompileDirectiveMetadata({
  CompileTypeMetadata type,
  CompileDirectiveMetadataType metadataType,
  String selector,
  String exportAs,
  List<String> inputs,
  List<String> outputs,
  Map<String, String> host,
  // CompileProviderMetadata | CompileTypeMetadata |
  // CompileIdentifierMetadata | List
  List providers,
  // CompileProviderMetadata | CompileTypeMetadata |
  // CompileIdentifierMetadata | List
  List viewProviders,
  List<CompileQueryMetadata> queries,
  CompileTemplateMetadata template,
}) {
  final hostListeners = <String, String>{};
  final hostProperties = <String, String>{};
  final hostAttributes = <String, String>{};
  CompileDirectiveMetadata.deserializeHost(
      host, hostAttributes, hostListeners, hostProperties);

  final inputsMap = <String, String>{};
  final inputTypeMap = <String, CompileTypeMetadata>{};
  inputs?.forEach((input) {
    final inputParts = input.split(';');
    final inputName = inputParts[0];
    final bindingParts = splitAtColon(inputName, [inputName, inputName]);
    inputsMap[bindingParts[0]] = bindingParts[1];
    if (inputParts.length > 1) {
      inputTypeMap[bindingParts[0]] =
          new CompileTypeMetadata(name: inputParts[1]);
    }
  });

  final outputsMap = <String, String>{};
  outputs?.forEach((output) {
    final bindingParts = splitAtColon(output, [output, output]);
    outputsMap[bindingParts[0]] = bindingParts[1];
  });

  return new CompileDirectiveMetadata(
    type: type,
    metadataType: metadataType ?? CompileDirectiveMetadataType.Directive,
    selector: selector,
    exportAs: exportAs,
    inputs: inputsMap,
    inputTypes: inputTypeMap,
    outputs: outputsMap,
    hostListeners: hostListeners,
    hostProperties: hostProperties,
    hostAttributes: hostAttributes,
    lifecycleHooks: [],
    providers: providers,
    viewProviders: viewProviders,
    queries: queries,
    template: template,
  );
}
