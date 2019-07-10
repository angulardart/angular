import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/angular_ast_extraction.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/lazy/component.dart' as lazy;
import 'package:angular_analyzer_plugin/src/model/lazy/directive.dart' as lazy;
import 'package:angular_analyzer_plugin/src/model/lazy/pipe.dart' as lazy;
import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_ast/angular_ast.dart';
import 'package:test/test.dart';
import 'package:matcher/matcher.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'angular_driver_base.dart';

// ignore_for_file: deprecated_member_use

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngularParseHtmlTest);
    defineReflectiveTests(BuildStandardHtmlComponentsTest);
    defineReflectiveTests(BuildStandardHtmlTest);
    defineReflectiveTests(BuildStandardAngularTest);
    defineReflectiveTests(BuildSyntacticModelTest);
    defineReflectiveTests(ResolveDartTemplatesTest);
    defineReflectiveTests(BuildResolvedModelTest);
    defineReflectiveTests(ResolveHtmlTemplatesTest);
    defineReflectiveTests(ResolveHtmlTemplateTest);
  });
}

@reflectiveTest
class AngularParseHtmlTest extends AngularDriverTestBase {
  // ignore: non_constant_identifier_names
  void test_perform() {
    final code = r'''
<!DOCTYPE html>
<html>
  <head>
    <title> test page </title>
  </head>
  <body>
    <h1 myAttr='my value'>Test</h1>
  </body>
</html>
    ''';
    final source = newSource('/test.html', code);
    final tplParser = TemplateParser()..parse(code, source);
    expect(tplParser.parseErrors, isEmpty);
    // HTML_DOCUMENT
    {
      final asts = tplParser.rawAst;
      expect(asts, isNotNull);
      // verify that attributes are not lower-cased
      final element = asts[1].childNodes[3].childNodes[1] as ElementAst;
      expect(element.attributes.length, 1);
      expect(element.attributes[0].name, 'myAttr');
      expect(element.attributes[0].value, 'my value');
    }
  }

  // ignore: non_constant_identifier_names
  void test_perform_noDocType() {
    final code = r'''
<div>AAA</div>
<span>BBB</span>
''';
    final source = newSource('/test.html', code);
    final tplParser = TemplateParser()..parse(code, source);
    // validate Document
    {
      final asts = tplParser.rawAst;
      expect(asts, isNotNull);
      expect(asts.length, 4);
      expect((asts[0] as ElementAst).name, 'div');
      expect((asts[2] as ElementAst).name, 'span');
    }
    // it's OK to don't have DOCTYPE
    expect(tplParser.parseErrors, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_perform_noDocType_with_dangling_unclosed_tag() {
    final code = r'''
<div>AAA</div>
<span>BBB</span>
<di''';
    final source = newSource('/test.html', code);
    final tplParser = TemplateParser()..parse(code, source);
    // quick validate Document
    {
      final asts = tplParser.rawAst;
      expect(asts, isNotNull);
      expect(asts.length, 5);
      expect((asts[0] as ElementAst).name, 'div');
      expect((asts[2] as ElementAst).name, 'span');
      expect((asts[4] as ElementAst).name, 'di');
    }
  }
}

@reflectiveTest
class BuildResolvedModelTest extends AngularDriverTestBase {
  List<DirectiveBase> directives;
  List<Template> templates;
  List<Pipe> pipes;
  List<AnalysisError> errors;

  // ignore: non_constant_identifier_names
  Future getDirectives(final Source source) async {
    final dartResult = await dartDriver.getResult(source.fullName);
    fillErrorListener(dartResult.errors);
    final ngResult = await angularDriver.requestDartResult(source.fullName);
    directives = ngResult.directives;
    errors = ngResult.errors;
    pipes = ngResult.pipes;
    fillErrorListener(errors);
    templates = directives
        .map((d) => d is Component ? d.template : null)
        .where((d) => d != null)
        .toList();
  }

  // ignore: non_constant_identifier_names
  Future test_Component() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'comp-a', template:'')
class ComponentA {
}

@Component(selector: 'comp-b', template:'')
class ComponentB {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(2));
    {
      final component = directives[0];
      expect(component, isA<Component>());
      {
        final selector = component.selector;
        expect(selector, isA<ElementNameSelector>());
        expect(selector.toString(), 'comp-a');
      }
    }
    {
      final component = directives[1];
      expect(component, isA<Component>());
      {
        final selector = component.selector;
        expect(selector, isA<ElementNameSelector>());
        expect(selector.toString(), 'comp-b');
      }
    }
  }

  // ignore: non_constant_identifier_names
  Future test_Directive() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Directive(selector: 'dir-a')
class DirectiveA {
}

@Directive(selector: 'dir-b')
class DirectiveB {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(2));
    {
      final directive = directives[0];
      expect(directive, isA<Directive>());
      {
        final selector = directive.selector;
        expect(selector, isA<ElementNameSelector>());
        expect(selector.toString(), 'dir-a');
      }
    }
    {
      final directive = directives[1];
      expect(directive, isA<Directive>());
      {
        final selector = directive.selector;
        expect(selector, isA<ElementNameSelector>());
        expect(selector.toString(), 'dir-b');
      }
    }
  }

  // ignore: non_constant_identifier_names
  Future test_exportAs_Component() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', exportAs: 'export-name', template:'')
class ComponentA {
}

@Component(selector: 'bbb', template:'')
class ComponentB {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(directives, hasLength(2));
    {
      final component = getComponentByName(directives, 'ComponentA');
      {
        final exportAs = component.exportAs;
        expect(exportAs.string, 'export-name');
        expect(exportAs.navigationRange.offset, code.indexOf('export-name'));
      }
    }
    {
      final component = getComponentByName(directives, 'ComponentB');
      {
        final exportAs = component.exportAs;
        expect(exportAs, isNull);
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_exportAs_constantStringExpressionOk() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', exportAs: 'a' + 'b', template:'')
class ComponentA {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(1));
    // has no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_exportAs_Directive() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]', exportAs: 'export-name')
class DirectiveA {
}

@Directive(selector: '[bbb]')
class DirectiveB {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(directives, hasLength(2));
    {
      final directive = getDirectiveByName(directives, 'DirectiveA');
      {
        final exportAs = directive.exportAs;
        expect(exportAs.string, 'export-name');
        expect(exportAs.navigationRange.offset, code.indexOf('export-name'));
      }
    }
    {
      final directive = getDirectiveByName(directives, 'DirectiveB');
      {
        final exportAs = directive.exportAs;
        expect(exportAs, isNull);
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_exportAs_hasError_notStringValue() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', exportAs: 42, template:'')
class ComponentA {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(1));
    // has an error
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      AngularWarningCode.STRING_VALUE_EXPECTED,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_finalPropertyInputError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '<p></p>')
class MyComponent {
  @Input() final int immutable = 1;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
        code,
        "immutable");
  }

  // ignore: non_constant_identifier_names
  Future test_finalPropertyInputErrorNonDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

class MyNonDirective {
  @Input() final int immutable = 1;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
        code,
        "immutable");
  }

  // ignore: non_constant_identifier_names
  Future test_FunctionalDirective() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Directive(selector: 'dir-a.myClass[myAttr]')
void directiveA() {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(1));
    final directive = directives.single;
    expect(directive, isA<FunctionalDirective>());
    final selector = directive.selector;
    expect(selector, isA<AndSelector>());
    expect((selector as AndSelector).selectors, hasLength(3));
  }

  // ignore: non_constant_identifier_names
  Future test_FunctionalDirective_notAllowedValues() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Directive(selector: 'dir-a.myClass[myAttr]',
  exportAs: 'foo')
void directiveA() {
}
''');
    await getDirectives(source);
    errorListener.assertErrorsWithCodes(
        [AngularWarningCode.FUNCTIONAL_DIRECTIVES_CANT_BE_EXPORTED]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildChildrenNoRangeNotRecorded() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren()
  List<ContentChildComp> contentChildren;
  @ContentChild()
  ContentChildComp contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first;
    final childrenFields = component.contentChildrenFields;
    expect(childrenFields, hasLength(0));
    final childFields = component.contentChildFields;
    expect(childFields, hasLength(0));
    // validate
    errorListener.assertErrorsWithCodes([
      CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS,
      CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildChildrenSetter() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp) // 1
  void set contentChild(ContentChildComp contentChild) => null;
  @ContentChildren(ContentChildComp) // 2
  void set contentChildren(List<ContentChildComp> contentChildren) => null;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first;

    final childFields = component.contentChildFields;
    expect(childFields, hasLength(1));
    final child = childFields.first;
    expect(child.fieldName, equals("contentChild"));
    expect(
        child.nameRange.offset, equals(code.indexOf("ContentChildComp) // 1")));
    expect(child.nameRange.length, equals("ContentChildComp".length));
    expect(child.typeRange.offset, equals(code.indexOf("ContentChildComp ")));
    expect(child.typeRange.length, equals("ContentChildComp".length));

    final childrenFields = component.contentChildrenFields;
    expect(childrenFields, hasLength(1));
    final children = childrenFields.first;
    expect(children.fieldName, equals("contentChildren"));
    expect(children.nameRange.offset,
        equals(code.indexOf("ContentChildComp) // 2")));
    expect(children.nameRange.length, equals("ContentChildComp".length));
    expect(children.typeRange.offset,
        equals(code.indexOf("List<ContentChildComp>")));
    expect(children.typeRange.length, equals("List<ContentChildComp>".length));

    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp)
  ContentChildComp contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first;
    final childFields = component.contentChildFields;
    expect(childFields, hasLength(1));
    final child = childFields.first;
    expect(child.fieldName, equals("contentChild"));
    expect(child.nameRange.offset, equals(code.indexOf("ContentChildComp)")));
    expect(child.nameRange.length, equals("ContentChildComp".length));
    expect(child.typeRange.offset, equals(code.indexOf("ContentChildComp ")));
    expect(child.typeRange.length, equals("ContentChildComp".length));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  List<ContentChildComp> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first;
    final childrenFields = component.contentChildrenFields;
    expect(childrenFields, hasLength(1));
    final children = childrenFields.first;
    expect(children.fieldName, equals("contentChildren"));
    expect(
        children.nameRange.offset, equals(code.indexOf("ContentChildComp)")));
    expect(children.nameRange.length, equals("ContentChildComp".length));
    expect(children.typeRange.offset,
        equals(code.indexOf("List<ContentChildComp>")));
    expect(children.typeRange.length, equals("List<ContentChildComp>".length));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_ArgumentSelectorMissing() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(template:'')
class ComponentA {
}
''');
    await getDirectives(source);
    // validate
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.ARGUMENT_SELECTOR_MISSING]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_CannotParseSelector() async {
    final code = r'''
import 'package:angular/angular.dart';
@Component(selector: 'a+bad selector', template: '')
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.CANNOT_PARSE_SELECTOR, code, "+");
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_DirectiveTypeLiteralExpected() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 'AAA', directives: const [int])
class ComponentA {
}
''');
    await getDirectives(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TYPE_IS_NOT_A_DIRECTIVE]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_selector_notStringValue() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 55, template: '')
class ComponentA {
}
''');
    await getDirectives(source);
    // validate
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      AngularWarningCode.STRING_VALUE_EXPECTED,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasExports() async {
    final code = r'''
import 'package:angular/angular.dart';

const foo = null;
void bar() {}
class MyClass {}

@Component(selector: 'my-component', template: '',
    exports: const [foo, bar, MyClass])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first as Component;
    expect(component.exports, hasLength(3));
    {
      final export = component.exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo,')));
      expect(export.range.length, equals('foo'.length));
      expect(export.element, isNotNull); // linked
    }
    {
      final export = component.exports[1];
      expect(export.name, equals('bar'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('bar,')));
      expect(export.range.length, equals('bar'.length));
      expect(export.element, isNotNull); // linked
    }
    {
      final export = component.exports[2];
      expect(export.name, equals('MyClass'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('MyClass]')));
      expect(export.range.length, equals('MyClass'.length));
      expect(export.element, isNotNull); // linked
    }
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasNonIdentifierExport() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '', exports: const [1])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.EXPORTS_MUST_BE_PLAIN_IDENTIFIERS, code, '1');
  }

  // ignore: non_constant_identifier_names
  Future test_hasRepeatedExports() async {
    final code = r'''
import 'package:angular/angular.dart';

const foo = null;

@Component(selector: 'my-component', template: '', exports: const [foo, foo])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate. Can't validate position because foo occurs so many times
    errorListener.assertErrorsWithCodes([AngularWarningCode.DUPLICATE_EXPORT]);
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadata() async {
    final code = r'''
import 'dart:async';
import 'package:angular/angular.dart';

@Component(selector: 'foo', template: '')
class BaseComponent {
  @Input()
  String input;
  @Output()
  Stream<String> output;

  @ViewChild(BaseComponent)
  BaseComponent queryView;
  @ViewChildren(BaseComponent)
  List<BaseComponent> queryListView;
  @ContentChild(BaseComponent)
  BaseComponent queryContent;
  @ContentChildren(BaseComponent)
  List<BaseComponent> queryListContent;

  // TODO host properties & listeners
}

@Component( selector: 'my-component', template: '<p></p>')
class MyComponent extends BaseComponent {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = getDirectiveByName(directives, 'MyComponent');
    final compInputs = component.inputs;
    expect(compInputs, hasLength(1));
    {
      final input = compInputs[0];
      expect(input.name, 'input');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("String"));
    }

    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.name, 'output');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("String"));
    }

    final compChildrenFields = component.contentChildrenFields;
    expect(compChildrenFields, hasLength(1));
    {
      final children = compChildrenFields[0];
      expect(children.fieldName, 'queryListContent');
    }

    final compChildFields = component.contentChildFields;
    expect(compChildFields, hasLength(1));
    {
      final child = compChildFields[0];
      expect(child.fieldName, 'queryContent');
    }

    // TODO asert viewchild is inherited once that's supported
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadata_notReimplemented_stillSurfacesAPI() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

