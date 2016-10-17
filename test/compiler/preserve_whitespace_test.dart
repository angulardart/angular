@Tags(const ['codegen'])
@TestOn('browser')
library angular2.test.compiler.preserve_whitespace_test;

import 'package:angular2/angular2.dart';
import 'package:angular2/testing_experimental.dart';
import 'package:test/test.dart';

void main() {
  var testRoot;
  group('preservewhitespace', () {
    tearDown(() async => await testRoot.dispose());

    test('should not remove whitespace by default', () async {
      var testBed = new NgTestBed<DefaultWhiteSpaceComponent>();
      testRoot = await testBed.create();
      expect(testRoot.element.text, defaultWithWhitespace);
    });
    test('should not remove whitespace when explicitely requested', () async {
      var testBed = new NgTestBed<WhiteSpaceComponentExplicitTrue>();
      testRoot = await testBed.create();
      expect(testRoot.element.text, defaultWithWhitespace);
    });

    test('should render ngsp entity', () async {
      var testBed = new NgTestBed<NgSpaceComponent>();
      testRoot = await testBed.create();
      expect(
          testRoot.element.text,
          'V1  test1   test2V2\n'
          'test0  test1   test2\n');
    });

    test('should remove whitespace when explicitely requested', () async {
      var testBed = new NgTestBed<WhiteSpaceComponentExplicitFalse>();
      testRoot = await testBed.create();
      expect(testRoot.element.text, 'HelloWorldV1 V2');
    });

    test('should remove whitespace inside interpolation on left side',
        () async {
      var testBed = new NgTestBed<Interpolate1LeftComponent>();
      testRoot = await testBed.create();
      expect(testRoot.element.text, 'V1');
    });

    test('should remove whitespace inside interpolation on left and right side',
        () async {
      var testBed = new NgTestBed<InterpolateComponent>();
      testRoot = await testBed.create();
      expect(testRoot.element.text, 'V1  V2');
    });
  });
}

String defaultWithWhitespace = '\n'
    '       Hello\n'
    '             World\n'
    '     V1 V2\n';

@Component(
    selector: 'test-default',
    template: '<span class="other-element">\n'
        '       Hello</span>\n'
        '     <div> <span>  </span>  <span> </span>  World</div>\n'
        '     <div>{{value1}} {{value2}}</div>\n')
class DefaultWhiteSpaceComponent {
  String get value1 => 'V1';
  String get value2 => 'V2';
}

@Component(
    selector: 'test-ngspace',
    // First div covers interpolate path.
    // Second div covers simple visitText path.
    template: '<div>{{value1}}&ngsp;&ngsp;test1 &ngsp; test2{{value2}}</div>\n'
        '<div>test0&ngsp;&ngsp;test1 &ngsp; test2</div>\n')
class NgSpaceComponent {
  String get value1 => 'V1';
  String get value2 => 'V2';
}

@Component(
    selector: 'test-explicit-false',
    template: r'''
        <span class="other-element">
        Hello</span>
        <div> <span>  </span>  <span> </span>  World</div>
        <div>{{value1}} {{value2}}</div>
     ''',
    preserveWhitespace: false)
class WhiteSpaceComponentExplicitFalse {
  String get value1 => 'V1';
  String get value2 => 'V2';
}

@Component(
    selector: 'test-explicit-true',
    template: '<span class="other-element">\n'
        '       Hello</span>\n'
        '     <div> <span>  </span>  <span> </span>  World</div>\n'
        '     <div>{{value1}} {{value2}}</div>\n',
    preserveWhitespace: true)
class WhiteSpaceComponentExplicitTrue {
  String get value1 => 'V1';
  String get value2 => 'V2';
}

@Component(
    selector: 'test-interpolate1-leftspace',
    template: '\n    \n    {{value1}}',
    preserveWhitespace: false)
class Interpolate1LeftComponent {
  String get value1 => 'V1';
}

/// Should preserve the space between interpolation but not in surrounding
/// area with new lines.
@Component(
    selector: 'test-interpolate',
    template: '\n    \n    {{value1}}  {{value2}}  \n      ',
    preserveWhitespace: false)
class InterpolateComponent {
  String get value1 => 'V1';
  String get value2 => 'V2';
}
