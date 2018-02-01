@TestOn('browser')

import 'dart:html';

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'host_attributes_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('Host attributes', () {
    tearDown(() => disposeAnyRunningTest());
    test('On component itself should be rendered', () async {
      var testBed = new NgTestBed<HostAttrOnComponentTest>();
      var testFixture = await testBed.create();
      Element element =
          testFixture.rootElement.querySelector('component-with-attr');
      expect(element.attributes['role'], 'listbox');
      expect(element.style.cssText, 'background-color: red;');
      expect(element.className, 'themeable');
    });

    test('Provided by a directive should be rendered', () async {
      var testBed = new NgTestBed<HostAttrOnDirectiveTest>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement.querySelector('#my_element');
      expect(element.attributes['role'], 'button');
      expect(element.style.cssText, 'display: block; background-color: green;');
      expect(element.className, 'autofocus');
    });

    test('Provided by component and directives should be merged', () async {
      var testBed = new NgTestBed<HostAttrMergedTest>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement.querySelector('#merged');
      expect(element.attributes['role'], 'button');
      expect(element.style.cssText, 'display: block; background-color: green;');
      expect(element.attributes['style'],
          'background-color: red; display:block; background-color: green;');
      expect(element.className, 'themeable autofocus');
    });

    test('On component itself should be rendered with base attribute',
        () async {
      var testBed = new NgTestBed<HostAttrOnComponentAndElementTest>();
      var testFixture = await testBed.create();
      Element element =
          testFixture.rootElement.querySelector('component-with-attr');
      expect(element.attributes['role'], 'listbox');
      expect(element.style.cssText, 'background-color: red;');
      expect(element.className, 'base themeable');
    });

    test('Provided by a directive should be rendered with base attribute',
        () async {
      var testBed = new NgTestBed<HostAttrOnDirectiveAndElementTest>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement.querySelector('#my_element');
      expect(element.attributes['role'], 'button');
      expect(element.style.cssText, 'display: block; background-color: green;');
      expect(element.className, 'base autofocus');
    });

    test(
        'Provided by component and directives should be merged with '
        'base attribute', () async {
      var testBed = new NgTestBed<HostAttrMergedAndElementTest>();
      var testFixture = await testBed.create();
      Element element = testFixture.rootElement.querySelector('#merged');
      expect(element.attributes['role'], 'button');
      expect(element.style.cssText, 'display: block; background-color: green;');
      expect(element.attributes['style'],
          'background-color: red; display:block; background-color: green;');
      expect(element.className, 'base themeable autofocus');
    });
  });
}

@Component(
  selector: 'host-attr-on-comp',
  template: '<component-with-attr></component-with-attr>',
  directives: const [ComponentWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrOnComponentTest {}

@Component(
  selector: 'host-attr-on-directive',
  template: '<div id="my_element" directive-with-attr>'
      '</div>',
  directives: const [DirectiveWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrOnDirectiveTest {}

@Component(
  selector: 'host-attr-merged',
  template: '<component-with-attr id="merged" directive-with-attr>'
      '</component-with-attr>',
  directives: const [ComponentWithAttr, DirectiveWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrMergedTest {}

@Component(
  selector: 'host-attr-on-comp-and-element',
  template: '<component-with-attr class="base"></component-with-attr>',
  directives: const [ComponentWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrOnComponentAndElementTest {}

@Component(
  selector: 'host-attr-on-directive',
  template: '<div id="my_element" class="base" directive-with-attr>'
      '</div>',
  directives: const [DirectiveWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrOnDirectiveAndElementTest {}

@Component(
  selector: 'host-attr-merged',
  template: '<component-with-attr id="merged" class="base" directive-with-attr>'
      '</component-with-attr>',
  directives: const [ComponentWithAttr, DirectiveWithAttr],
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class HostAttrMergedAndElementTest {}

@Component(
  host: const {
    'role': 'listbox',
    'style': 'background-color: red;',
    'class': 'themeable'
  },
  selector: 'component-with-attr',
  template: '<div>{{message}}</div>',
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class ComponentWithAttr {
  final String message = 'Hello World';
}

@Directive(
  selector: '[directive-with-attr]',
  host: const {
    'role': 'button',
    'style': 'display:block; background-color: green;',
    'class': 'autofocus'
  },
  // TODO(b/71710685): Change to `Visibility.local` to reduce code size.
  visibility: Visibility.all,
)
class DirectiveWithAttr {}