abstract class BaseComponent {
  @Input()
  set someInput(int x);

  @Output()
  Stream<int> get someOutput;
}

@Component(selector: 'my-component', template: '<p></p>')
class ImproperlyDefinedComponent extends BaseComponent {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component =
        getDirectiveByName(directives, 'ImproperlyDefinedComponent');
    final compInputs = component.inputs;
    final compOutputs = component.outputs;
    expect(compInputs, hasLength(1));
    {
      final input = compInputs[0];
      expect(input.name, 'someInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("int"));
    }
    expect(compOutputs, hasLength(1));
    {
      final input = compOutputs[0];
      expect(input.name, 'someOutput');
      expect(input.eventType, isNotNull);
      expect(input.eventType.toString(), equals("int"));
    }
    errorListener.assertErrorsWithCodes(
        [StaticWarningCode.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER_TWO]);
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadata_overriddenWithVariance() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

abstract class BaseComponent {
  @Input()
  set someInput(int x);

  @Output()
  Stream<Object> get someOutput;
}

@Component(selector: 'my-component', template: '<p></p>')
class VarianceComponent extends BaseComponent {
  set someInput(Object x) => null; // contravariance -- allowed on params

  Stream<int> someOutput; // covariance -- allowed on returns
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = getDirectiveByName(directives, 'VarianceComponent');
    final compInputs = component.inputs;
    final compOutputs = component.outputs;
    expect(compInputs, hasLength(1));
    {
      final input = compInputs[0];
      expect(input.name, 'someInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("Object"));
    }
    expect(compOutputs, hasLength(1));
    {
      final input = compOutputs[0];
      expect(input.name, 'someOutput');
      expect(input.eventType, isNotNull);
      expect(input.eventType.toString(), equals("int"));
    }
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadataChildDirective() async {
    final childCode = r'''
import 'dart:async';
import 'package:angular/angular.dart';

@Component(selector: 'foo', template: '')
class BaseComponent {
  @Input()
  String input;
  @Output()
  Stream<String> output;

  @ViewChild(BaseComponent)
  BaseComponent queryView;
  @ViewChildren(BaseComponent)
  List<BaseComponent> queryListView;
  @ContentChild(BaseComponent)
  BaseComponent queryContent;
  @ContentChildren(BaseComponent)
  List<BaseComponent> queryListContent;

  // TODO host properties & listeners
}

@Component( selector: 'child-component', template: '<p></p>')
class ChildComponent extends BaseComponent {
}
''';
    newSource('/child.dart', childCode);

    final code = r'''
import 'package:angular/angular.dart';
import 'child.dart';

@Component(selector: 'my-component', template: '<p></p>',
    directives: const [ChildComponent])
class MyComponent {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component =
        (getDirectiveByName(directives, 'MyComponent') as Component)
            .directives
            .first;
    final compInputs = component.inputs;
    expect(compInputs, hasLength(1));
    {
      final input = compInputs[0];
      expect(input.name, 'input');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("String"));
    }

    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.name, 'output');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("String"));
    }

    final compChildren = component.contentChildrenFields;
    expect(compChildren, hasLength(1));
    {
      final children = compChildren[0];
      expect(children.fieldName, 'queryListContent');
    }

    final compChilds = component.contentChildFields;
    expect(compChilds, hasLength(1));
    {
      final child = compChilds[0];
      expect(child.fieldName, 'queryContent');
    }

    // TODO asert viewchild is inherited once that's supported
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadataInheritanceDeep() async {
    final code = r'''
import 'package:angular/angular.dart';

class BaseBaseComponent {
  @Input()
  int someInput;
}

class BaseComponent extends BaseBaseComponent {
}

@Component(selector: 'my-component', template: '<p></p>')
class FinalComponent
   extends BaseComponent {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = getDirectiveByName(directives, 'FinalComponent');
    final compInputs = component.inputs;
    expect(compInputs, hasLength(1));
    {
      final input = compInputs[0];
      expect(input.name, 'someInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("int"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_inheritMetadataMixinsInterfaces() async {
    final code = r'''
import 'package:angular/angular.dart';

class MixinComponent1 {
  @Input()
  int mixin1Input;
}

class MixinComponent2 {
  @Input()
  int mixin2Input;
}

class ComponentInterface1 {
  @Input()
  int interface1Input;
}

class ComponentInterface2 {
  @Input()
  int interface2Input;
}

@Component( selector: 'my-component', template: '<p></p>')
class FinalComponent
   extends Object
   with MixinComponent1, MixinComponent2
   implements ComponentInterface1, ComponentInterface2 {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = getDirectiveByName(directives, 'FinalComponent');
    final inputNames = component.inputs.map((input) => input.name);
    expect(
        inputNames,
        unorderedEquals([
          'mixin1Input',
          'mixin2Input',
          'interface1Input',
          'interface2Input'
        ]));
  }

  // ignore: non_constant_identifier_names
  Future test_inputOnGetterIsError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class MyComponent {
  @Input()
  String get someGetter => null;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.INPUT_ANNOTATION_PLACEMENT_INVALID,
        code,
        "@Input()");
  }

  // ignore: non_constant_identifier_names
  Future test_inputs() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Input()
  bool firstField;
  @Input('secondInput')
  String secondField;
  @Input()
  set someSetter(String x) { }
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final inputs = component.inputs;
    expect(inputs, hasLength(3));
    {
      final input = inputs[0];
      expect(input.name, 'firstField');
      expect(input.nameRange.offset, code.indexOf('firstField'));
      expect(input.nameRange.length, 'firstField'.length);
      expect(input.setterRange.offset, input.nameRange.offset);
      expect(input.setterRange.length, input.name.length);
      expect(input.setter, isNotNull);
      expect(input.setter.isSetter, isTrue);
      expect(input.setter.displayName, 'firstField');
      expect(input.setterType.toString(), equals("bool"));
    }
    {
      final input = inputs[1];
      expect(input.name, 'secondInput');
      expect(input.nameRange.offset, code.indexOf('secondInput'));
      expect(input.setterRange.offset, code.indexOf('secondField'));
      expect(input.setterRange.length, 'secondField'.length);
      expect(input.setter, isNotNull);
      expect(input.setter.isSetter, isTrue);
      expect(input.setter.displayName, 'secondField');
      expect(input.setterType.toString(), equals("String"));
    }
    {
      final input = inputs[2];
      expect(input.name, 'someSetter');
      expect(input.nameRange.offset, code.indexOf('someSetter'));
      expect(input.setterRange.offset, input.nameRange.offset);
      expect(input.setterRange.length, input.name.length);
      expect(input.setter, isNotNull);
      expect(input.setter.isSetter, isTrue);
      expect(input.setter.displayName, 'someSetter');
      expect(input.setterType.toString(), equals("String"));
    }

    // assert no syntax errors, etc
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_noDirectives() async {
    final source = newSource('/test.dart', r'''
class A {}
class B {}
''');
    await getDirectives(source);
    expect(directives, isEmpty);
  }

  // ignore: non_constant_identifier_names
  Future test_outputOnSetterIsError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class MyComponent {
  @Output()
  set someSetter(x) { }
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.OUTPUT_ANNOTATION_PLACEMENT_INVALID,
        code,
        "@Output()");
  }

  // ignore: non_constant_identifier_names
  Future test_outputs() async {
    final code = r'''
import 'dart:async';
import 'package:angular/angular.dart';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  Stream<int> outputOne;
  @Output('outputTwo')
  Stream secondOutput;
  @Output()
  Stream get someGetter => null;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(3));
    {
      final output = compOutputs[0];
      expect(output.name, 'outputOne');
      expect(output.nameRange.offset, code.indexOf('outputOne'));
      expect(output.nameRange.length, 'outputOne'.length);
      expect(output.getterRange.offset, output.nameRange.offset);
      expect(output.getterRange.length, output.nameRange.length);
      expect(output.getter, isNotNull);
      expect(output.getter.isGetter, isTrue);
      expect(output.getter.displayName, 'outputOne');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("int"));
    }
    {
      final output = compOutputs[1];
      expect(output.name, 'outputTwo');
      expect(output.nameRange.offset, code.indexOf('outputTwo'));
      expect(output.getterRange.offset, code.indexOf('secondOutput'));
      expect(output.getterRange.length, 'secondOutput'.length);
      expect(output.getter, isNotNull);
      expect(output.getter.isGetter, isTrue);
      expect(output.getter.displayName, 'secondOutput');
      expect(output.eventType, isNotNull);
      expect(output.eventType.isDynamic, isTrue);
    }
    {
      final output = compOutputs[2];
      expect(output.name, 'someGetter');
      expect(output.nameRange.offset, code.indexOf('someGetter'));
      expect(output.getterRange.offset, output.nameRange.offset);
      expect(output.getterRange.length, output.name.length);
      expect(output.getter, isNotNull);
      expect(output.getter.isGetter, isTrue);
      expect(output.getter.displayName, 'someGetter');
      expect(output.eventType, isNotNull);
      expect(output.eventType.isDynamic, isTrue);
    }

    // assert no syntax errors, etc
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_extendStreamIsOk() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

abstract class MyStream<T> implements Stream<T> { }

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  MyStream<int> myOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.eventType, isNotNull);
    }
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_extendStreamNotStreamHasDynamicEventType() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  int badOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("dynamic"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_extendStreamSpecializedIsOk() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

class MyStream extends Stream<int> { }

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  MyStream myOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("int"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_extendStreamUntypedIsOk() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

class MyStream extends Stream { }

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  MyStream myOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("dynamic"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_notEventEmitterTypeError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  int badOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.OUTPUT_MUST_BE_STREAM, code, "badOutput");
  }

  // ignore: non_constant_identifier_names
  Future test_outputs_streamIsOk() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:async';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent {
  @Output()
  Stream<int> myOutput;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output = compOutputs[0];
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("int"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_parameterizedInheritedInputsOutputs() async {
    final code = r'''
import 'dart:async';
import 'package:angular/angular.dart';

class Generic<T> {
  @Input()
  T inputViaParentDecl;
  @Output()
  Stream<T> outputViaParentDecl;
}

@Component(selector: 'my-component', template: '<p></p>')
class MyComponent extends Generic {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compInputs = component.inputs;
    expect(compInputs, hasLength(1));
    {
      final input =
          compInputs.singleWhere((i) => i.name == 'inputViaParentDecl');
      expect(input, isNotNull);
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("dynamic"));
    }

    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output =
          compOutputs.singleWhere((o) => o.name == 'outputViaParentDecl');
      expect(output, isNotNull);
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("dynamic"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_parameterizedInheritedInputsOutputsSpecified() async {
    final code = r'''
import 'dart:async';
import 'package:angular/angular.dart';

class Generic<T> {
  @Input()
  T inputViaParentDecl;
  @Output()
  Stream<T> outputViaParentDecl;
}

@Component(selector: 'my-component', template: '<p></p>')
class MyComponent extends Generic<String> {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final compInputs = component.inputs;
    expect(compInputs, hasLength(1));
    {
      final input =
          compInputs.singleWhere((i) => i.name == 'inputViaParentDecl');
      expect(input, isNotNull);
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("String"));
    }

    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(1));
    {
      final output =
          compOutputs.singleWhere((o) => o.name == 'outputViaParentDecl');
      expect(output, isNotNull);
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("String"));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_parameterizedInputsOutputs() async {
    final code = r'''
import 'dart:async';
import 'package:angular/angular.dart';

@Component(
    selector: 'my-component',
    template: '<p></p>')
class MyComponent<T, A extends String, B extends A> {
  @Output() Stream<T> dynamicOutput;
  @Input() T dynamicInput;
  @Output() Stream<A> stringOutput;
  @Input() A stringInput;
  @Output() Stream<B> stringOutput2;
  @Input() B stringInput2;
  @Output() Stream<List<B>> listOutput;
  @Input() List<B> listInput;
}

''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    final component = directives.single;
    final compInputs = component.inputs;
    expect(compInputs, hasLength(4));
    {
      final input = compInputs[0];
      expect(input.name, 'dynamicInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("dynamic"));
    }
    {
      final input = compInputs[1];
      expect(input.name, 'stringInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("String"));
    }
    {
      final input = compInputs[2];
      expect(input.name, 'stringInput2');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("String"));
    }
    {
      final input = compInputs[3];
      expect(input.name, 'listInput');
      expect(input.setterType, isNotNull);
      expect(input.setterType.toString(), equals("List<String>"));
    }

    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(4));
    {
      final output = compOutputs[0];
      expect(output.name, 'dynamicOutput');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("dynamic"));
    }
    {
      final output = compOutputs[1];
      expect(output.name, 'stringOutput');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("String"));
    }
    {
      final output = compOutputs[2];
      expect(output.name, 'stringOutput2');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("String"));
    }
    {
      final output = compOutputs[3];
      expect(output.name, 'listOutput');
      expect(output.eventType, isNotNull);
      expect(output.eventType.toString(), equals("List<String>"));
    }

    // assert no syntax errors, etc
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeB')
class PipeB extends PipeTransform {
  String transform(int a1, String a2, bool a3) => 'someString';
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(2));
    {
      final pipe = pipes[0];
      expect(pipe, isA<Pipe>());
      final pipeName = pipe.pipeName;
      expect(pipeName, isA<String>());
      expect(pipeName, 'pipeA');

      expect(pipe.requiredArgumentType.toString(), 'int');
      expect(pipe.transformReturnType.toString(), 'int');
      expect(pipe.optionalArgumentTypes, hasLength(0));
    }
    {
      final pipe = pipes[1];
      expect(pipe, isA<Pipe>());
      final pipeName = pipe.pipeName;
      expect(pipeName, isA<String>());
      expect(pipeName, 'pipeB');

      expect(pipe.requiredArgumentType.toString(), 'int');
      expect(pipe.transformReturnType.toString(), 'String');

      final opArgs = pipe.optionalArgumentTypes;
      expect(opArgs, hasLength(2));
      expect(opArgs[0].toString(), 'String');
      expect(opArgs[1].toString(), 'bool');
    }
    errorListener.assertNoErrors();
  }

  Future test_Pipe_allowedOptionalArgs() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform{
  transform([named]) {}
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());

    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_dynamic() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform{
  dynamic transform(dynamic x, [dynamic more]) {}
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());

    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_error_bad_extends() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

class Trouble {}

@Pipe('pipeA')
class PipeA extends Trouble{
  int transform(int blah) => blah;
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());
    final pipeName = pipe.pipeName;
    expect(pipeName, isA<String>());
    expect(pipeName, 'pipeA');

    expect(pipe.transformReturnType.toString(), 'int');
    expect(pipe.requiredArgumentType.toString(), 'int');
    expect(pipe.optionalArgumentTypes, hasLength(0));

    errorListener.assertErrorsWithCodes(
        [AngularWarningCode.PIPE_REQUIRES_PIPETRANSFORM]);
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_error_named_args() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform{
  transform({named}) {}
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());

    errorListener.assertErrorsWithCodes(
        [AngularWarningCode.PIPE_TRANSFORM_NO_NAMED_ARGS]);
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_error_no_pipeTransform() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA {
  int transform(int blah) => blah;
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());
    final pipeName = pipe.pipeName;
    expect(pipeName, isA<String>());
    expect(pipeName, 'pipeA');

    expect(pipe.transformReturnType.toString(), 'int');
    expect(pipe.requiredArgumentType.toString(), 'int');
    expect(pipe.optionalArgumentTypes, hasLength(0));

    errorListener.assertErrorsWithCodes(
        [AngularWarningCode.PIPE_REQUIRES_PIPETRANSFORM]);
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_error_no_transform() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

class Trouble {}

@Pipe('pipeA')
class PipeA extends PipeTransform{}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());
    final pipeName = pipe.pipeName;
    expect(pipeName, isA<String>());
    expect(pipeName, 'pipeA');

    expect(pipe.requiredArgumentType, null);
    expect(pipe.transformReturnType, null);
    expect(pipe.optionalArgumentTypes, hasLength(0));

    errorListener.assertErrorsWithCodes(
        [AngularWarningCode.PIPE_REQUIRES_TRANSFORM_METHOD]);
  }

  // ignore: non_constant_identifier_names
  Future test_Pipe_is_abstract() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

class Trouble {}

@Pipe('pipeA')
abstract class PipeA extends PipeTransform{
  int transform(int blah) => blah;
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    final pipe = pipes[0];
    expect(pipe, isA<Pipe>());
    final pipeName = pipe.pipeName;
    expect(pipeName, isA<String>());
    expect(pipeName, 'pipeA');

    expect(pipe.transformReturnType.toString(), 'int');
    expect(pipe.requiredArgumentType.toString(), 'int');
    expect(pipe.optionalArgumentTypes, hasLength(0));

    errorListener
        .assertErrorsWithCodes([AngularWarningCode.PIPE_CANNOT_BE_ABSTRACT]);
  }

  // ignore: non_constant_identifier_names
  Future test_pipeInheritance() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

class BasePipe extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipe')
class MyPipe extends BasePipe {
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(1));
    {
      final pipe = pipes[0];
      expect(pipe, isA<Pipe>());
      final pipeName = pipe.pipeName;
      expect(pipeName, isA<String>());
      expect(pipeName, 'pipe');

      expect(pipe.requiredArgumentType.toString(), 'int');
      expect(pipe.transformReturnType.toString(), 'int');
      expect(pipe.optionalArgumentTypes, hasLength(0));
    }

    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_prefixedExport() async {
    newSource('/prefixed.dart', 'const foo = null;');
    final code = r'''
import 'package:angular/angular.dart';
import '/prefixed.dart' as prefixed;

const foo = null;

@Component(selector: 'my-component', template: '',
    exports: const [prefixed.foo, foo])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first as Component;
    expect(component.exports, hasLength(2));
    {
      final export = component.exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals('prefixed'));
      expect(export.range.offset, equals(code.indexOf('prefixed.foo')));
      expect(export.range.length, equals('prefixed.foo'.length));
      expect(export.element, isNotNull); // linked
    }
    {
      final export = component.exports[1];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo]')));
      expect(export.range.length, equals('foo'.length));
      expect(export.element, isNotNull); // linked
    }

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_selector_constantExpressionOk() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'a' + '[b]', template: '')
class ComponentA {
}
''');
    await getDirectives(source);
    // validate
    errorListener.assertNoErrors();
  }
}

@reflectiveTest
class BuildStandardAngularTest extends AngularDriverTestBase {
  // ignore: non_constant_identifier_names
  Future test_perform() async {
    final ng = await angularDriver.buildStandardAngular();
    // validate
    expect(ng, isNotNull);
    expect(ng.templateRef, isNotNull);
    expect(ng.elementRef, isNotNull);
    expect(ng.pipeTransform, isNotNull);
    expect(ng.component, isNotNull);
  }

  // ignore: non_constant_identifier_names
  Future test_securitySchema() async {
    final ng = await angularDriver.buildStandardAngular();
    // validate
    expect(ng, isNotNull);
    expect(ng.securitySchema, isNotNull);

    final imgSrcSecurity = ng.securitySchema.lookup('img', 'src');
    expect(imgSrcSecurity, isNotNull);
    expect(imgSrcSecurity.safeTypes[0].toString(), 'SafeUrl');
    expect(imgSrcSecurity.sanitizationAvailable, true);

    final aHrefSecurity = ng.securitySchema.lookup('a', 'href');
    expect(aHrefSecurity, isNotNull);
    expect(aHrefSecurity.safeTypes[0].toString(), 'SafeUrl');
    expect(aHrefSecurity.sanitizationAvailable, true);

    final innerHtmlSecurity = ng.securitySchema.lookupGlobal('innerHTML');
    expect(innerHtmlSecurity, isNotNull);
    expect(innerHtmlSecurity.safeTypes[0].toString(), 'SafeHtml');
    expect(innerHtmlSecurity.sanitizationAvailable, true);

    final iframeSrcdocSecurity = ng.securitySchema.lookup('iframe', 'srcdoc');
    expect(iframeSrcdocSecurity, isNotNull);
    expect(iframeSrcdocSecurity.safeTypes[0].toString(), 'SafeHtml');
    expect(iframeSrcdocSecurity.sanitizationAvailable, true);

    final styleSecurity = ng.securitySchema.lookupGlobal('style');
    expect(styleSecurity, isNotNull);
    expect(styleSecurity.safeTypes[0].toString(), 'SafeStyle');
    expect(styleSecurity.sanitizationAvailable, true);

    final iframeSrcSecurity = ng.securitySchema.lookup('iframe', 'src');
    expect(iframeSrcSecurity, isNotNull);
    expect(iframeSrcSecurity.safeTypes[0].toString(), 'SafeResourceUrl');
    expect(iframeSrcSecurity.sanitizationAvailable, false);

    final scriptSrcSecurity = ng.securitySchema.lookup('script', 'src');
    expect(scriptSrcSecurity, isNotNull);
    expect(scriptSrcSecurity.safeTypes[0].toString(), 'SafeResourceUrl');
    expect(scriptSrcSecurity.sanitizationAvailable, false);
  }
}

@reflectiveTest
class BuildStandardHtmlComponentsTest extends AngularDriverTestBase {
  // ignore: non_constant_identifier_names
  // ignore: non_constant_identifier_names
  Future test_buildStandardHtmlAttributes() async {
    final stdhtml = await angularDriver.buildStandardHtml();
    final inputElements = stdhtml.attributes;
    {
      final input = inputElements['tabIndex'];
      expect(input, isNotNull);
      expect(input.setter, isNotNull);
      expect(input.setterType.toString(), equals("int"));
    }
    {
      final input = inputElements['hidden'];
      expect(input, isNotNull);
      expect(input.setter, isNotNull);
      expect(input.setterType.toString(), equals("bool"));
    }
    {
      final input = inputElements['innerHtml'];
      expect(input, isNotNull);
      expect(identical(input, inputElements['innerHTML']), true);
      expect(input.setter, isNotNull);
      expect(input.setterType.toString(), equals('String'));
      expect(input.securityContext, isNotNull);
      expect(input.securityContext.safeTypes[0].toString(), equals('SafeHtml'));
      expect(input.securityContext.sanitizationAvailable, equals(true));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_buildStandardHtmlClasses() async {
    final stdhtml = await angularDriver.buildStandardHtml();
    expect(stdhtml.elementClass, isNotNull);
    expect(stdhtml.elementClass.name, 'Element');
    expect(stdhtml.htmlElementClass, isNotNull);
    expect(stdhtml.htmlElementClass.name, 'HtmlElement');
  }

  // ignore: non_constant_identifier_names
  Future test_buildStandardHtmlEvents() async {
    final stdhtml = await angularDriver.buildStandardHtml();
    final outputElements = stdhtml.events;
    {
      // This one is important because it proves we're using @DomAttribute
      // to generate the output name and not the method in the sdk.
      final outputElement = outputElements['keyup'];
      expect(outputElement, isNotNull);
      expect(outputElement.getter, isNotNull);
      expect(outputElement.eventType, isNotNull);
    }
    {
      final outputElement = outputElements['cut'];
      expect(outputElement, isNotNull);
      expect(outputElement.getter, isNotNull);
      expect(outputElement.eventType, isNotNull);
    }
    {
      final outputElement = outputElements['click'];
      expect(outputElement, isNotNull);
      expect(outputElement.getter, isNotNull);
      expect(outputElement.eventType, isNotNull);
      expect(outputElement.eventType.toString(), 'MouseEvent');
    }
    {
      final outputElement = outputElements['change'];
      expect(outputElement, isNotNull);
      expect(outputElement.getter, isNotNull);
      expect(outputElement.eventType, isNotNull);
    }
    {
      // used to happen from "id" which got truncated by 'on'.length
      final outputElement = outputElements[''];
      expect(outputElement, isNull);
    }
    {
      // used to happen from "hidden" which got truncated by 'on'.length
      final outputElement = outputElements['dden'];
      expect(outputElement, isNull);
    }
    {
      // missing from dart:html, and supplied manually (with no getter)
      final outputElement = outputElements['focusin'];
      expect(outputElement, isNotNull);
      expect(outputElement.eventType, isNotNull);
      expect(outputElement.eventType.toString(), 'FocusEvent');
    }
    {
      // missing from dart:html, and supplied manually (with no getter)
      final outputElement = outputElements['focusout'];
      expect(outputElement, isNotNull);
      expect(outputElement.eventType, isNotNull);
      expect(outputElement.eventType.toString(), 'FocusEvent');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_perform() async {
    final stdhtml = await angularDriver.buildStandardHtml();
    // validate
    final map = stdhtml.components;
    expect(map, isNotNull);
    // a
    {
      final component = map['a'];
      expect(component, isNotNull);
      expect(component.classElement.displayName, 'AnchorElement');
      expect(component.selector.toString(), 'a');
      final inputs = component.inputs;
      final outputElements = component.outputs;
      {
        final input = inputs.singleWhere((i) => i.name == 'href');
        expect(input, isNotNull);
        expect(input.setter, isNotNull);
        expect(input.setterType.toString(), equals("String"));
        expect(input.securityContext, isNotNull);
        expect(
            input.securityContext.safeTypes[0].toString(), equals('SafeUrl'));
        expect(input.securityContext.sanitizationAvailable, equals(true));
      }
      expect(outputElements, hasLength(0));
      expect(inputs.where((i) => i.name == '_privateField'), hasLength(0));
    }
    // button
    {
      final component = map['button'];
      expect(component, isNotNull);
      expect(component.classElement.displayName, 'ButtonElement');
      expect(component.selector.toString(), 'button');
      final inputs = component.inputs;
      final outputElements = component.outputs;
      {
        final input = inputs.singleWhere((i) => i.name == 'autofocus');
        expect(input, isNotNull);
        expect(input.setter, isNotNull);
        expect(input.setterType.toString(), equals("bool"));
        expect(input.securityContext, isNull);
      }
      expect(outputElements, hasLength(0));
    }
    // iframe
    {
      final component = map['iframe'];
      expect(component, isNotNull);
      expect(component.classElement.displayName, 'IFrameElement');
      expect(component.selector.toString(), 'iframe');
      final inputs = component.inputs;
      {
        final input = inputs.singleWhere((i) => i.name == 'src');
        expect(input, isNotNull);
        expect(input.setter, isNotNull);
        expect(input.setterType.toString(), equals("String"));
        expect(input.securityContext, isNotNull);
        expect(input.securityContext.safeTypes[0].toString(),
            equals('SafeResourceUrl'));
        expect(input.securityContext.sanitizationAvailable, equals(false));
      }
    }
    // input
    {
      final component = map['input'];
      expect(component, isNotNull);
      expect(component.classElement.displayName, 'InputElement');
      expect(component.selector.toString(), 'input');
      final outputElements = component.outputs;
      expect(outputElements, hasLength(0));
    }
    // body is one of the few elements with special events
    {
      final component = map['body'];
      expect(component, isNotNull);
      expect(component.classElement.displayName, 'BodyElement');
      expect(component.selector.toString(), 'body');
      final outputElements = component.outputs;
      expect(outputElements, hasLength(1));
      {
        final output = outputElements[0];
        expect(output.name, equals("unload"));
        expect(output.getter, isNotNull);
        expect(output.eventType, isNotNull);
      }
    }
    // h1, h2, h3
    expect(map['h1'], isNotNull);
    expect(map['h2'], isNotNull);
    expect(map['h3'], isNotNull);
    // has no mention of 'option' in the source, is hardcoded
    expect(map['option'], isNotNull);
    // <template> is special, not actually a TemplateElement
    expect(map['template'], isNull);
    // <audio> is a "specialElementClass", its ctor isn't analyzable.
    expect(map['audio'], isNotNull);
  }
}

@reflectiveTest
class BuildStandardHtmlTest extends AngularDriverTestBase {
  Source optionsSource;
  @override
  Future<void> setUp() {
    // Don't perform setup before tests. Tests will run `super.setUp()`.

    // However, we need to create a Source for the options file.
    resourceProvider = MemoryResourceProvider();
    optionsSource =
        resourceProvider.newFile('/analysis_options.yaml', '').createSource();

    return null;
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_coreTypes() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        strEventImplicitCore:
          type: String
        strEventExplicitCore:
          type: String
          path: 'dart:core'
        boolEventImplicitCore:
          type: bool
        boolEventExplicitCore:
          type: bool
          path: 'dart:core'
''', optionsSource);

    await super.setUp();

    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(4));
    {
      final event = html.customEvents['strEventImplicitCore'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'String');
      expect(
          event.eventType.element.source.fullName, '/sdk/lib/core/core.dart');
    }
    {
      final event = html.customEvents['strEventExplicitCore'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'String');
      expect(
          event.eventType.element.source.fullName, '/sdk/lib/core/core.dart');
    }
    {
      final event = html.customEvents['boolEventImplicitCore'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'bool');
      expect(
          event.eventType.element.source.fullName, '/sdk/lib/core/core.dart');
    }
    {
      final event = html.customEvents['boolEventExplicitCore'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'bool');
      expect(
          event.eventType.element.source.fullName, '/sdk/lib/core/core.dart');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_enum() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        enumType:
          type: EnumType
          path: 'package:test_package/enum.dart'
''', optionsSource);

    await super.setUp();

    newSource('/enum.dart', r'''
enum EnumType {}
''');
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['enumType'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'EnumType');
      expect(event.eventType.element.source.fullName, '/enum.dart');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_generic() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        generic:
          type: Generic
          path: 'package:test_package/generic.dart'
''', optionsSource);

    await super.setUp();

    newSource('/generic.dart', r'''
class Generic<T> {}
''');
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['generic'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'Generic<dynamic>');
      expect(event.eventType.element.source.fullName, '/generic.dart');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_noSource_dynamic() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        noSuchSource:
          typePath: nonexist.dart
''', optionsSource);

    await super.setUp();
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['noSuchSource'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'dynamic');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_noSuchIdentifier_dynamic() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        noSuchIdentifier:
          type: NonExistEvent
          path: 'package:test_package/customevent.dart'
''', optionsSource);

