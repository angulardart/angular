import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/component.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/functional_directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/pipe.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/top_level.dart';
import 'package:angular_analyzer_plugin/src/selector/and_selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:angular_analyzer_plugin/src/syntactic_discovery.dart';

import 'angular_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SyntacticDiscoveryTest);
  });
}

Component getComponentByName(List<DirectiveBase> directives, String name) =>
    getDirectiveByName(directives, name) as Component;

Directive getDirectiveByName(List<DirectiveBase> directives, String name) =>
    directives
        .whereType<Directive>()
        .firstWhere((directive) => directive.className == name, orElse: () {
      fail('DirectiveMetadata with the class "$name" was not found.');
    });

@reflectiveTest
class SyntacticDiscoveryTest extends AngularTestBase {
  List<TopLevel> topLevels;
  List<DirectiveBase> directives;
  List<Pipe> pipes;
  List<AnalysisError> errors;

  Future getDirectives(final Source source) async {
    final dartResult = await dartDriver.getResult(source.fullName);
    fillErrorListener(dartResult.errors);
    final extractor = SyntacticDiscovery(dartResult.unit, source);
    topLevels = extractor.discoverTopLevels();
    directives = topLevels.whereType<DirectiveBase>().toList();
    pipes = topLevels.whereType<Pipe>().toList();
    fillErrorListener(extractor.errorListener.errors);
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
      expect(component.exportAs, 'export-name');
      expect(component.exportAsRange.offset, code.indexOf('export-name'));
    }
    {
      final component = getComponentByName(directives, 'ComponentB');
      final exportAs = component.exportAs;
      expect(exportAs, isNull);
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
      expect(directive.exportAs, 'export-name');
      expect(directive.exportAsRange.offset, code.indexOf('export-name'));
    }
    {
      final directive = getDirectiveByName(directives, 'DirectiveB');
      expect(directive.exportAs, isNull);
      expect(directive.exportAsRange, isNull);
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
  Future test_FunctionalDirective() async {
    final source = newSource('/test.dart', r'''
import 'package:angular/angular.dart';

@Directive(selector: 'dir-a.myClass[myAttr]')
void directiveA() {
}
''');
    await getDirectives(source);
    expect(directives, hasLength(1));
    final directive = directives.single as FunctionalDirective;
    expect(directive.functionName, "directiveA");
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
    final component = directives.first as Component;
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
    final component = directives.first as Component;

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
    final component = directives.first as Component;
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
    final component = directives.first as Component;
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
    expect(component.exports, isA<ListLiteral>());
    final exports = (component.exports as ListLiteral).items;
    expect(exports, hasLength(3));
    {
      final export = exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo,')));
      expect(export.range.length, equals('foo'.length));
    }
    {
      final export = exports[1];
      expect(export.name, equals('bar'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('bar,')));
      expect(export.range.length, equals('bar'.length));
    }
    {
      final export = exports[2];
      expect(export.name, equals('MyClass'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('MyClass]')));
      expect(export.range.length, equals('MyClass'.length));
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
    final component = directives.single as Component;
    final inputs = component.inputs;
    expect(inputs, hasLength(3));
    {
      final input = inputs[0];
      expect(input.name, 'firstField');
      expect(input.nameRange.offset, code.indexOf('firstField'));
      expect(input.nameRange.length, 'firstField'.length);
      expect(input.setterRange.offset, input.nameRange.offset);
      expect(input.setterRange.length, input.name.length);
    }
    {
      final input = inputs[1];
      expect(input.name, 'secondInput');
      expect(input.nameRange.offset, code.indexOf('secondInput'));
      expect(input.setterRange.offset, code.indexOf('secondField'));
      expect(input.setterRange.length, 'secondField'.length);
    }
    {
      final input = inputs[2];
      expect(input.name, 'someSetter');
      expect(input.nameRange.offset, code.indexOf('someSetter'));
      expect(input.setterRange.offset, input.nameRange.offset);
      expect(input.setterRange.length, input.name.length);
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
    final component = directives.single as Component;
    final compOutputs = component.outputs;
    expect(compOutputs, hasLength(3));
    {
      final output = compOutputs[0];
      expect(output.name, 'outputOne');
      expect(output.nameRange.offset, code.indexOf('outputOne'));
      expect(output.nameRange.length, 'outputOne'.length);
      expect(output.getterRange.offset, output.nameRange.offset);
      expect(output.getterRange.length, output.nameRange.length);
    }
    {
      final output = compOutputs[1];
      expect(output.name, 'outputTwo');
      expect(output.nameRange.offset, code.indexOf('outputTwo'));
      expect(output.getterRange.offset, code.indexOf('secondOutput'));
      expect(output.getterRange.length, 'secondOutput'.length);
    }
    {
      final output = compOutputs[2];
      expect(output.name, 'someGetter');
      expect(output.nameRange.offset, code.indexOf('someGetter'));
      expect(output.getterRange.offset, output.nameRange.offset);
      expect(output.getterRange.length, output.name.length);
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

@Pipe('pipeB', pure: false)
class PipeB extends PipeTransform {
  String transform(int a1, String a2, bool a3) => 'someString';
}
''');
    await getDirectives(source);
    expect(pipes, hasLength(2));
    {
      final pipe = pipes[0];
      expect(pipe, isA<Pipe>());
      expect(pipe.pipeName, 'pipeA');
    }
    {
      final pipe = pipes[1];
      expect(pipe, isA<Pipe>());
      expect(pipe.pipeName, 'pipeB');
    }
    errorListener.assertNoErrors();
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

    errorListener
        .assertErrorsWithCodes([AngularWarningCode.PIPE_CANNOT_BE_ABSTRACT]);
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
    expect(component.exports, isA<ListLiteral>());
    final exports = (component.exports as ListLiteral).items;
    expect(exports, hasLength(2));
    {
      final export = exports[0];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals('prefixed'));
      expect(export.range.offset, equals(code.indexOf('prefixed.foo')));
      expect(export.range.length, equals('prefixed.foo'.length));
    }
    {
      final export = exports[1];
      expect(export.name, equals('foo'));
      expect(export.prefix, equals(''));
      expect(export.range.offset, equals(code.indexOf('foo]')));
      expect(export.range.length, equals('foo'.length));
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
