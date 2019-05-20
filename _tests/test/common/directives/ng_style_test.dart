@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'ng_style_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('ngStyle', () {
    tearDown(() => disposeAnyRunningTest());

    test('should update styles specified in an map literal', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateTest component) {
        component.map = {'max-width': '40px'};
      });
      expect(content.style.maxWidth, '40px');
      await testFixture.update((MapUpdateTest component) {
        component.map['max-width'] = '30%';
      });
      expect(content.style.maxWidth, '30%');
    });

    test('should remove styles when deleting a key in a map literal', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateTest component) {
        component.map = {'max-width': '40px'};
      });
      expect(content.style.maxWidth, '40px');
      await testFixture.update((MapUpdateTest component) {
        component.map.remove('max-width');
      });
      expect(content.style.maxWidth, '');
    });

    test('should cooperate with the style attribute', () async {
      var testBed = NgTestBed<MapUpdateWithDefaultTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateWithDefaultTest component) {
        component.map = {'max-width': '40px'};
      });
      expect(content.style.maxWidth, '40px');
      expect(content.style.fontSize, '12px');
      await testFixture.update((MapUpdateWithDefaultTest component) {
        component.map.remove('max-width');
      });
      expect(content.style.maxWidth, '');
      expect(content.style.fontSize, '12px');
    });

    test('should cooperate with the style.[styleName]="expr" special-case',
        () async {
      var testBed = NgTestBed<MapUpdateWithStyleExprTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateWithStyleExprTest component) {
        component.map = {'max-width': '40px'};
      });
      expect(content.style.maxWidth, '40px');
      expect(content.style.fontSize, '12px');
      await testFixture.update((MapUpdateWithStyleExprTest component) {
        component.map.remove('max-width');
      });
      expect(content.style.maxWidth, '');
      expect(content.style.fontSize, '12px');
    });
  });
}

@Component(
  selector: 'map-update-test',
  directives: [NgStyle],
  template: '<div [ngStyle]="map"></div>',
)
class MapUpdateTest {
  Map<String, String> map;
}

@Component(
  selector: 'map-update-with-default-test',
  directives: [NgStyle],
  template: '<div style="font-size: 12px" [ngStyle]="map"></div>',
)
class MapUpdateWithDefaultTest {
  Map<String, String> map;
}

@Component(
  selector: 'map-update-with-style-expr-test',
  directives: [NgStyle],
  template: '<div [style.font-size.px]="12" [ngStyle]="map"></div>',
)
class MapUpdateWithStyleExprTest {
  Map<String, String> map;
}