    await super.setUp();

    newSource('/customevent.dart', r'''
class NotTheCorrectEvent {}
''');

    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['noSuchIdentifier'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'dynamic');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_resolved() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        bar:
          type: BarEvent
          path: 'package:test_package/bar.dart'
''', optionsSource);

    await super.setUp();

    newSource('/bar.dart', r'''
class BarEvent {}
''');
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['bar'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'BarEvent');
      expect(event.eventType.element.source.fullName, '/bar.dart');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_typedef() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        typedef:
          type: TypeDef
          path: 'package:test_package/typedef.dart'
''', optionsSource);

    await super.setUp();

    newSource('/typedef.dart', r'''
typedef TypeDef = int Function<T>();
''');
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['typedef'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      final eventType = event.eventType as FunctionType;
      expect(eventType, isNotNull);
      expect(eventType.returnType.toString(), 'int');
      expect(eventType.typeFormals, isEmpty);
      expect(eventType.parameters, isEmpty);
      expect(eventType.element.source.fullName, '/typedef.dart');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_typeIsNotAType_dynamic() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        notAType:
          type: foo
          path: 'package:test_package/customevent.dart'
''', optionsSource);

    await super.setUp();

    newSource('/customevent.dart', r'''
int foo;
''');
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(1));
    {
      final event = html.customEvents['notAType'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'dynamic');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_customEvents_untyped() async {
    ngOptions = AngularOptions.fromString(r'''
analyzer:
  plugins:
    angular:
      enabled: true
      custom_events:
        foo:
        bar:
''', optionsSource);

    await super.setUp();
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.customEvents, isNotNull);
    expect(html.customEvents, hasLength(2));
    {
      final event = html.customEvents['foo'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'dynamic');
    }
    {
      final event = html.customEvents['bar'];
      expect(event, isNotNull);
      expect(event.getter, isNull);
      expect(event.eventType, isNotNull);
      expect(event.eventType.toString(), 'dynamic');
    }
  }

  // ignore: non_constant_identifier_names
  Future test_perform() async {
    await super.setUp();
    final html = await angularDriver.buildStandardHtml();
    // validate
    expect(html, isNotNull);
    expect(html.events, isNotNull);
    expect(html.standardEvents, isNotNull);
    expect(html.customEvents, isNotNull);
  }
}

@reflectiveTest
class BuildSyntacticModelTest extends AngularDriverTestBase {
  List<DirectiveBase> directives;
  List<Pipe> pipes;
  List<Template> templates;
  List<AnalysisError> errors;

  Future getTemplates(final Source source) async {
    final dartResult = await dartDriver.getResult(source.fullName);
    fillErrorListener(dartResult.errors);
    final result = await angularDriver.requestDartResult(source.fullName);
    directives = result.directives;
    pipes = result.pipes;

    templates = directives
        .map((d) => d is Component ? d.template : null)
        .where((d) => d != null)
        .toList();
    errors = result.errors;
    fillErrorListener(errors);
  }

  // ignore: non_constant_identifier_names
  Future test_constantExpressionTemplateComplexIsOnlyError() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

const String tooComplex = 'bcd';

@Component(selector: 'aaa', template: 'abc' + tooComplex + "{{invalid {{stuff")
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularHintCode.OFFSETS_CANNOT_BE_CREATED]);
  }

  // ignore: non_constant_identifier_names
  Future test_constantExpressionTemplateOk() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 'abc' + 'bcd')
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_directives() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
class DirectiveA {}

@Directive(selector: '[bbb]')
class DirectiveB {}

@Directive(selector: '[ccc]')
class DirectiveC {}

const DIR_AB = const [DirectiveA, DirectiveB];

@Component(selector: 'my-component', template: 'My template',
    directives: const [DIR_AB, DirectiveC])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.directives, hasLength(3));
        final directiveClassNames = component.directives
            .map((directive) => (directive as Directive).classElement.name)
            .toList();
        expect(directiveClassNames,
            unorderedEquals(['DirectiveA', 'DirectiveB', 'DirectiveC']));
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_directives_hasError_notListVariable() async {
    final code = r'''
import 'package:angular/angular.dart';

const NOT_DIRECTIVE_LIST = 42;

@Component(selector: 'my-component', template: 'My template',
   directives: const [NOT_DIRECTIVE_LIST])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TYPE_LITERAL_EXPECTED]);
  }

  // ignore: non_constant_identifier_names
  Future test_directives_not_list_syntax() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
