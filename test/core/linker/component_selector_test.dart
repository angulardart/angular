@Tags(const ['codegen'])
@TestOn('browser && !js')
library angular2.test.core.linker.component_selector_test;

import 'dart:html';

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  group('Selector', () {
    tearDown(() => disposeAnyRunningTest());
    test('should support attaching component to tr tag', () async {
      var testBed = new NgTestBed<TrTagTest>();
      var testFixture = await testBed.create();
      List<Element> rows =
          testFixture.rootElement.querySelectorAll('tr[repaired-part]');
      expect(rows, hasLength(3));
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
        '    <tr repaired-part>{{repair["id"]}}</tr>'
        '  </template>'
        '</tbody>'
        '</table>',
    directives: const [NgFor])
class TrTagTest {
  List<Map<String, String>> repairs;
  TrTagTest() {
    repairs = [
      {'id': '34534'},
      {'id': '7'},
      {'id': '5'}
    ];
  }
}

@Component(selector: 'tr[repaired-part]', template: '<td>Repaired</td>')
class RepairedPartComponent {}
