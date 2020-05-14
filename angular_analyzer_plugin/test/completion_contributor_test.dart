import 'dart:async';

import 'package:analyzer_plugin/utilities/completion/relevance.dart';
import 'package:angular_analyzer_plugin/src/completion/template_completer.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_test_util.dart';

void main() {
  defineReflectiveTests(DartCompletionContributorTest);
  defineReflectiveTests(HtmlCompletionContributorTest);
}

@reflectiveTest
class DartCompletionContributorTest extends AbstractCompletionContributorTest {
  @override
  Future<void> setUp() async {
    testFile = '/completionTest.dart';
    await super.setUp();
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_beginning() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<^<div></div>', selector: 'my-parent', directives: const[MyChildComponent1, MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_beginning_with_partial() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<my^<div></div>', selector: 'my-parent', directives: const[MyChildComponent1, MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<my'.length);
    expect(replacementLength, '<my'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_end() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div></div></div><^', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_end_after_close() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div></div></div>^', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_end_with_partial() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div></div></div><m^', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<m'.length);
    expect(replacementLength, '<m'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_middle() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div><^</div></div>', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_middle_of_text() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div> some text<^</div></div>', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_at_middle_with_partial() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div><div><my^</div></div>', selector: 'my-parent', directives: const[MyChildComponent1, MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<my'.length);
    expect(replacementLength, '<my'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_in_middle_of_unclosed_tag() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<div>some text<^', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInlineHtmlSelectorTag_on_empty_document() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '^', selector: 'my-parent', directives: const[MyChildComponent1,MyChildComponent2])
class MyParentComponent{}
@Component(template: '', selector: 'my-child1, my-child2')
class MyChildComponent1{}
@Component(template: '', selector: 'my-child3.someClass[someAttr]')
class MyChildComponent2{}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInput_as_plainAttribute() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag ^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Input() int intInput;
  @Output() Stream<String> myEvent;

  bool _myDynamicInput = false;
  bool get myDynamicInput => _myDynamicInput;
  @Input()
  void set myDynamicInput(value) {}
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('stringInput');
    assertNotSuggested('intInput');
    assertSuggestSetter('myDynamicInput',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputNotStarted_at_incompleteTag_with_newTag() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag ^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[stringInput]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_at_incompleteTag_with_EOF() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag [^', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[stringInput]');
    assertNotSuggested('(myEvent)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_at_incompleteTag_with_newTag() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag [^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[stringInput]');
    assertNotSuggested('(myEvent)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInAttrBinding() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<h1 [attr.on-click]="^"></h1>', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInClassBinding() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<h1 [class.my-class]="^"></h1>', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInInputBinding() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<h1 [hidden]="^"></h1>', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInInputOutput_at_incompleteTag_with_EOF() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag ^', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[stringInput]');
    assertSuggestGetter('(myEvent)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInInputOutput_at_incompleteTag_with_newTag() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag ^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[stringInput]');
    assertSuggestGetter('(myEvent)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInMustache() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '{{^}}', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInStyleBinding() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<h1 [style.background-color]="^"></h1>', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberMustacheAttrBinding() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<h1 title="{{^}}"></h1>', selector: 'a')
class MyComp {
  String text;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMultipleMembers() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '{{d^}}', selector: 'a')
class MyComp {
  String text;
  String description;
}
    ''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestGetter('text', 'String');
    assertSuggestGetter('description', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputStarted_at_incompleteTag_with_EOF() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag (^', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('[stringInput]');
    assertSuggestGetter('(myEvent)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputStarted_at_incompleteTag_with_newTag() async {
    addTestSource('''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(template: '<child-tag (^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
  @Input() String stringInput;
  @Output() Stream<String> myEvent;
}
    ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('[stringInput]');
    assertSuggestGetter('(myEvent)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutsideTemplateOK() async {
    addTestSource('''
import 'package:angular/angular.dart';
class MyComp {
  String text = ^;
}
    ''');

    await computeSuggestions();
  }

  // ignore: non_constant_identifier_names
  Future test_completeStandardInput_as_plainAttribute() async {
    addTestSource('''
import 'package:angular/angular.dart';
@Component(template: '<child-tag ^<div></div>', selector: 'my-tag',
directives: const [MyChildComponent])
class MyComponent {}
@Component(template: '', selector: 'child-tag')
class MyChildComponent {
}
  }
  ''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[id]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestSetter('id', relevance: DART_RELEVANCE_DEFAULT - 2);
  }
}

@reflectiveTest
class HtmlCompletionContributorTest extends AbstractCompletionContributorTest {
  void assertSuggestTransclusion(String name) {
    assertSuggestClassTypeAlias(name,
        relevance: TemplateCompleter.RELEVANCE_TRANSCLUSION);
  }

  // ignore: non_constant_identifier_names
  @override
  Future<void> setUp() async {
    testFile = '/completionTest.html';
    await super.setUp();
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_banana_noInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {
  @Input()
  String foo;
  @Output()
  Stream<String> myDirectiveChange;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('myDirective');
    assertNotSuggested('[foo]');
    assertNotSuggested('(myDirectiveChange)');
    assertNotSuggested('[(myDirective)]');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_begin() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('myDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_complete() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective, MyDirectiveTwo])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {}
@Directive(selector: '[myDirectiveTwo]')
class MyDirectiveTwo {}
    ''');

    addTestSource('<my-tag ^myDirective></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 'myDirective'.length);
    assertSuggestSetter('myDirectiveTwo');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_middle() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {}
    ''');

    addTestSource('<my-tag myDi^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 'myDi'.length);
    expect(replacementLength, 'myDi'.length);
    assertSuggestSetter('myDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_and() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective][foo][bar]')
class MyDirective {}
    ''');

    addTestSource('<my-tag foo ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('myDirective');
    assertNotSuggested('foo');
    assertSuggestSetter('bar');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_attrValue1() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[foo=bar][baz]')
class MyDirective {}
    ''');

    addTestSource('<my-tag foo="blah" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertNotSuggested('baz');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_attrValue2() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[foo=bar][baz]')
class MyDirective {}
    ''');

    addTestSource('<my-tag foo="bar" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('foo');
    assertSuggestSetter('baz');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_matchBanana() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective],[foo],[bar]')
class MyDirective {
  @Input()
  String myDirective;
  @Output()
  Stream<String> myDirectiveChange;
}
    ''');
    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('myDirective');
    assertSuggestSetter('[myDirective]');
    assertNotSuggested('(myDirective)');
    assertSuggestSetter('[(myDirective)]', returnType: 'String');
    assertSuggestSetter('foo');
    assertSuggestSetter('bar');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_matchInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective],[foo],[bar]')
class MyDirective {
  @Input()
  String myDirective;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('myDirective');
    assertSuggestSetter('[myDirective]');
    assertSuggestSetter('foo');
    assertSuggestSetter('bar');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_or() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective],[foo],[bar]')
class MyDirective {}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('myDirective');
    assertSuggestSetter('foo');
    assertSuggestSetter('bar');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_multipleAttribute_or_matchOne() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective],[foo],[bar]')
class MyDirective {}
    ''');

    addTestSource('<my-tag foo ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('myDirective');
    assertNotSuggested('bar');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_sharedBanana() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {
  @Input()
  String myDirective;
  @Output()
  Stream<String> myDirectiveChange;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('myDirective');
    assertSuggestSetter('[myDirective]');
    assertNotSuggested('(myDirective)');
    assertSuggestSetter('[(myDirective)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_sharedInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {
  @Input()
  String myDirective;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('myDirective');
    assertSuggestSetter('[myDirective]');
  }

  // ignore: non_constant_identifier_names
  Future test_availDirective_attribute_unsharedInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
class MyDirective {
  @Input()
  String foo;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[foo]');
    assertSuggestSetter('myDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_availFunctionalDirective_attribute_begin() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, myDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]')
void myDirective() {}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('myDirective');
  }

  // ignore: non_constant_identifier_names
  Future test_completeAfterExportedPrefixes() async {
    newSource('/prefixed.dart', '''
const int foo = 1;
const int bar = 1;
''');
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
import 'prefixed.dart' as prefixed;
const int baz = 2;
@Component(templateUrl: 'completionTest.html', selector: 'a', exports: const [
  prefixed.foo,
])
class MyComp {
}
    ''');

    addTestSource('{{prefixed.^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('foo', 'int');
    assertNotSuggested('bar');
    assertNotSuggested('baz');
    assertNotSuggested('MyComp');
    assertNotSuggested('hashCode');
    assertNotSuggested('toString()');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaNotStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
    assertSuggestGetter('(nameChange)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaNotSuggested_after_inputUsed() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [name]="\'bob\'" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertSuggestGetter('(nameChange)', 'String');
    assertNotSuggested('[(name)]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaNotSuggested_after_outputUsed() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag (nameChange)="" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertNotSuggested('(nameChange)');
    assertNotSuggested('[(name)]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaNotSuggestedTwice() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(name)]="\'bob\'" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertNotSuggested('(nameChange)');
    assertNotSuggested('[(name)]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaReplacing() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;

  @Input() String codename;
  @Output() Stream<String> codenameChange;
}
    ''');

    addTestSource('<my-tag [(^name)]></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, '[(name)]'.length);
    assertNotSuggested('[name]');
    assertNotSuggested('(nameChange)');
    assertNotSuggested('[codename]');
    assertNotSuggested('(codenameChange)');
    assertSuggestSetter('[(name)]', returnType: 'String');
    assertSuggestSetter('[(codename)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted1() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
    assertNotSuggested('(nameChange)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted1_at_incompleteTag_with_EOF() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('(nameChange)');
    assertSuggestSetter('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted2() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
    assertNotSuggested('(nameChange)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted2_at_incompleteTag_with_EOF() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);
    assertNotSuggested('(nameChange)');
    assertNotSuggested('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted_at_incompleteTag_bananaStart() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(^<div></div>');
    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 2);
    expect(replacementLength, 2);

    assertNotSuggested('(nameChange)');
    assertNotSuggested('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaStarted_at_incompleteTag_bracketStart() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [^<div></div>');
    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);

    assertNotSuggested('(nameChange)');
    assertSuggestSetter('[name]');
    assertSuggestSetter('[(name)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBananaSuggestsItself() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(name^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 6);
    expect(replacementLength, 6);
    assertNotSuggested('[name]');
    assertNotSuggested('(nameChange)');
    assertSuggestSetter('[(name)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeBeforeComment() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
class MyClass{}
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {}
    ''');

    addTestSource('^<!-- comment! -->');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
  }

  // ignore: non_constant_identifier_names
  Future test_completeCurrentClass() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('{{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('MyComp');
  }

  // ignore: non_constant_identifier_names
  Future test_completeDotMemberAlreadyStartedInMustache() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('html file {{text.le^}} with mustache');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 'le'.length);
    expect(replacementLength, 'le'.length);
    assertSuggestGetter('length', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeDotMemberInMustache() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('html file {{text.^}} with mustache');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('length', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeDotMemberInNgFor() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let item of text.^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('length', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeDotMemberInNgIf() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgIf])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngIf="text.^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('length', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeEmptyExpressionDoesntIncludeVoid() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  void dontCompleteMe() {}
}
    ''');

    addTestSource('{{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('dontCompleteMe');
  }

  // ignore: non_constant_identifier_names
  Future test_completeExportedPrefixes() async {
    newSource('/prefix_one.dart', '''
const int foo = 1;
''');
    newSource('/prefix_two.dart', '''
const int foo = 1;
const int bar = 1;
''');
    newSource('/prefix_three.dart', '''
const int foo = 1;
const int bar = 1;
const int baz = 1;
''');
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
import 'prefix_one.dart' as prefix_one;
import 'prefix_two.dart' as prefix_two;
import 'prefix_three.dart' as prefix_three;
@Component(templateUrl: 'completionTest.html', selector: 'a', exports: const [
  prefix_one.foo,
  prefix_two.foo,
  prefix_two.bar,
])
class MyComp {
}
    ''');

    addTestSource('{{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLibrary('prefix_one');
    assertSuggestLibrary('prefix_two');
    assertNotSuggested('prefix_three');
  }

  // ignore: non_constant_identifier_names
  Future test_completeExports() async {
    newSource('/prefixed.dart', '''
const int otherAccessor = 1;
int otherFunction(){}
class OtherClass {}
enum OtherEnum {}
''');
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
import 'prefixed.dart' as prefixed;
const int myAccessor = 1;
int myFunction(){}
class MyClass {}
enum MyEnum {}
@Component(templateUrl: 'completionTest.html', selector: 'a', exports: const [
  myAccessor,
  myFunction,
  MyClass,
  MyEnum,
  prefixed.otherAccessor,
  prefixed.otherFunction,
  prefixed.OtherClass,
  prefixed.OtherEnum,
])
class MyComp {
}
    ''');

    addTestSource('{{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('myAccessor', 'int');
    assertSuggestFunction('myFunction', 'int');
    assertSuggestClass('MyClass');
    assertSuggestEnum('MyEnum');
    assertSuggestGetter('prefixed.otherAccessor', 'int',
        elementName: 'otherAccessor');
    assertSuggestFunction('prefixed.otherFunction', 'int',
        elementName: 'otherFunction');
    assertSuggestClass('prefixed.OtherClass', elemName: 'OtherClass');
    assertSuggestEnum('prefixed.OtherEnum');
  }

  // ignore: non_constant_identifier_names
  Future test_completeExportsAfterNew() async {
    newSource('/prefixed.dart', '''
const int foo = 1;
class OtherClass {};
''');
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
import 'prefixed.dart' as prefixed;
class MyClass{}
@Component(templateUrl: 'completionTest.html', selector: 'a', exports: const [
  MyClass,
  prefixed.foo,
  prefixed.OtherClass,
])
class MyComp {
}
    ''');

    // NOTE: This actually isn't valid angular yet (we flag it) but one day will
    // be: once we move to angular_ast in both repos.
    addTestSource('{{new ^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClass('MyComp');
    assertSuggestClass('MyClass');
    assertSuggestClass('prefixed.OtherClass', elemName: 'OtherClass');
    assertSuggestLibrary('prefixed');
    assertNotSuggested('foo');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHashVar() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('<button #buttonEl>button</button> {{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVar('buttonEl', 'ButtonElement');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag__in_middle_of_unclosed_tag() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('<div>some text<^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_beginning() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2
      ''');
    addTestSource('<^<div></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_beginning_with_partial() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('<my^<div></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<my'.length);
    expect(replacementLength, '<my'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_end() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('''<div><div></div></div><^''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_end_after_close() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('<div><div></div></div>^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_end_with_partial() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('''<div><div></div></div>
    <my^''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<my'.length);
    expect(replacementLength, '<my'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_middle() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('''<div><div><^</div></div>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_middle_of_text() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('''<div><div> some text<^</div></div>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_at_middle_with_partial() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('''<div><div><my^</div></div>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '<my'.length);
    expect(replacementLength, '<my'.length);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeHtmlSelectorTag_on_empty_document() async {
    final dartSource = newSource('/completionTest.dart', '''
      import 'package:angular/angular.dart';
      @Component(templateUrl: 'completionTest.html', selector: 'a',
        directives: const [MyChildComponent1, MyChildComponent2])
        class MyComp{}
      @Component(template: '', selector: 'my-child1, my-child2')
      class MyChildComponent1{}
      @Component(template: '', selector: 'my-child3.someClass[someAttr]')
      class MyChildComponent2{}
      ''');
    addTestSource('^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestClassTypeAlias('<my-child1');
    assertSuggestClassTypeAlias('<my-child2');
    assertSuggestClassTypeAlias('<my-child3');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInMiddleOfExpressionDoesntIncludeVoid() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  bool takesArg(dynamic arg) {};
  void dontCompleteMe() {}
}
    ''');

    addTestSource('{{takesArg(^)}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('dontCompleteMe');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputAsPlainAttribute() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Input() int intInput;

  bool _myDynamicInput = false;
  bool get myDynamicInput => _myDynamicInput;
  @Input()
  void set myDynamicInput(value) {}
}
    ''');
    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('name');
    assertNotSuggested('intInput');
    assertSuggestSetter('id', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestSetter('[myDynamicInput]');
    assertSuggestSetter('myDynamicInput',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputAsPlainAttributeStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Input() int intInput;

  bool _myDynamicInput = false;
  bool get myDynamicInput => _myDynamicInput;
  @Input()
  void set myDynamicInput(value) {}
}
    ''');
    addTestSource('<my-tag myDyna^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 6);
    expect(replacementLength, 6);
    assertSuggestSetter('name');
    assertNotSuggested('intInput');
    assertSuggestSetter('id', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestSetter('[myDynamicInput]');
    assertSuggestSetter('myDynamicInput',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputInStar() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor="let x of items; ^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTemplateInput('trackBy:', elementName: '[ngForTrackBy]');
    assertNotSuggested('of');
    assertNotSuggested('of:');
    assertNotSuggested('trackBy'); // without the colon
    assertNotSuggested('items');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputInStarReplacing() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor="let x of items; trackBy^: foo"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 'trackBy'.length);
    expect(replacementLength, 'trackBy'.length);
    assertSuggestTemplateInput('trackBy:', elementName: '[ngForTrackBy]');
    assertNotSuggested('of');
    assertNotSuggested('of:');
    assertNotSuggested('trackBy'); // without the colon
    assertNotSuggested('items');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputInStarReplacingBeforeValue() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor="let x of items; trackBy^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 'trackBy'.length);
    expect(replacementLength, 'trackBy'.length);
    assertSuggestTemplateInput('trackBy:', elementName: '[ngForTrackBy]');
    assertNotSuggested('of');
    assertNotSuggested('of:');
    assertNotSuggested('trackBy'); // without the colon
    assertNotSuggested('items');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputInStarValueAlready() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor="let x of items; ^ : foo"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTemplateInput('trackBy:', elementName: '[ngForTrackBy]');
    assertNotSuggested('of');
    assertNotSuggested('of:');
    assertNotSuggested('trackBy'); // without the colon
    assertNotSuggested('items');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputNotStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');
    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputNotStarted_plain_standardHtmlInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('<div ^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('class', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('className');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputNotStarted_standardHtmlInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('<div ^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[class]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('[className]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputNotSuggestedTwice() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [name]="\'bob\'" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputOutputBanana() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;

  @Input() String twoWay;
  @Output() Stream<String> twoWayChange;
}
    ''');

    addTestSource('<my-tag ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
    assertSuggestSetter('[twoWay]');
    assertSuggestGetter('(twoWayChange)', 'String');
    assertSuggestSetter('[(twoWay)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputOutputBanana_at_incompleteTag_with_EOF() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;

  @Input() String twoWay;
  @Output() Stream<String> twoWayChange;
}
    ''');

    addTestSource('<my-tag ^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
    assertSuggestSetter('[twoWay]');
    assertSuggestGetter('(twoWayChange)', 'String');
    assertSuggestSetter('[(twoWay)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputOutputBanana_at_incompleteTag_with_newTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;

  @Input() String twoWay;
  @Output() Stream<String> twoWayChange;
}
    ''');

    addTestSource('<my-tag ^<div></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
    assertSuggestSetter('[twoWay]');
    assertSuggestGetter('(twoWayChange)', 'String');
    assertSuggestSetter('[(twoWay)]', returnType: 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputOutputNotSuggestedAfterTwoWay() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
  String name;
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameChange;
}
    ''');

    addTestSource('<my-tag [(name)]="name" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertNotSuggested('(nameEvent)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputReplacing() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [^input]="4"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, '[input]'.length);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('(nameEvent)');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('(nameEvent)');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_at_incompleteTag_with_EOF() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('(nameEvent)');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_at_incompleteTag_with_newTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [^<div></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('(nameEvent)');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_plain_standardHtmlInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('<div cla^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 3);
    expect(replacementLength, 3);
    assertSuggestSetter('class', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('className');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputStarted_standardHtmlInput() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
}
    ''');

    addTestSource('<div [^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestSetter('[class]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('[className]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeInputSuggestsItself() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [name^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '[name'.length);
    expect(replacementLength, '[name'.length);
    assertSuggestSetter('[name]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInMustache() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('html file {{^}} with mustache');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
    assertSuggestMethod('toString', 'Object', 'String');
    assertSuggestGetter('hashCode', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInNgFor() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let item of ^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
    assertSuggestMethod('toString', 'Object', 'String');
    assertSuggestGetter('hashCode', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInNgIf() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgIf])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngIf="^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
    assertSuggestMethod('toString', 'Object', 'String');
    assertSuggestGetter('hashCode', 'int');
  }

  // ignore: non_constant_identifier_names
  Future test_completeMemberInNgIfPartial() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgIf])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngIf="let ^" ></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
    assertNotSuggested('ngIf');
  }

  // ignore: non_constant_identifier_names
  Future test_completeNgForItem() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor="let item of items">{{^}}</div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVar('item', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeNgForStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '*ngFor'.length);
    expect(replacementLength, '*ngFor'.length);
    assertSuggestStar('*ngFor');
    assertNotSuggested('*ngForOf');
    assertNotSuggested('[id]');
    assertNotSuggested('id');
  }

  // ignore: non_constant_identifier_names
  Future test_completeNgForStartedWithValue() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  List<String> items;
}
    ''');

    addTestSource('<div *ngFor^="let x of items"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '*ngFor'.length);
    expect(replacementLength, '*ngFor'.length);
    assertSuggestStar('*ngFor');
    assertNotSuggested('*ngForOf');
    assertNotSuggested('[id]');
    assertNotSuggested('id');
  }

  // ignore: non_constant_identifier_names
  Future test_completeNgVars_notAfterDot() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  List<String> items;
}
    ''');

    addTestSource(
        '<button #buttonEl>button</button><div *ngFor="item of items">{{hashCode.^}}</div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('buttonEl');
    assertNotSuggested('item');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputNotSuggestedTwice() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (nameEvent)="" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertNotSuggested('(nameEvent)');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputReplacing() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (^output)="4"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, '(output)'.length);
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
    assertNotSuggested('[name]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
    assertNotSuggested('[name]');
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputStarted_at_incompleteTag_with_EOF() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (^');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('[name]');
    assertNotSuggested('[hidden]');
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputStarted_at_incompleteTag_with_newTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (^<div></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertNotSuggested('[name]');
    assertNotSuggested('[hidden]');
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeOutputSuggestsItself() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (nameEvent^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '(nameEvent'.length);
    expect(replacementLength, '(nameEvent'.length);
    assertSuggestGetter('(nameEvent)', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeStandardInputNotSuggestedTwice() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [hidden]="true" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[hidden]');
    assertSuggestSetter('[name]');
    assertSuggestGetter('(nameEvent)', 'String');
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeStandardInputSuggestsItself() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag [hidden^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '[hidden'.length);
    expect(replacementLength, '[hidden'.length);
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
  }

  // ignore: non_constant_identifier_names
  Future test_completeStarAttrsNotStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [NgFor, NgIf, CustomTemplateDirective, NotTemplateDirective])
class MyComp {
  List<String> items;
}

@Directive(selector: '[customTemplateDirective]')
class CustomTemplateDirective {
  CustomTemplateDirective(TemplateRef tpl);
}

@Directive(selector: '[notTemplateDirective]')
class NotTemplateDirective {
}
    ''');

    addTestSource('<div ^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestStar('*ngFor');
    assertSuggestStar('*ngIf');
    assertSuggestStar('*customTemplateDirective');
    assertNotSuggested('*notTemplateDirective');
    assertNotSuggested('*ngForOf');
  }

  // ignore: non_constant_identifier_names
  Future test_completeStarAttrsOnlyStar() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives:
    const [NgFor, NgIf, CustomTemplateDirective, functionalTemplateDirective])
class MyComp {
  List<String> items;
}

@Directive(selector: '[customTemplateDirective]')
class CustomTemplateDirective {
  CustomTemplateDirective(TemplateRef tpl);
}

@Directive(selector: '[functionalTemplateDirective]')
void functionalTemplateDirective(TemplateRef tpl);
    ''');

    addTestSource('<div *^></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 1);
    expect(replacementLength, 1);
    assertSuggestStar('*ngFor');
    assertSuggestStar('*ngIf');
    assertSuggestStar('*customTemplateDirective');
    assertSuggestStar('*functionalTemplateDirective');
    assertNotSuggested('*ngForOf');
    assertNotSuggested('[id]');
    assertNotSuggested('id');
  }

  // ignore: non_constant_identifier_names
  Future test_completeStatements() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('<button (click)="^"></button>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLocalVar(r'$event', 'MouseEvent');
    assertSuggestField('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_completeStdOutputNotSuggestedTwice() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (click)="" ^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestSetter('[name]');
    assertSuggestSetter('[hidden]', relevance: DART_RELEVANCE_DEFAULT - 2);
    assertSuggestGetter('(nameEvent)', 'String');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_completeStdOutputSuggestsItself() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream<String> nameEvent;
}
    ''');

    addTestSource('<my-tag (click^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - '(click'.length);
    expect(replacementLength, '(click'.length);
    assertSuggestGetter('(click)', 'MouseEvent',
        relevance: DART_RELEVANCE_DEFAULT - 1);
  }

  // ignore: non_constant_identifier_names
  Future test_completeTransclusionSuggestion() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('<container>^</container>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  // ignore: non_constant_identifier_names
  Future test_completeTransclusionSuggestionAfterTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('''
<container>
  <blah></blah>
  ^
</container>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  // ignore: non_constant_identifier_names
  Future test_completeTransclusionSuggestionBeforeTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('''
<container>
  ^
  <blah></blah>
</container>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  // ignore: non_constant_identifier_names
  Future test_completeTransclusionSuggestionInWhitespace() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('''
<container>
  ^
</container>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  // ignore: non_constant_identifier_names
  Future test_completeTransclusionSuggestionStarted() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('''
<container>
  <^
</container>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    //expect(replacementOffset, completionOffset - 1);
    //expect(replacementLength, 1);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  Future test_completeTransclusionSuggestionStartedTagName() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [ContainerComponent])
class MyComp{}

@Component(template:
    '<ng-content select="tag1,tag2[withattr],tag3.withclass"></ng-content>',
    selector: 'container')
class ContainerComponent{}
      ''');
    addTestSource('''
<container>
  <tag^
</container>''');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    //expect(replacementOffset, completionOffset - 4);
    //expect(replacementLength, 4);
    assertSuggestTransclusion('<tag1');
    assertSuggestTransclusion('<tag2 withattr');
    assertSuggestTransclusion('<tag3 class="withclass"');
  }

  // ignore: non_constant_identifier_names
  Future test_completeUnclosedMustache() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('some text and {{^   <div>some html</div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_findCompletionTarget_afterUnclosedDom() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a')
class MyComp {
  String text;
}
    ''');

    addTestSource('<input /> {{^}}');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestGetter('text', 'String');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteEmptyTagContents() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream event;
}
    ''');

    addTestSource('<my-tag>^</my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertNotSuggested('[hidden]');
    assertNotSuggested('(event)');
    assertNotSuggested('(click)');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteInOutputInCloseTag() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream event;

  @Input() String twoWay;
  @Output() Stream<String> twoWayChange;
}
    ''');

    addTestSource('<my-tag></my-tag ^>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('[name]');
    assertNotSuggested('[hidden]');
    assertNotSuggested('(event)');
    assertNotSuggested('(click)');
    assertNotSuggested('[twoWay]');
    assertNotSuggested('(twoWayChange)');
    assertNotSuggested('[(twoWay)]');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteInOutputsOnTagNameCompletion() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'dart:async';
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [OtherComp])
class MyComp {
}
@Component(template: '', selector: 'my-tag')
class OtherComp {
  @Input() String name;
  @Output() Stream event;

  @Input() String twoWay;
  @Output() Stream<String> twoWayChange;
}
    ''');

    addTestSource('<my-tag^></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, 0);
    expect(replacementLength, '<my-tag'.length);
    assertNotSuggested('[name]');
    assertNotSuggested('[hidden]');
    assertNotSuggested('(event)');
    assertNotSuggested('(click)');
    assertNotSuggested('[twoWay]');
    assertNotSuggested('(twoWayChange)');
    assertNotSuggested('[(twoWay)]');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteMemberInNgFor_forLettedName() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let ^"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteMemberInNgForAfterLettedName() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let item^ of [text]"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteMemberInNgForInLet() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="l^et item of [text]"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteMemberInNgForInLettedName() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let i^tem of [text]"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
  }

  // ignore: non_constant_identifier_names
  Future test_noCompleteMemberInNgForRightAfterLet() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a', directives: const [NgFor])
class MyComp {
  String text;
}
    ''');

    addTestSource('<div *ngFor="let^ item of [text]"></div>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('text');
  }

  // ignore: non_constant_identifier_names
  Future test_refValue_begin() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]', exportAs: 'foo')
class MyDirective {}
    ''');

    addTestSource('<my-tag myDirective #ref="^"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLabel('foo');
  }

  // ignore: non_constant_identifier_names
  Future test_refValue_complete() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]', exportAs: 'foobar')
class MyDirective {}
    ''');

    addTestSource('<my-tag myDirective #ref="^foobar"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 'foobar'.length);
    assertSuggestLabel('foobar');
  }

  // ignore: non_constant_identifier_names
  Future test_refValue_middle() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirective])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirective]', exportAs: 'foobar')
class MyDirective {}
    ''');

    addTestSource('<my-tag myDirective #ref="foo^"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset - 'foo'.length);
    expect(replacementLength, 'foo'.length);
    assertSuggestLabel('foobar');
  }

  // ignore: non_constant_identifier_names
  Future test_refValue_should_dedupe() async {
    final dartSource = newSource('/completionTest.dart', '''
import 'package:angular/angular.dart';
@Component(templateUrl: 'completionTest.html', selector: 'a',
    directives: const [MyTagComponent, MyDirectiveOne, MyDirectiveTwo])
class MyComp {
}
@Component(selector: 'my-tag', template: '')
class MyTagComponent{}
@Directive(selector: '[myDirectiveOne]', exportAs: 'foobar')
class MyDirectiveOne {}
@Directive(selector: '[myDirectiveTwo]', exportAs: 'foobar')
class MyDirectiveTwo {}
    ''');

    addTestSource('<my-tag myDirectiveOne myDirectiveTwo #ref="^"></my-tag>');

    await resolveSingleTemplate(dartSource);
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestLabel('foobar');
  }
}