class DirectiveA {}

@Directive(selector: '[bbb]')
class DirectiveB {}

const VARIABLE = const [DirectiveA, DirectiveB];

@Component(selector: 'my-component', template: 'My template',
    directives: VARIABLE)
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final view = getDirectiveByName(directives, 'MyComponent') as Component;
    final directiveClassNames = view.directives
        .map((directive) => (directive as Directive).classElement.name)
        .toList();
    expect(directiveClassNames, unorderedEquals(['DirectiveA', 'DirectiveB']));
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_directives_not_list_syntax_errorWithinVariable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: 'My template',
    directives: VARIABLE)
class MyComponent {}

// A non-array is a type error in the analyzer; a non-component in an array is
// not so we must test it. Define below usage for asserting position.
const VARIABLE = const [Object];
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.TYPE_IS_NOT_A_DIRECTIVE, code, 'VARIABLE');
  }

  // ignore: non_constant_identifier_names
  Future test_directivesList_invalidDirectiveEntries() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
class DirectiveA {}

@Directive(selector: '[bbb]')
void directiveB() {}

void notADirective() {}
class NotADirectiveEither {}

const DIR_AB_DEEP = const [ const [ const [
    DirectiveA, directiveB, notADirective, NotADirectiveEither]]];

@Component(selector: 'my-component', template: 'My template',
    directives: const [DIR_AB_DEEP])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.directives, hasLength(2));
        final directiveNames = component.directives
            .map((directive) => directive is Directive
                ? directive.classElement.name
                : (directive as FunctionalDirective).functionElement.name)
            .toList();
        expect(directiveNames, unorderedEquals(['DirectiveA', 'directiveB']));
      }
    }

    errorListener.assertErrorsWithCodes([
      AngularWarningCode.TYPE_IS_NOT_A_DIRECTIVE,
      AngularWarningCode.FUNCTION_IS_NOT_A_DIRECTIVE
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildChildrenSetter() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp) // 1
  void set contentChild(ContentChildComp contentChild) => null;
  @ContentChildren(ContentChildComp) // 2
  void set contentChildren(List<ContentChildComp> contentChildren) => null;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;

    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));

    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<DirectiveQueriedChildType>());
    final child = childs.first.query as DirectiveQueriedChildType;

    expect(child.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildComponent() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp)
  ContentChildComp contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<DirectiveQueriedChildType>());
    final child = childs.first.query as DirectiveQueriedChildType;

    expect(child.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_dynamicOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp)
  dynamic contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<DirectiveQueriedChildType>());
    final child = childs.first.query as DirectiveQueriedChildType;

    expect(child.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_htmlNotAllowed() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'dart:html';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(AnchorElement)
  AnchorElement contentChild;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(0));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE, code, 'AnchorElement');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp)
  String contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<DirectiveQueriedChildType>());
    final child = childs.first.query as DirectiveQueriedChildType;
    expect(child.directive, equals(directives[1]));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_notRecognizedType() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(String)
  ElementRef contentChild;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(0));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE, code, 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_notTypeOrString() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(const [])
  ElementRef contentChild;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(0));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.UNKNOWN_CHILD_QUERY_TYPE, code, 'const []');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildDirective_subTypeNotAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp)
  ContentChildCompSub contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}

