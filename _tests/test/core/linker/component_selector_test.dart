import 'package:test/test.dart';
import 'package:_tests/matchers.dart';
import 'package:angular/angular.dart';
import 'package:angular_test/angular_test.dart';

import 'component_selector_test.template.dart' as ng;

void main() {
  group('Selector', () {
    tearDown(() => disposeAnyRunningTest());

    test('should support attaching component to tr tag', () async {
      var testBed = NgTestBed(ng.createTrTagTestFactory());
      var testFixture = await testBed.create();
      var rows = testFixture.rootElement.querySelectorAll('tr[repaired-part]');
      expect(rows, hasLength(3));
      expect(rows, everyElement(hasTextContent('Repaired')));
    });

    test('should support exact attribute selector', () async {
      final testBed =
          NgTestBed(ng.createExactAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo]')!.text, isEmpty);
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, isEmpty);
    });

    test('should support hypen attribute selector', () async {
      final testBed =
          NgTestBed(ng.createHyphenAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo="bar-baz"]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, isEmpty);
    });

    test('should support list attribute selector', () async {
      final testBed =
          NgTestBed(ng.createListAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo="bar baz"]')!.text, 'Matched!');
      expect(select('[foo="baz bar qux"]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, isEmpty);
    });

    test('should support prefix attribute selector', () async {
      final testBed =
          NgTestBed(ng.createPrefixAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, 'Matched!');
      expect(select('[foo=bazbar]')!.text, isEmpty);
    });

    test('should support set attribute selector', () async {
      final testBed =
          NgTestBed(ng.createSetAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('div')!.text, isEmpty);
      expect(select('[foo]')!.text, 'Matched!');
      expect(select('[foo=""]')!.text, 'Matched!');
      expect(select('[foo="bar"]')!.text, 'Matched!');
    });

    test('should support substring attribute selector', () async {
      final testBed =
          NgTestBed(ng.createSubstringAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, 'Matched!');
      expect(select('[foo=bazbar]')!.text, 'Matched!');
    });

    test('should support suffix attribute selector', () async {
      final testBed =
          NgTestBed(ng.createSuffixAttributeSelectorTestComponentFactory());
      final testFixture = await testBed.create();
      final select = testFixture.rootElement.querySelector;
      expect(select('[foo=bar]')!.text, 'Matched!');
      expect(select('[foo=barbaz]')!.text, isEmpty);
      expect(select('[foo=bazbar]')!.text, 'Matched!');
    });
  });
}

@Component(
  selector: 'tr-tag-test',
  template: '<table>'
      '<thead><tr><th>Repairs:</th></tr>'
      '</thead>'
      '<tbody>'
      '  <template ngFor let-repair [ngForOf]="repairs">'
      '    <tr repaired-part></tr>'
      '  </template>'
      '</tbody>'
      '</table>',
  directives: [NgFor, RepairedPartComponent],
)
class TrTagTest {
  final repairs = List.filled(3, null);
}

@Component(
  selector: 'tr[repaired-part]',
  template: '<td>Repaired</td>',
)
class RepairedPartComponent {}

@Component(
  selector: 'div[foo=bar]',
  template: '<p>Matched!</p>',
)
class ExactAttributeSelectorComponent {}

@Component(
  selector: 'hyphen-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo></div>
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>''',
  directives: [
    ExactAttributeSelectorComponent,
  ],
)
class ExactAttributeSelectorTestComponent {}

@Component(
  selector: 'div[foo|=bar]',
  template: '<p>Matched!</p>',
)
class HyphenAttributeSelectorComponent {}

@Component(
  selector: 'hyphen-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="bar-baz"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>''',
  directives: [
    HyphenAttributeSelectorComponent,
  ],
)
class HyphenAttributeSelectorTestComponent {}

@Component(
  selector: 'div[foo~=bar]',
  template: '<p>Matched!</p>',
)
class ListAttributeSelectorComponent {}

@Component(
  selector: 'list-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="bar baz"></div>
<div @skipSchemaValidationFor="[foo]" foo="baz bar qux"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>''',
  directives: [
    ListAttributeSelectorComponent,
  ],
)
class ListAttributeSelectorTestComponent {}

@Component(
  selector: 'div[foo^=bar]',
  template: '<p>Matched!</p>',
)
class PrefixAttributeSelectorComponent {}

@Component(
  selector: 'prefix-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>
<div @skipSchemaValidationFor="[foo]" foo="bazbar"></div>''',
  directives: [
    PrefixAttributeSelectorComponent,
  ],
)
class PrefixAttributeSelectorTestComponent {}

@Component(
  selector: 'div[foo]',
  template: '<p>Matched!</p>',
)
class SetAttributeSelectorComponent {}

@Component(
  selector: 'set-attribute-selector-test',
  template: '''
<div></div>
<div @skipSchemaValidationFor="[foo]" foo></div>
<div @skipSchemaValidationFor="[foo]" foo=""></div>
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>''',
  directives: [
    SetAttributeSelectorComponent,
  ],
)
class SetAttributeSelectorTestComponent {}

@Component(
  selector: r'div[foo*=bar]',
  template: '<p>Matched!</p>',
)
class SubstringAttributeSelectorComponent {}

@Component(
  selector: 'substring-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>
<div @skipSchemaValidationFor="[foo]" foo="bazbar"></div>
<div @skipSchemaValidationFor="[foo]" foo="baz bar qux"></div>''',
  directives: [
    SubstringAttributeSelectorComponent,
  ],
)
class SubstringAttributeSelectorTestComponent {}

@Component(
  selector: r'div[foo$=bar]',
  template: '<p>Matched!</p>',
)
class SuffixAttributeSelectorComponent {}

@Component(
  selector: 'suffix-attribute-selector-test',
  template: '''
<div @skipSchemaValidationFor="[foo]" foo="bar"></div>
<div @skipSchemaValidationFor="[foo]" foo="barbaz"></div>
<div @skipSchemaValidationFor="[foo]" foo="bazbar"></div>''',
  directives: [
    SuffixAttributeSelectorComponent,
  ],
)
class SuffixAttributeSelectorTestComponent {}
