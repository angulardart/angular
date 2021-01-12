// @dart=2.9

import 'package:test/test.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/expression_parser/parser.dart';
import 'package:angular_compiler/v1/src/compiler/schema/dom_element_schema_registry.dart';
import 'package:angular_compiler/v1/src/compiler/template_ast.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/compiler/template_parser/ast_template_parser.dart';
import 'package:angular_compiler/v2/context.dart';

import '../resolve_util.dart';
import 'template_humanizer_util.dart';

void main() {
  CompileContext.overrideForTesting();

  final expressionParser = ExpressionParser();
  final schemaRegistry = DomElementSchemaRegistry();
  final templateParser = AstTemplateParser(
    schemaRegistry,
    expressionParser,
    CompilerFlags(),
  );

  List<Object> getHumanizedTemplate(
    NormalizedComponentWithViewDirectives component,
  ) {
    final componentMetadata = component.component;
    final templateAsts = templateParser.parse(
      componentMetadata,
      componentMetadata.template.template,
      component.directives,
      [],
      null,
      componentMetadata.template.templateUrl,
    );
    return humanizeTplAst(templateAsts);
  }

  group('variable assigned NgFor locals', () {
    test('should be typed', () async {
      final component = await resolveAndFindComponent("""
        @Component(
          selector: 'app',
          template: '<div *ngFor="let value of values; let i=index; let length=count; let isFirst=first; let isLast=last; let isEven=even; let isOdd=odd"></div>',
          directives: const [NgFor],
        )
        class AppComponent {
          List<String> values;
        }""");
      final template = getHumanizedTemplate(component);
      expect(template, [
        [EmbeddedTemplateAst],
        [AttrAst, 'ngFor', ''],
        [VariableAst, 'value', r'$implicit', 'String'],
        [VariableAst, 'i', 'index', 'int'],
        [VariableAst, 'length', 'count', 'int'],
        [VariableAst, 'isFirst', 'first', 'bool'],
        [VariableAst, 'isLast', 'last', 'bool'],
        [VariableAst, 'isEven', 'even', 'bool'],
        [VariableAst, 'isOdd', 'odd', 'bool'],
        [DirectiveAst, component.directives.first], // NgFor
        [BoundDirectivePropertyAst, 'ngForOf', 'values'],
        [ElementAst, 'div'],
      ]);
    });

    test('should be typed dynamic if bound type is private', () async {
      final component = await resolveAndFindComponent("""
        @Component(
          selector: 'app',
          template: '<div *ngFor="let value of values"></div>',
          directives: const [NgFor],
        )
        class AppComponent {
          List<_Value> values;
        }

        class _Value {}""");
      final template = getHumanizedTemplate(component);
      expect(template, [
        [EmbeddedTemplateAst],
        [AttrAst, 'ngFor', ''],
        [VariableAst, 'value', r'$implicit', 'dynamic'],
        [DirectiveAst, component.directives.first], // NgFor
        [BoundDirectivePropertyAst, 'ngForOf', 'values'],
        [ElementAst, 'div'],
      ]);
    });

    test('should be typed if bound expression has receiver', () async {
      final component = await resolveAndFindComponent("""
        @Component(
          selector: 'app',
          template: '<div *ngFor="let value of values.reversed"></div>',
          directives: const [NgFor],
        )
        class AppComponent {
          List<int> values;
        }""");
      final template = getHumanizedTemplate(component);
      expect(template, [
        [EmbeddedTemplateAst],
        [AttrAst, 'ngFor', ''],
        [VariableAst, 'value', r'$implicit', 'int'],
        [DirectiveAst, component.directives.first], // NgFor
        [BoundDirectivePropertyAst, 'ngForOf', 'values.reversed'],
        [ElementAst, 'div'],
      ]);
    });
  });
}