class ContentChildCompSub extends ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<DirectiveQueriedChildType>());
    final child = childs.first.query as DirectiveQueriedChildType;
    expect(child.directive, equals(directives[1]));

    // validate
    assertErrorInCodeAtPosition(AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
        code, 'ContentChildCompSub');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildElementRef() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ElementRef)
  ElementRef contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<ElementQueriedChildType>());

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildElementRef_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ElementRef)
  String contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildLetBound() async {
    final code = r'''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild('foo')
  ContentChildComp contentChildDirective;
  @ContentChild('fooTpl')
  TemplateRef contentChildTpl;
  @ContentChild('fooElemRef')
  ElementRef contentChildElemRef;
  @ContentChild('fooElem', read: Element)
  Element contentChildElem;
  @ContentChild('fooHtmlElem', read: HtmlElement)
  HtmlElement contentChildHtmlElem;
  @ContentChild('fooDynamic')
  dynamic contentChildDynamic;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(6));

    final childDirective = childs
        .singleWhere((c) => c.fieldName == "contentChildDirective")
        .query as LetBoundQueriedChildType;
    expect(childDirective, isA<LetBoundQueriedChildType>());
    expect(childDirective.letBoundName, equals("foo"));
    expect(childDirective.containerType.toString(), equals("ContentChildComp"));

    final childTemplate = childs
        .singleWhere((c) => c.fieldName == "contentChildTpl")
        .query as LetBoundQueriedChildType;
    expect(childTemplate, isA<LetBoundQueriedChildType>());
    expect(childTemplate.letBoundName, equals("fooTpl"));
    expect(childTemplate.containerType.toString(), equals("TemplateRef"));

    final childElement = childs
        .singleWhere((c) => c.fieldName == "contentChildElem")
        .query as LetBoundQueriedChildType;
    expect(childElement, isA<LetBoundQueriedChildType>());
    expect(childElement.letBoundName, equals("fooElem"));
    expect(childElement.containerType.toString(), equals("Element"));

    final childHtmlElement = childs
        .singleWhere((c) => c.fieldName == "contentChildHtmlElem")
        .query as LetBoundQueriedChildType;
    expect(childHtmlElement, isA<LetBoundQueriedChildType>());
    expect(childHtmlElement.letBoundName, equals("fooHtmlElem"));
    expect(childHtmlElement.containerType.toString(), equals("HtmlElement"));

    final childElementRef = childs
        .singleWhere((c) => c.fieldName == "contentChildElemRef")
        .query as LetBoundQueriedChildType;
    expect(childElementRef, isA<LetBoundQueriedChildType>());
    expect(childElementRef.letBoundName, equals("fooElemRef"));
    expect(childElementRef.containerType.toString(), equals("ElementRef"));

    final childDynamic = childs
        .singleWhere((c) => c.fieldName == "contentChildDynamic")
        .query as LetBoundQueriedChildType;
    expect(childDynamic, isA<LetBoundQueriedChildType>());
    expect(childDynamic.letBoundName, equals("fooDynamic"));
    expect(childDynamic.containerType.toString(), equals("dynamic"));

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  List<ContentChildComp> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_dynamicIterableOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  Iterable contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_dynamicListOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  List contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_dynamicOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  dynamic contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_iterableNotAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  Iterable<String> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
        code, 'Iterable<String>');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_iterableOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  Iterable<ContentChildComp> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;

    expect(children.directive, equals(directives[1]));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  List<String> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'List<String>');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_notList() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  String contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;
    expect(children.directive, equals(directives[1]));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST,
        code,
        'String');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenLetBound_dynamic() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren('foo')
  dynamic contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<LetBoundQueriedChildType>());
    final children = childrens.first.query as LetBoundQueriedChildType;
    expect(children.containerType, isNotNull);
    expect(children.containerType.toString(), 'dynamic');

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_subtypingListNotOk() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  // this is not allowed. Angular makes a List, regardless of your subtype
  CannotSubtypeList contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}

abstract class CannotSubtypeList extends List {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<DirectiveQueriedChildType>());
    final children = childrens.first.query as DirectiveQueriedChildType;
    expect(children.directive, equals(directives[1]));

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.CONTENT_OR_VIEW_CHILDREN_REQUIRES_LIST,
        code,
        'CannotSubtypeList');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_withReadSet() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(ContentChildComp, read: ViewContainerRef)
  ViewContainerRef contentChild;
  @ContentChildren(ContentChildComp, read: ViewContainerRef)
  List<ViewContainerRef> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.read.toString(), equals('ViewContainerRef'));
    final childs = component.contentChildrenFields;
    expect(childs, hasLength(1));
    expect(childs.first.read.toString(), equals('ViewContainerRef'));
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenElementRef() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ElementRef)
  List<ElementRef> contentChildren;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<ElementQueriedChildType>());

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenElementRef_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ElementRef)
  List<String> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'List<String>');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenLetBound() async {
    final code = r'''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren('foo')
  List<ContentChildComp> contentChildDirective;
  @ContentChildren('fooTpl')
  List<TemplateRef> contentChildTpl;
  @ContentChildren('fooElem', read: Element)
  List<Element> contentChildElem;
  @ContentChildren('fooHtmlElem', read: HtmlElement)
  List<HtmlElement> contentChildHtmlElem;
  @ContentChildren('fooElemRef')
  List<ElementRef> contentChildElemRef;
  @ContentChildren('fooDynamic')
  List contentChildDynamic;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(6));

    final childrenDirective = childrens
        .singleWhere((c) => c.fieldName == "contentChildDirective")
        .query as LetBoundQueriedChildType;
    expect(childrenDirective, isA<LetBoundQueriedChildType>());
    expect(childrenDirective.letBoundName, equals("foo"));
    expect(
        childrenDirective.containerType.toString(), equals("ContentChildComp"));

    final childrenTemplate = childrens
        .singleWhere((c) => c.fieldName == "contentChildTpl")
        .query as LetBoundQueriedChildType;
    expect(childrenTemplate, isA<LetBoundQueriedChildType>());
    expect(childrenTemplate.letBoundName, equals("fooTpl"));
    expect(childrenTemplate.containerType.toString(), equals("TemplateRef"));

    final childrenElement = childrens
        .singleWhere((c) => c.fieldName == "contentChildElem")
        .query as LetBoundQueriedChildType;
    expect(childrenElement, isA<LetBoundQueriedChildType>());
    expect(childrenElement.letBoundName, equals("fooElem"));
    expect(childrenElement.containerType.toString(), equals("Element"));

    final childrenHtmlElement = childrens
        .singleWhere((c) => c.fieldName == "contentChildHtmlElem")
        .query as LetBoundQueriedChildType;
    expect(childrenHtmlElement, isA<LetBoundQueriedChildType>());
    expect(childrenHtmlElement.letBoundName, equals("fooHtmlElem"));
    expect(childrenHtmlElement.containerType.toString(), equals("HtmlElement"));

    final childrenElementRef = childrens
        .singleWhere((c) => c.fieldName == "contentChildElemRef")
        .query as LetBoundQueriedChildType;
    expect(childrenElementRef, isA<LetBoundQueriedChildType>());
    expect(childrenElementRef.letBoundName, equals("fooElemRef"));
    expect(childrenElementRef.containerType.toString(), equals("ElementRef"));

    final childrenDynamic = childrens
        .singleWhere((c) => c.fieldName == "contentChildDynamic")
        .query as LetBoundQueriedChildType;
    expect(childrenDynamic, isA<LetBoundQueriedChildType>());
    expect(childrenDynamic.letBoundName, equals("fooDynamic"));
    expect(childrenDynamic.containerType.toString(), equals("dynamic"));

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenLetBound_elementReadDoesntMatchType() async {
    final code = r'''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild('el', read: Element)
  ElementRef elemRefNotElem;
  @ContentChild('el', read: HtmlElement)
  ElementRef elemRefNotHtmlElem;
  @ContentChild('el', read: Element)
  HtmlElement htmlElemNotElem;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    errorListener.assertErrorsWithCodes([
      AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
      AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
      AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenLetBound_elementWithoutReadError() async {
    final code = r'''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren('el') // missing read: Element
  List<Element> contentChildrenElem;
  @ContentChild('el') // missing read: Element
  Element contentChildElem;
  @ContentChild('el') // missing read: HtmlElement
  HtmlElement contentChildHtmlElem;
  @ContentChildren('el') // missing read: HtmlElement
  List<HtmlElement> contentChildrenHtmlElem;
  @ContentChildren('el', read: Element) // not HtmlElement
  List<HtmlElement> contentChildrenNotHtmlElem;
  @ContentChild('el', read: Element) // not HtmlElement
  HtmlElement contentChildNotHtmlElem;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    errorListener.assertErrorsWithCodes([
      AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
      AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
      AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
      AngularWarningCode.CHILD_QUERY_TYPE_REQUIRES_READ,
      AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
      AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY,
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenLetBound_readSubtypeOfAttribute() async {
    final code = r'''
import 'dart:html';
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild('el', read: Element)
  Object objectNotElem;
  @ContentChild('el', read: HtmlElement)
  Element elemNotHtmlElem;
  @ContentChild('el', read: HtmlElement)
  Object objectNotHtmlElem;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final children = component.contentChildFields;
    expect(children, hasLength(3));

    final objectNotElem = children
        .singleWhere((c) => c.fieldName == 'objectNotElem')
        .query as LetBoundQueriedChildType;
    expect(objectNotElem, isA<LetBoundQueriedChildType>());
    expect(objectNotElem.letBoundName, equals('el'));
    expect(objectNotElem.containerType.toString(), equals('Element'));

    final elemNotHtmlElem = children
        .singleWhere((c) => c.fieldName == 'elemNotHtmlElem')
        .query as LetBoundQueriedChildType;
    expect(elemNotHtmlElem, isA<LetBoundQueriedChildType>());
    expect(elemNotHtmlElem.letBoundName, equals('el'));
    expect(elemNotHtmlElem.containerType.toString(), equals('HtmlElement'));

    final objectNotHtmlElem = children
        .singleWhere((c) => c.fieldName == 'objectNotHtmlElem')
        .query as LetBoundQueriedChildType;
    expect(objectNotHtmlElem, isA<LetBoundQueriedChildType>());
    expect(objectNotHtmlElem.letBoundName, equals('el'));
    expect(objectNotHtmlElem.containerType.toString(), equals('HtmlElement'));

    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenTemplateRef() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(TemplateRef)
  List<TemplateRef> contentChildren;
}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childrens = component.contentChildrenFields;
    expect(childrens, hasLength(1));
    expect(childrens.first.query, isA<TemplateRefQueriedChildType>());

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenTemplateRef_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(TemplateRef)
  List<String> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'List<String>');
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildTemplateRef() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(TemplateRef)
  TemplateRef contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    final component = directives.first;
    final childs = component.contentChildFields;
    expect(childs, hasLength(1));
    expect(childs.first.query, isA<TemplateRefQueriedChildType>());

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildTemplateRef_notAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChild(TemplateRef)
  String contentChild;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);

    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.INVALID_TYPE_FOR_CHILD_QUERY, code, 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_missingHtmlFile() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', templateUrl: 'missing-template.html')
class MyComponent {}
''';
    final dartSource = newSource('/test.dart', code);
    await getTemplates(dartSource);
    assertErrorInCodeAtPosition(
        AngularWarningCode.REFERENCED_HTML_FILE_DOESNT_EXIST,
        code,
        "'missing-template.html'");
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_NeitherTemplateNorTemplateUrlDefined() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa')
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.NO_TEMPLATE_URL_OR_TEMPLATE_DEFINED]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_StringValueExpected() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 55)
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      AngularWarningCode.STRING_VALUE_EXPECTED,
      StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_TemplateAndTemplateUrlDefined() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 'AAA', templateUrl: 'a.html')
class ComponentA {
}
''');
    newSource('/a.html', '');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TEMPLATE_URL_AND_TEMPLATE_DEFINED]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_TypeLiteralExpected() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 'AAA', directives: const [42])
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TYPE_LITERAL_EXPECTED]);
  }

  // ignore: non_constant_identifier_names
  Future test_pipe_hasError_TypeLiteralExpected() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'aaa', template: 'AAA', pipes: const [42])
class ComponentA {
}
''');
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TYPE_LITERAL_EXPECTED]);
  }

  // ignore: non_constant_identifier_names
  Future test_pipes() async {
    final code = r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeB')
class PipeB extends PipeTransform {
  int transform(int blah) => blah;
}

@Component(selector: 'my-component', template: 'MyTemplate',
    pipes: const [PipeA, PipeB])
class MyComponent {}
    ''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.pipes, hasLength(2));
        final pipeNames =
            component.pipes.map((pipe) => pipe.classElement.name).toList();
        expect(pipeNames, unorderedEquals(['PipeA', 'PipeB']));
      }
    }
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_pipes_hasError_notListVariable() async {
    final code = r'''
import 'package:angular/angular.dart';

const NOT_PIPES_LIST = 42;

@Component(selector: 'my-component', template: 'My template',
    pipes: const [NOT_PIPES_LIST])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularWarningCode.TYPE_LITERAL_EXPECTED]);
  }

  // ignore: non_constant_identifier_names
  Future test_pipes_list_recursive() async {
    final code = r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeB')
class PipeB extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeC')
class PipeC extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeD')
class PipeD extends PipeTransform {
  int transform(int blah) => blah;
}

const PIPELIST_ONE = const [ const [PipeA, PipeB]];
const PIPELIST_TWO = const [ const [ const [PipeC, PipeD]]];
const BIGPIPELIST = const [PIPELIST_ONE, PIPELIST_TWO];

@Component(selector: 'my-component', template: 'MyTemplate',
    pipes: const [BIGPIPELIST])
class MyComponent {}
    ''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.pipes, hasLength(4));
        final pipeNames =
            component.pipes.map((pipe) => pipe.classElement.name).toList();
        expect(
            pipeNames, unorderedEquals(['PipeA', 'PipeB', 'PipeC', 'PipeD']));
      }
    }
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_pipes_selective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Pipe('pipeA')
class PipeA extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeB')
class PipeB extends PipeTransform {
  int transform(int blah) => blah;
}

@Pipe('pipeC')
class PipeC extends PipeTransform {
  int transform(int blah) => blah;
}

@Component(selector: 'my-component', template: 'MyTemplate',
    pipes: const [PipeC, PipeB])
class MyComponent {}
    ''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.pipes, hasLength(2));
        final pipeNames =
            component.pipes.map((pipe) => pipe.classElement.name).toList();
        expect(pipeNames, unorderedEquals(['PipeC', 'PipeB']));
      }
    }
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_prefixedDirectives() async {
    final otherCode = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
class DirectiveA {}

@Directive(selector: '[bbb]')
class DirectiveB {}

@Directive(selector: '[ccc]')
class DirectiveC {}

const DIR_AB = const [DirectiveA, DirectiveB];
''';

    final code = r'''
import 'package:angular/angular.dart';
import 'other.dart' as other;

@Component(selector: 'my-component', template: 'My template',
    directives: const [other.DIR_AB, other.DirectiveC])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    newSource('/other.dart', otherCode);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.directives, hasLength(3));
        final directiveClassNames = component.directives
            .map((directive) => (directive as Directive).classElement.name)
            .toList();
        expect(directiveClassNames,
            unorderedEquals(['DirectiveA', 'DirectiveB', 'DirectiveC']));
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_recursiveDirectivesList() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
class DirectiveA {}

@Directive(selector: '[bbb]')
class DirectiveB {}

const DIR_AB_DEEP = const [ const [ const [DirectiveA, DirectiveB]]];

@Component(selector: 'my-component', template: 'My template',
    directives: const [DIR_AB_DEEP])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.directives, hasLength(2));
        final directiveClassNames = component.directives
            .map((directive) => (directive as Directive).classElement.name)
            .toList();
        expect(
            directiveClassNames, unorderedEquals(['DirectiveA', 'DirectiveB']));
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_template_relativeToLibForParts() async {
    final libCode = r'''
import 'package:angular/angular.dart';
part 'parts/part.dart';
    ''';
    final partCode = r'''
part of '../lib.dart';
@Component(selector: 'my-component', templateUrl: 'parts/my-template.html')
class MyComponent {}
''';
    newSource('/lib.dart', libCode);
    final dartPartSource = newSource('/parts/part.dart', partCode);
    final htmlSource = newSource('/parts/my-template.html', '');
    await getTemplates(dartPartSource);
    errorListener.assertNoErrors();
    // MyComponent
    final component =
        getDirectiveByName(directives, 'MyComponent') as Component;
    expect(component.templateText, ''); // empty string due to summarization
    expect(component.templateUrlSource, isNotNull);
    expect(component.templateUrlSource, htmlSource);
    expect(component.templateSource, htmlSource);
    {
      final url = "'parts/my-template.html'";
      expect(component.templateUrlRange,
          SourceRange(partCode.indexOf(url), url.length));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_templateExternal() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', templateUrl: 'my-template.html')
class MyComponent {}
''';
    final dartSource = newSource('/test.dart', code);
    final htmlSource = newSource('/my-template.html', '');
    await getTemplates(dartSource);
    // MyComponent
    final component =
        getDirectiveByName(directives, 'MyComponent') as Component;
    expect(component.templateText, ''); // empty due to summarization
    expect(component.templateUrlSource, isNotNull);
    expect(component.templateUrlSource, htmlSource);
    expect(component.templateSource, htmlSource);
    {
      final url = "'my-template.html'";
      expect(component.templateUrlRange,
          SourceRange(code.indexOf(url), url.length));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_templateInline() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: 'my-directive')
class MyDirective {}

@Component(selector: 'other-component', template: 'Other template')
class OtherComponent {}

@Component(selector: 'my-component', template: 'My template',
    directives: const [MyDirective, OtherComponent])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    expect(templates, hasLength(2));
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      expect(
          component.templateText, ' My template '); // spaces preserve offsets
      expect(
          component.templateTextRange.offset, code.indexOf('My template') - 1);
      expect(component.templateUrlSource, isNull);
      expect(component.templateSource, source);
      {
        expect(component.directives, hasLength(2));
        final directiveClassNames = component.directives
            .map((directive) => (directive as Directive).classElement.name)
            .toList();
        expect(directiveClassNames,
            unorderedEquals(['OtherComponent', 'MyDirective']));
      }
    }
  }

  // ignore: non_constant_identifier_names
  Future test_useFunctionalDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: 'my-directive')
