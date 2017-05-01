@Tags(const ['codegen'])
@TestOn('browser')

import 'package:angular2/angular2.dart';
import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';

void main() {
  group('ngStyle', () {
    tearDown(() => disposeAnyRunningTest());

    test('should add styles specified in an map literal', () async {
      var testBed = new NgTestBed<MapLiteralTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.style.maxWidth, '40px');
    });
    test('should update styles specified in an map literal', () async {
      var testBed = new NgTestBed<MapUpdateTest>();
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
      var testBed = new NgTestBed<MapUpdateTest>();
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
      var testBed = new NgTestBed<MapUpdateWithDefaultTest>();
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
      var testBed = new NgTestBed<MapUpdateWithStyleExprTest>();
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
    selector: 'map-literal-test',
    directives: const [NgStyle],
    template: '<div [ngStyle]="{\'max-width\': \'40px\'}"></div>')
class MapLiteralTest {}

@Component(
    selector: 'map-update-test',
    directives: const [NgStyle],
    template: '<div [ngStyle]="map"></div>')
class MapUpdateTest {
  Map<String, String> map;
}

@Component(
    selector: 'map-update-with-default-test',
    directives: const [NgStyle],
    template: '<div style="font-size: 12px" [ngStyle]="map"></div>')
class MapUpdateWithDefaultTest {
  Map<String, String> map;
}

@Component(
    selector: 'map-update-with-style-expr-test',
    directives: const [NgStyle],
    template: '<div [style.font-size.px]="12" [ngStyle]="map"></div>')
class MapUpdateWithStyleExprTest {
  Map<String, String> map;
}