void myDirective() {}

@Component(selector: 'my-component', template: 'My template',
    directives: const [myDirective])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    errorListener.assertNoErrors();
    expect(templates, hasLength(1));
    final component = templates.single.component;
    expect(component.directives, hasLength(1));
    final directive = component.directives.single;
    expect(directive, isA<FunctionalDirective>());
    expect(
        (directive as FunctionalDirective).functionElement.name, 'myDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_useFunctionNotFunctionalDirective() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: 'My template',
    directives: const [notDirective])
class MyComponent {}

// put this after component, so indexOf works in assertErrorInCodeAtPosition
void notDirective() {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.FUNCTION_IS_NOT_A_DIRECTIVE, code, 'notDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_validFunctionalDirectivesList() async {
    final code = r'''
import 'package:angular/angular.dart';

@Directive(selector: '[aaa]')
void directiveA() {}

@Directive(selector: '[bbb]')
void directiveB() {}

const DIR_AB_DEEP = const [ const [ const [directiveA, directiveB]]];

@Component(selector: 'my-component', template: 'My template',
    directives: const [DIR_AB_DEEP])
class MyComponent {}
''';
    final source = newSource('/test.dart', code);
    await getTemplates(source);
    errorListener.assertNoErrors();
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      {
        expect(component.directives, hasLength(2));
        final directiveNames = component.directives
            .map((directive) =>
                (directive as FunctionalDirective).functionElement.name)
            .toList();
        expect(directiveNames, unorderedEquals(['directiveA', 'directiveB']));
      }
    }
  }
}

abstract class GatherAnnotationsTestMixin implements AngularDriverTestBase {
  List<DirectiveBase> directives;
  List<Pipe> pipes;
  List<AnalysisError> errors;

  Future getDirectives(final Source source) async {
    final dartResult = await dartDriver.getResult(source.fullName);
    fillErrorListener(dartResult.errors);
    final result = await angularDriver.requestDartResult(source.fullName);
    directives = result.directives;
    pipes = result.pipes;
    errors = result.errors;
    fillErrorListener(errors);
  }

  // ignore: non_constant_identifier_names
  Future test_hasContentChildrenDirective_worksInFuture() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class ComponentA {
  @ContentChildren(ContentChildComp)
  List<ContentChildComp> contentChildren;
}

@Component(selector: 'foo', template: '')
class ContentChildComp {}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first;
    final childrenFields = component.contentChildrenFields;
    expect(childrenFields, hasLength(1));
    final children = childrenFields.first;
    expect(children.fieldName, equals("contentChildren"));
    expect(
        children.nameRange.offset, equals(code.indexOf("ContentChildComp)")));
    expect(children.nameRange.length, equals("ContentChildComp".length));
    expect(children.typeRange.offset,
        equals(code.indexOf("List<ContentChildComp>")));
    expect(children.typeRange.length, equals("List<ContentChildComp>".length));
    // validate
    errorListener.assertNoErrors();
  }
}

@reflectiveTest
class ResolveDartTemplatesTest extends AngularDriverTestBase {
  List<DirectiveBase> directives;
  List<Template> templates;
  List<AnalysisError> errors;

  Future getDirectives(final Source source) async {
    final dartResult = await dartDriver.getResult(source.fullName);
    fillErrorListener(dartResult.errors);
    final ngResult = await angularDriver.requestDartResult(source.fullName);
    directives = ngResult.directives;
    errors = ngResult.errors;
    fillErrorListener(errors);
    templates = directives
        .map((d) => d is Component ? d.template : null)
        .where((d) => d != null)
        .toList();
  }

  // ignore: non_constant_identifier_names
  Future test_attributeNotString() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class MyComponent {
  MyComponent(@Attribute("my-attr") int foo);
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final attributes = component.attributes;
    expect(attributes, hasLength(1));
    {
      final attribute = attributes[0];
      expect(attribute.string, 'my-attr');
      // TODO better offsets here. But its really not that critical
      expect(attribute.navigationRange.offset, code.indexOf("foo"));
      expect(attribute.navigationRange.length, "foo".length);
    }
    assertErrorInCodeAtPosition(
        AngularWarningCode.ATTRIBUTE_PARAMETER_MUST_BE_STRING, code, 'foo');
  }

  // ignore: non_constant_identifier_names
  Future test_attributes() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '')
class MyComponent {
  MyComponent(@Attribute("my-attr") String foo);
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.single;
    final attributes = component.attributes;
    expect(attributes, hasLength(1));
    {
      final attribute = attributes[0];
      expect(attribute.string, 'my-attr');
      // TODO better offsets here. But its really not that critical
      expect(attribute.navigationRange.offset, code.indexOf("foo"));
      expect(attribute.navigationRange.length, "foo".length);
    }
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_cannotExportComponentClassItself() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '',
    exports: const [ComponentA])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.COMPONENTS_CANT_EXPORT_THEMSELVES,
        code,
        'ComponentA');
  }

  Future test_componentReference() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa', template: '<div>AAA</div>')
class ComponentA {
}

@Component(selector: 'my-bbb', template: '<div>BBB</div>')
class ComponentB {
}

@Component(selector: 'my-ccc', template: r"""
<div>
  <my-aaa></my-aaa>1
  <my-bbb></my-bbb>2
</div>
""", directives: const [ComponentA, ComponentB])
class ComponentC {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final componentA = getComponentByName(directives, 'ComponentA');
    final componentB = getComponentByName(directives, 'ComponentB');
    // validate
    expect(templates, hasLength(3));
    {
      final template = _getDartTemplateByClassName(templates, 'ComponentA');
      expect(template.ranges, isEmpty);
    }
    {
      final template = _getDartTemplateByClassName(templates, 'ComponentB');
      expect(template.ranges, isEmpty);
    }
    {
      final template = _getDartTemplateByClassName(templates, 'ComponentC');
      final ranges = template.ranges;
      expect(ranges, hasLength(4));
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'my-aaa></');
        assertComponentReference(resolvedRange, componentA);
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'my-aaa>1');
        assertComponentReference(resolvedRange, componentA);
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'my-bbb></');
        assertComponentReference(resolvedRange, componentB);
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'my-bbb>2');
        assertComponentReference(resolvedRange, componentB);
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_constantExpressionTemplateVarDoesntCrash() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

const String tplText = "we don't analyze this";

@Component(selector: 'aaa', template: tplText)
class ComponentA {
}
''');
    await getDirectives(source);
    expect(templates, hasLength(0));
    errorListener.assertErrorsWithCodes(
        <ErrorCode>[AngularHintCode.OFFSETS_CANNOT_BE_CREATED]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_expression_ArgumentTypeNotAssignable() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel',
    template: r"<div> {{text.length + text}} </div>")
class TextPanel {
  String text;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertErrorsWithCodes(
        [StaticWarningCode.ARGUMENT_TYPE_NOT_ASSIGNABLE]);
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_expression_UndefinedIdentifier() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"<div>some text</div>")
class TextPanel {
  @Input()
  String text;
}

@Component(selector: 'UserPanel', template: r"""
<div>
  <text-panel [text]='noSuchName'></text-panel>
</div>
""", directives: const [TextPanel])
class UserPanel {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener
        .assertErrorsWithCodes([StaticWarningCode.UNDEFINED_IDENTIFIER]);
  }

  Future
      // ignore: non_constant_identifier_names
      test_hasError_expression_UndefinedIdentifier_OutsideFirstHtmlTag() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '<h1></h1>{{noSuchName}}')
class MyComponent {
}
''';

    final source = newSource('/test.dart', code);
    await getDirectives(source);
    assertErrorInCodeAtPosition(
        StaticWarningCode.UNDEFINED_IDENTIFIER, code, 'noSuchName');
  }

  // ignore: non_constant_identifier_names
  Future test_hasError_UnresolvedTag() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa',
    template: "<unresolved-tag attr='value'></unresolved-tag>")
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    assertErrorInCodeAtPosition(
        AngularWarningCode.UNRESOLVED_TAG, code, 'unresolved-tag');
  }

  // ignore: non_constant_identifier_names
  Future test_hasExports() async {
    final code = r'''
import 'package:angular/angular.dart';

const String foo = 'foo';
int bar() { return 2; }
class MyClass {}

@Component(selector: 'my-component', template: '',
    exports: const [foo, bar, MyClass])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first as Component;
    expect(component, isNotNull);
    expect(component.exports, hasLength(3));
    {
      final export = component.exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo,')));
      expect(export.range.length, equals('foo'.length));
      final element = export.element as PropertyAccessorElement;
      expect(element.isGetter, isTrue);
      expect(element.name, equals('foo'));
      expect(element.returnType.toString(), equals('String'));
    }
    {
      final export = component.exports[1];
      expect(export.name, equals('bar'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('bar,')));
      expect(export.range.length, equals('bar'.length));
      final element = export.element as FunctionElement;
      expect(element.name, equals('bar'));
      expect(element.parameters, isEmpty);
      expect(element.returnType.toString(), equals('int'));
    }
    {
      final export = component.exports[2];
      expect(export.name, equals('MyClass'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('MyClass]')));
      expect(export.range.length, equals('MyClass'.length));
      expect(export.element.toString(), equals('class MyClass'));
    }
    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_hasWrongTypeOfPrefixedIdentifierExport() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '',
    exports: const [ComponentA.foo])
class ComponentA {
  static void foo(){}
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    assertErrorInCodeAtPosition(
        AngularWarningCode.EXPORTS_MUST_BE_PLAIN_IDENTIFIERS,
        code,
        'ComponentA.foo');
  }

  // ignore: non_constant_identifier_names
  Future test_htmlParsing_hasError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel',
    template: r"<div> <h2> Expected closing H2 </h3> </div>")
class TextPanel {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // has errors
    errorListener.assertErrorsWithCodes([
      NgParserWarningCode.DANGLING_CLOSE_ELEMENT,
      NgParserWarningCode.CANNOT_FIND_MATCHING_CLOSE,
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_input_OK_event() async {
    final code = r'''
import 'dart:html';
    import 'package:angular/angular.dart';

@Component(selector: 'UserPanel', template: r"""
<div>
  <input (click)='gotClicked($event)'>
</div>
""")
class TodoList {
  gotClicked(MouseEvent event) {}
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(templates, hasLength(1));
    {
      final template = _getDartTemplateByClassName(templates, 'TodoList');
      final ranges = template.ranges;
      expect(ranges, hasLength(4));
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, r'gotClicked($');
        expect(resolvedRange.range.length, 'gotClicked'.length);
        final element = (resolvedRange.navigable as DartElement).element;
        expect(element, isA<MethodElement>());
        expect(element.name, 'gotClicked');
        expect(
            element.nameOffset, code.indexOf('gotClicked(MouseEvent event)'));
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, r"$event)'>");
        expect(resolvedRange.range.length, r'$event'.length);
        final element = (resolvedRange.navigable as LocalVariable).dartVariable;
        expect(element, isA<LocalVariableElement>());
        expect(element.name, r'$event');
        expect(element.nameOffset, -1);
      }
      {
        final resolvedRange = getResolvedRangeAtString(code, ranges, 'click');
        expect(resolvedRange.range.length, 'click'.length);
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_input_OK_reference_expression() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"<div>some text</div>")
class TextPanel {
  @Input()
  String text;
}

@Component(selector: 'UserPanel', template: r"""
<div>
  <text-panel [text]='user.name'></text-panel>
</div>
""", directives: const [TextPanel])
class UserPanel {
  User user; // 1
}

class User {
  String name; // 2
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final textPanel = getComponentByName(directives, 'TextPanel');
    // validate
    expect(templates, hasLength(2));
    {
      final template = _getDartTemplateByClassName(templates, 'UserPanel');
      final ranges = template.ranges;
      expect(ranges, hasLength(5));
      {
        final resolvedRange = getResolvedRangeAtString(code, ranges, 'text]=');
        expect(resolvedRange.range.length, 'text'.length);
        assertPropertyReference(resolvedRange, textPanel, 'text');
      }
      {
        final resolvedRange = getResolvedRangeAtString(code, ranges, 'user.');
        expect(resolvedRange.range.length, 'user'.length);
        final element = (resolvedRange.navigable as DartElement).element;
        expect(element, isA<PropertyAccessorElement>());
        expect(element.name, 'user');
        expect(element.nameOffset, code.indexOf('user; // 1'));
      }
      {
        final resolvedRange = getResolvedRangeAtString(code, ranges, "name'>");
        expect(resolvedRange.range.length, 'name'.length);
        final element = (resolvedRange.navigable as DartElement).element;
        expect(element, isA<PropertyAccessorElement>());
        expect(element.name, 'name');
        expect(element.nameOffset, code.indexOf('name; // 2'));
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_input_OK_reference_text() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(
    selector: 'comp-a',
    template: r"<div>AAA</div>")
class ComponentA {
  @Input()
  int firstValue;
  @Input()
  int second;
}

@Component(selector: 'comp-b', template: r"""
<div>
  <comp-a [firstValue]='1' [second]='2'></comp-a>
</div>
""", directives: const [ComponentA])
class ComponentB {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final componentA = getComponentByName(directives, 'ComponentA');
    // validate
    expect(templates, hasLength(2));
    {
      final template = _getDartTemplateByClassName(templates, 'ComponentB');
      final ranges = template.ranges;
      expect(ranges, hasLength(4));
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'firstValue]=');
        expect(resolvedRange.range.length, 'firstValue'.length);
        assertPropertyReference(resolvedRange, componentA, 'firstValue');
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'second]=');
        expect(resolvedRange.range.length, 'second'.length);
        assertPropertyReference(resolvedRange, componentA, 'second');
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_misspelledPrefixSuppressesWrongPrefixTypeError() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-component', template: '',
    exports: const [garbage.garbage])
class ComponentA {
  static void foo(){}
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // validate
    errorListener.assertErrorsWithCodes(<ErrorCode>[
      StaticWarningCode.UNDEFINED_IDENTIFIER,
      CompileTimeErrorCode.CONST_WITH_NON_CONSTANT_ARGUMENT,
      CompileTimeErrorCode.NON_CONSTANT_LIST_ELEMENT
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_noRootElement() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel',
    template: r'Often used without an element in tests.')
class TextPanel {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(templates, hasLength(1));
    // has errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_noTemplateContents() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel',
    template: '')
class TextPanel {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(templates, hasLength(1));
    // has errors
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_prefixedExport() async {
    newSource('/prefixed.dart', 'const double foo = 2.0;');
    final code = r'''
import 'package:angular/angular.dart';
import '/prefixed.dart' as prefixed;

const int foo = 2;

@Component(selector: 'my-component', template: '',
    exports: const [prefixed.foo, foo])
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    final component = directives.first as Component;
    expect(component.exports, hasLength(2));
    {
      final export = component.exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals('prefixed'));
      expect(export.range.offset, equals(code.indexOf('prefixed.foo')));
      expect(export.range.length, equals('prefixed.foo'.length));
      final element = export.element as PropertyAccessorElement;
      expect(element.isGetter, isTrue);
      expect(element.name, equals('foo'));
      expect(element.returnType.toString(), equals('double'));
    }
    {
      final export = component.exports[1];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo]')));
      expect(export.range.length, equals('foo'.length));
      final element = export.element as PropertyAccessorElement;
      expect(element.isGetter, isTrue);
      expect(element.name, equals('foo'));
      expect(element.returnType.toString(), equals('int'));
    }

    // validate
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_resolveGetChildDirectivesNgContentSelectors() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'child_file.dart';

@Component(selector: 'my-component', template: 'My template',
    directives: const [ChildComponent])
class MyComponent {}
''';
    final childCode = r'''
import 'package:angular/angular.dart';
@Component(selector: 'child-component',
    template: 'My template <ng-content></ng-content>',
    directives: const [])
class ChildComponent {}
''';
    final source = newSource('/test.dart', code);
    newSource('/child_file.dart', childCode);

    // do this twice to confirm cache result is correct as well.
    for (var i = 0; i < 2; ++i) {
      await getDirectives(source);
      expect(templates, hasLength(1));
      // no errors
      errorListener.assertNoErrors();

      final childDirectives = templates.first.component.directives;
      expect(childDirectives, hasLength(1));

      final childComponents = childDirectives.whereType<Component>().toList();
      expect(childComponents, hasLength(1));
      final childComponent = childComponents.first;
      expect(childComponent.ngContents, hasLength(1));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_resolveGetChildDirectivesNgContentSelectors_templateUrl() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'child_file.dart';

@Component(selector: 'my-component', template: 'My template',
    directives: const [ChildComponent])
class MyComponent {}
''';
    final childCode = r'''
import 'package:angular/angular.dart';
@Component(selector: 'child-component',
    templateUrl: 'child_file.html',
    directives: const [])
class ChildComponent {}
''';
    final source = newSource('/test.dart', code);
    newSource('/child_file.dart', childCode);
    newSource('/child_file.html', 'My template <ng-content></ng-content>');

    // do this twice to confirm cache result is correct as well.
    for (var i = 0; i < 2; ++i) {
      await getDirectives(source);
      expect(templates, hasLength(1));
      // no errors
      errorListener.assertNoErrors();

      final childDirectives = templates.first.component.directives;
      expect(childDirectives, hasLength(1));

      final childComponents = childDirectives.whereType<Component>().toList();
      expect(childComponents, hasLength(1));
      final childComponent = childComponents.first;
      expect(childComponent.ngContents, hasLength(1));
    }
  }

  // ignore: non_constant_identifier_names
  Future test_suppressError_NotCaseSensitive() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa',
    template: """
<!-- @ngIgnoreErrors: UnReSoLvEd_tAg -->
<unresolved-tag attr='value'></unresolved-tag>""")
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_suppressError_UnresolvedTag() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa',
    template: """
<!-- @ngIgnoreErrors: UNRESOLVED_TAG -->
<unresolved-tag attr='value'></unresolved-tag>""")
class ComponentA {
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_suppressError_UnresolvedTagAndInput() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa',
    template: """
<!-- @ngIgnoreErrors: UNRESOLVED_TAG, NONEXIST_INPUT_BOUND -->
<unresolved-tag [attr]='value'></unresolved-tag>""")
class ComponentA {
  Object value;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertNoErrors();
  }

  // ignore: non_constant_identifier_names
  Future test_textExpression_hasError_DoubleOpenedMustache() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"<div> {{text {{ error}} </div>")
class TextPanel {
  String text;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertErrorsWithCodes([
      NgParserWarningCode.UNTERMINATED_MUSTACHE,
      StaticWarningCode.UNDEFINED_IDENTIFIER
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_textExpression_hasError_MultipleUnclosedMustaches() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"<div> {{open {{error {{text}} close}} close}} </div>")
class TextPanel {
  String text, open, close;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    errorListener.assertErrorsWithCodes([
      NgParserWarningCode.UNTERMINATED_MUSTACHE,
      NgParserWarningCode.UNTERMINATED_MUSTACHE,
      StaticWarningCode.UNDEFINED_IDENTIFIER,
      NgParserWarningCode.UNOPENED_MUSTACHE,
      NgParserWarningCode.UNOPENED_MUSTACHE,
    ]);
  }

  // ignore: non_constant_identifier_names
  Future test_textExpression_hasError_UnopenedMustache() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"<div> text}} </div>")
class TextPanel {
  String text;
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // has errors
    errorListener
        .assertErrorsWithCodes([NgParserWarningCode.UNOPENED_MUSTACHE]);
  }

  // ignore: non_constant_identifier_names
  Future test_textExpression_hasError_UnterminatedMustache() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', template: r"{{text")
class TextPanel {
  String text = "text";
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    // has errors
    errorListener
        .assertErrorsWithCodes([NgParserWarningCode.UNTERMINATED_MUSTACHE]);
  }

  // ignore: non_constant_identifier_names
  Future test_textExpression_OK() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel',
    template: r"<div> <h2> {{text}}  </h2> and {{text.length}} </div>")
class TextPanel {
  String text; // 1
}
''';
    final source = newSource('/test.dart', code);
    await getDirectives(source);
    expect(templates, hasLength(1));
    {
      final template = _getDartTemplateByClassName(templates, 'TextPanel');
      final ranges = template.ranges;
      expect(ranges, hasLength(5));
      {
        final resolvedRange = getResolvedRangeAtString(code, ranges, 'text}}');
        expect(resolvedRange.range.length, 'text'.length);
        final element = assertGetter(resolvedRange);
        expect(element.name, 'text');
        expect(element.nameOffset, code.indexOf('text; // 1'));
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'text.length');
        expect(resolvedRange.range.length, 'text'.length);
        final element = assertGetter(resolvedRange);
        expect(element.name, 'text');
        expect(element.nameOffset, code.indexOf('text; // 1'));
      }
      {
        final resolvedRange =
            getResolvedRangeAtString(code, ranges, 'length}}');
        expect(resolvedRange.range.length, 'length'.length);
        final element = assertGetter(resolvedRange);
        expect(element.name, 'length');
        expect(element.enclosingElement.name, 'String');
      }
    }
    // no errors
    errorListener.assertNoErrors();
  }

  static Template _getDartTemplateByClassName(
          List<Template> templates, String className) =>
      templates.firstWhere(
          (template) => template.component.classElement.name == className,
          orElse: () {
        fail('Template with the class "$className" was not found.');
      });
}

@reflectiveTest
class ResolveHtmlTemplatesTest extends AngularDriverTestBase {
  List<Template> templates;
  Future getDirectives(Source htmlSource, List<Source> dartSources) async {
    for (final dartSource in dartSources) {
      final result = await angularDriver.requestDartResult(dartSource.fullName);
      fillErrorListener(result.errors);
    }
    final result2 = await angularDriver.requestHtmlResult(htmlSource.fullName);
    fillErrorListener(result2.errors);
    templates = result2.directives
        .map((d) => d is Component ? d.template : null)
        .where((d) => d != null)
        .toList();
  }

  // ignore: non_constant_identifier_names
  Future test_multipleViewsWithTemplate() async {
    final dartCodeOne = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panelA', templateUrl: 'text_panel.html')
class TextPanelA {
  String text; // A
}
''';

    final dartCodeTwo = r'''
import '/angular/angular.dart';

@Component(selector: 'text-panelB', templateUrl: 'text_panel.html')
class TextPanelB {
  String text; // B
}
''';
    final htmlCode = r"""
<div>
  {{text}}
</div>
""";
    final dartSourceOne = newSource('/test1.dart', dartCodeOne);
    final dartSourceTwo = newSource('/test2.dart', dartCodeTwo);
    final htmlSource = newSource('/text_panel.html', htmlCode);
    await getDirectives(htmlSource, [dartSourceOne, dartSourceTwo]);
    expect(templates, hasLength(2));
    // validate templates
    var hasTextPanelA = false;
    var hasTextPanelB = false;
    for (final template in templates) {
      final componentClassName = template.component.classElement.name;
      int textLocation;
      if (componentClassName == 'TextPanelA') {
        hasTextPanelA = true;
        textLocation = dartCodeOne.indexOf('text; // A');
      }
      if (componentClassName == 'TextPanelB') {
        hasTextPanelB = true;
        textLocation = dartCodeTwo.indexOf('text; // B');
      }
      expect(template.ranges, hasLength(1));
      {
        final resolvedRange =
            getResolvedRangeAtString(htmlCode, template.ranges, 'text}}');
        final element = assertGetter(resolvedRange);
        expect(element.name, 'text');
        expect(element.nameOffset, textLocation);
      }
    }
    expect(hasTextPanelA, isTrue);
    expect(hasTextPanelB, isTrue);
  }
}

@reflectiveTest
class ResolveHtmlTemplateTest extends AngularDriverTestBase {
  List<Template> templates;
  List<DirectiveBase> directives;
  Future getDirectives(Source htmlSource, Source dartSource) async {
    final result = await angularDriver.requestDartResult(dartSource.fullName);
    fillErrorListener(result.errors);
    final result2 = await angularDriver.requestHtmlResult(htmlSource.fullName);
    fillErrorListener(result2.errors);
    directives = result2.directives;
    templates = result2.directives
        .map((d) => d is Component ? d.template : null)
        .where((v) => v != null)
        .toList();
  }

  // ignore: non_constant_identifier_names
  Future test_contentChildAnnotatedConstructor() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'a', templateUrl: 'test.html')
class A {
  @ContentChild(X)
  A(){}
}
''';
    final dartSource = newSource('/test.dart', code);
    final htmlSource = newSource('/test.html', '');
    await getDirectives(htmlSource, dartSource);

    final component = directives.first as Component;

    expect(component.contentChildFields, hasLength(0));
  }

  // ignore: non_constant_identifier_names
  Future test_errorFromWeirdInclude_includesFromPath() async {
    final code = r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa', templateUrl: "test.html")
class WeirdComponent {
}
''';
    final dartSource = newSource('/weird.dart', code);
    final htmlSource =
        newSource('/test.html', "<unresolved-tag></unresolved-tag>");
    await getDirectives(htmlSource, dartSource);
    final errors = errorListener.errors;
    expect(errors, hasLength(1));
    expect(
        errors.first.message,
        equals('In WeirdComponent:'
            ' Unresolved tag "unresolved-tag" (from /weird.dart)'));
  }

  // ignore: non_constant_identifier_names
  Future test_hasView_withTemplate_relativeToLibForParts() async {
    final libCode = r'''
import 'package:angular/angular.dart';
part 'parts/part.dart';
    ''';
    final partCode = r'''
part of '../lib.dart';
@Component(selector: 'my-component', templateUrl: 'parts/my-template.html')
class MyComponent {
  String text; // 1
}
''';
    final htmlCode = r'''
<div>
  {{text}}
</div>
''';
    newSource('/lib.dart', libCode);
    final dartPartSource = newSource('/parts/part.dart', partCode);
    final htmlSource = newSource('/parts/my-template.html', htmlCode);
    await getDirectives(htmlSource, dartPartSource);
    errorListener.assertNoErrors();
    expect(templates, hasLength(1));
    {
      final component =
          getDirectiveByName(directives, 'MyComponent') as Component;
      expect(component.templateUrlSource, isNotNull);
      // resolve this View
      final template = component.template;
      expect(template, isNotNull);
      expect(template.component, component);
      expect(template.ranges, hasLength(1));
      {
        final resolvedRange =
            getResolvedRangeAtString(htmlCode, template.ranges, 'text}}');
        final element = assertGetter(resolvedRange);
        expect(element.name, 'text');
        expect(element.nameOffset, partCode.indexOf('text; // 1'));
      }
    }
  }

  // ignore: non_constant_identifier_names
  Future test_hasViewWithTemplate() async {
    final dartCode = r'''
import 'package:angular/angular.dart';

@Component(selector: 'text-panel', templateUrl: 'text_panel.html')
class TextPanel {
  String text; // 1
}
''';
    final htmlCode = r"""
<div>
  {{text}}
</div>
""";
    final dartSource = newSource('/test.dart', dartCode);
    final htmlSource = newSource('/text_panel.html', htmlCode);
    // compute
    await getDirectives(htmlSource, dartSource);
    expect(templates, hasLength(1));
    {
      final component =
          getDirectiveByName(directives, 'TextPanel') as Component;
      expect(component.templateUrlSource, isNotNull);
      // resolve this View
      final template = component.template;
      expect(template, isNotNull);
      expect(template.component, component);
      expect(template.ranges, hasLength(1));
      {
        final resolvedRange =
            getResolvedRangeAtString(htmlCode, template.ranges, 'text}}');
        final element = assertGetter(resolvedRange);
        expect(element.name, 'text');
        expect(element.nameOffset, dartCode.indexOf('text; // 1'));
      }
    }
  }

  // ignore: non_constant_identifier_names
  Future test_lazyLinkResolve() async {
    final dartSource = newSource('/test_panel.dart', r'''
import 'package:angular/angular.dart';
import 'not_necessary_to_resolve.dart';
@Component(selector: 'test-panel', templateUrl: 'test_panel.html',
    directives: const [
      NotNecessaryToResolve,
      NotNecessaryToResolveDirective,
    ],
    pipes: const [NotNecessaryToResolvePipe])
class TestPanel {
}''');

    newSource('/not_necessary_to_resolve.dart', r'''
import 'package:angular/angular.dart';
@Component(selector: 'not-necessary-to-resolve', template: '')
class NotNecessaryToResolve {
}
@Directive(selector: 'not-necessary-to-resolve-directive')
class NotNecessaryToResolveDirective {
}

@Pipe('notNecessary')
class NotNecessaryToResolvePipe {}
''');
    final htmlSource = newSource('/test_panel.html', r"""
<div></div>
    """);

    await getDirectives(dartSource, htmlSource);
    await angularDriver.requestHtmlResult('/test_panel.html');

    final component = directives.single as Component;
    final subdirectives = component.directives;
    expect(component.directives, hasLength(2));

    final subcomponent = subdirectives[0];
    expect(subcomponent, isA<lazy.Component>());
    final lazysubcomponent = subcomponent as lazy.Component;
    expect(lazysubcomponent.isLinked, false);

    final subdirective = subdirectives[1];
    expect(subdirective, isA<lazy.Directive>());
    final lazysubdirective = subdirective as lazy.Directive;
    expect(lazysubdirective.isLinked, false);

    expect(component.pipes, hasLength(1));

    final pipe = component.pipes[0];
    expect(pipe, isA<lazy.Pipe>());
    final lazypipe = pipe as lazy.Pipe;
    expect(lazypipe.isLinked, false);
  }

  // ignore: non_constant_identifier_names
  Future test_resolveGetChildDirectivesNgContentSelectors() async {
    final code = r'''
import 'package:angular/angular.dart';
import 'child_file.dart';

import 'package:angular/angular.dart';
@Component(selector: 'my-component', templateUrl: 'test.html',
    directives: const [ChildComponent])
class MyComponent {}
''';
    final childCode = r'''
import 'package:angular/angular.dart';
@Component(selector: 'child-component',
    template: 'My template <ng-content></ng-content>',
    directives: const [])
class ChildComponent {}
''';
    final dartSource = newSource('/test.dart', code);
    newSource('/child_file.dart', childCode);
    final htmlSource = newSource('/test.html', '');
    await getDirectives(htmlSource, dartSource);

    final childDirectives = (directives.first as Component).directives;
    expect(childDirectives, hasLength(1));

    final childComponent = childDirectives.first as Component;
    expect(childComponent.ngContents, hasLength(1));
  }

  // ignore: non_constant_identifier_names
  Future test_suppressError_UnresolvedTagHtmlTemplate() async {
    final dartSource = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Component(selector: 'my-aaa', templateUrl: 'test.html')
class ComponentA {
}
''');
    final htmlSource = newSource('/test.html', '''
<!-- @ngIgnoreErrors: UNRESOLVED_TAG -->
<unresolved-tag attr='value'></unresolved-tag>""")
''');
    await getDirectives(htmlSource, dartSource);
    errorListener.assertNoErrors();
  }
}
