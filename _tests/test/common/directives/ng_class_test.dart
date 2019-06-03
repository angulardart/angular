@TestOn('browser')

import 'package:angular_test/angular_test.dart';
import 'package:test/test.dart';
import 'package:angular/angular.dart';

import 'ng_class_test.template.dart' as ng_generated;

void main() {
  ng_generated.initReflector();

  group('ngClass', () {
    tearDown(() => disposeAnyRunningTest());

    test('should clean up when the directive is destroyed', () async {
      var testBed = NgTestBed<DestroyClassTest>();
      var testFixture = await testBed.create();
      await testFixture.update((DestroyClassTest component) {
        component.items = [
          ['0']
        ];
      });
      await testFixture.update((DestroyClassTest component) {
        component.items = [
          ['1']
        ];
      });
      expect(
          testFixture.rootElement.querySelector('div').classes, equals(['1']));
    });

    test('should add classes specified in map without change in class names',
        () async {
      var testBed = NgTestBed<ClassWithNames>();
      var testFixture = await testBed.create();
      expect(testFixture.rootElement.querySelector('div').classes,
          equals(['foo-bar', 'fooBar']));
    });

    test('should update classes based on changes in map values', () async {
      var testBed = NgTestBed<ConditionMapTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((ConditionMapTest component) {
        component.condition = false;
      });
      expect(content.classes, equals(['bar']));
    });

    test('should update classes based on changes to the map', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((MapUpdateTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['foo', 'bar']));
      await testFixture.update((MapUpdateTest component) {
        component.map['baz'] = true;
      });
      expect(content.classes, equals(['foo', 'bar', 'baz']));
      await testFixture.update((MapUpdateTest component) {
        component.map.remove('bar');
      });
      expect(content.classes, equals(['foo', 'baz']));
    });

    test('should update classes based on reference changes to the map',
        () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'foo': true, 'bar': true};
      });
      expect(content.classes, equals(['foo', 'bar']));
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'baz': true};
      });
      expect(content.classes, equals(['baz']));
    });

    test('should remove classes when expression is null', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((MapUpdateTest component) {
        component.map = null;
      });
      expect(content.classes, isEmpty);
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'foo': false, 'bar': true};
      });
      expect(content.classes, equals(['bar']));
    });

    test('should allow multiple classes per expression', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'bar baz': true, 'bar1 baz1': true};
      });
      expect(content.classes, equals(['bar', 'baz', 'bar1', 'baz1']));
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'bar baz': false, 'bar1 baz1': true};
      });
      expect(content.classes, equals(['bar1', 'baz1']));
    });

    test('should split by one or more spaces between classes', () async {
      var testBed = NgTestBed<MapUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateTest component) {
        component.map = <String, bool>{'foo bar     baz': true};
      });
      expect(content.classes, equals(['foo', 'bar', 'baz']));
    });

    test('should add classes specified in a list literal', () async {
      var testBed = NgTestBed<ListLiteralTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo', 'bar', 'foo-bar', 'fooBar']));
    });

    test('should update classes based on changes to the list', () async {
      var testBed = NgTestBed<ListUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((ListUpdateTest component) {
        component.list.add('bar');
      });
      expect(content.classes, equals(['foo', 'bar']));
      await testFixture.update((ListUpdateTest component) {
        component.list[1] = 'baz';
      });
      expect(content.classes, equals(['foo', 'baz']));
      await testFixture.update((ListUpdateTest component) {
        component.list.remove('baz');
      });
      expect(content.classes, equals(['foo']));
    });

    test('should update classes when list reference changes', () async {
      var testBed = NgTestBed<ListUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((ListUpdateTest component) {
        component.list = ['bar'];
      });
      expect(content.classes, equals(['bar']));
    });

    test('should take initial classes into account when a reference changes',
        () async {
      var testBed = NgTestBed<ListUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((ListUpdateWithInitialTest component) {
        component.list = ['bar'];
      });
      expect(content.classes, equals(['foo', 'bar']));
    });

    test('should ignore empty or blank class names', () async {
      var testBed = NgTestBed<ListUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((ListUpdateWithInitialTest component) {
        component.list = ['', '  '];
      });
      expect(content.classes, equals(['foo']));
    });

    test('should trim blanks from class names', () async {
      var testBed = NgTestBed<ListUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((ListUpdateWithInitialTest component) {
        component.list = [' bar  '];
      });
      expect(content.classes, equals(['foo', 'bar']));
    });

    test('should allow multiple classes per item in lists', () async {
      var testBed = NgTestBed<ListUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((ListUpdateTest component) {
        component.list = ['foo bar baz', 'foo1 bar1   baz1'];
      });
      expect(content.classes,
          equals(['foo', 'bar', 'baz', 'foo1', 'bar1', 'baz1']));
      await testFixture.update((ListUpdateTest component) {
        component.list = ['foo bar   baz foobar'];
      });
      expect(content.classes, equals(['foo', 'bar', 'baz', 'foobar']));
    });

    test('should update classes if the set instance changes', () async {
      var testBed = NgTestBed<SetUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      var set = <String>{};
      set.add('bar');
      await testFixture.update((SetUpdateTest component) {
        component.set = set;
      });
      expect(content.classes, equals(['bar']));
      set = <String>{};
      set.add('baz');
      await testFixture.update((SetUpdateTest component) {
        component.set = set;
      });
      expect(content.classes, equals(['baz']));
    });

    test('should add classes specified in a string literal', () async {
      var testBed = NgTestBed<StringLiteralTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo', 'bar', 'foo-bar', 'fooBar']));
    });

    test('should update classes based on changes to the string', () async {
      var testBed = NgTestBed<StringUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((StringUpdateTest component) {
        component.string = 'foo bar';
      });
      expect(content.classes, equals(['foo', 'bar']));
      await testFixture.update((StringUpdateTest component) {
        component.string = 'baz';
      });
      expect(content.classes, equals(['baz']));
    });

    test('should remove active classes when switching from string to null',
        () async {
      var testBed = NgTestBed<StringUpdateTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((StringUpdateTest component) {
        component.string = null;
      });
      expect(content.classes, isEmpty);
    });

    test(
        'should take initial classes into account when '
        'switching from string to null', () async {
      var testBed = NgTestBed<StringUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo']));
      await testFixture.update((StringUpdateWithInitialTest component) {
        component.string = null;
      });
      expect(content.classes, equals(['foo']));
    });

    test('should ignore empty and blank strings', () async {
      var testBed = NgTestBed<StringUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((StringUpdateWithInitialTest component) {
        component.string = '';
      });
      expect(content.classes, equals(['foo']));
    });

    test('should cooperate with the class attribute', () async {
      var testBed = NgTestBed<MapUpdateWithInitialTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateWithInitialTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['init', 'foo', 'bar']));
      await testFixture.update((MapUpdateWithInitialTest component) {
        component.map['foo'] = false;
      });
      expect(content.classes, equals(['init', 'bar']));
      await testFixture.update((MapUpdateWithInitialTest component) {
        component.map = null;
      });
      expect(content.classes, equals(['init', 'foo']));
    });

    test('should cooperate with interpolated class attribute', () async {
      var testBed = NgTestBed<MapUpdateWithInitialInterpolationTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture
          .update((MapUpdateWithInitialInterpolationTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['init', 'foo', 'bar']));
      await testFixture
          .update((MapUpdateWithInitialInterpolationTest component) {
        component.map['foo'] = false;
      });
      expect(content.classes, equals(['init', 'bar']));
      await testFixture
          .update((MapUpdateWithInitialInterpolationTest component) {
        component.map = null;
      });
      expect(content.classes, equals(['init', 'foo']));
    });

    test('should cooperate with class attribute and binding to it', () async {
      var testBed = NgTestBed<MapUpdateWithInitialBindingTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      await testFixture.update((MapUpdateWithInitialBindingTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['init', 'foo', 'bar']));
      await testFixture.update((MapUpdateWithInitialBindingTest component) {
        component.map['foo'] = false;
      });
      expect(content.classes, equals(['init', 'bar']));
      await testFixture.update((MapUpdateWithInitialBindingTest component) {
        component.map = null;
      });
      expect(content.classes, equals(['init', 'foo']));
    });

    test('should cooperate with class attribute and class.name binding',
        () async {
      var testBed = NgTestBed<MapUpdateWithConditionBindingTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['init', 'foo', 'baz']));
      await testFixture.update((MapUpdateWithConditionBindingTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['init', 'foo', 'baz', 'bar']));
      await testFixture.update((MapUpdateWithConditionBindingTest component) {
        component.map['foo'] = false;
      });
      expect(content.classes, equals(['init', 'baz', 'bar']));
      await testFixture.update((MapUpdateWithConditionBindingTest component) {
        component.condition = false;
      });
      expect(content.classes, equals(['init', 'bar']));
    });

    test(
        'should cooperate with initial class and class '
        'attribute binding when binding changes', () async {
      var testBed = NgTestBed<MapUpdateWithStringBindingTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['init', 'foo']));
      await testFixture.update((MapUpdateWithStringBindingTest component) {
        component.map['bar'] = true;
      });
      expect(content.classes, equals(['init', 'foo', 'bar']));
      await testFixture.update((MapUpdateWithStringBindingTest component) {
        component.string = 'baz';
      });
      expect(content.classes, equals(['init', 'bar', 'baz', 'foo']));
      await testFixture.update((MapUpdateWithStringBindingTest component) {
        component.map = null;
      });
      expect(content.classes, equals(['init', 'baz']));
    });

    test(
        'should cooperate with interpolated class attribute '
        'and clas.name binding', () async {
      var testBed = NgTestBed<InterpolationWithConditionBindingTest>();
      var testFixture = await testBed.create();
      var content = testFixture.rootElement.querySelector('div');
      expect(content.classes, equals(['foo', 'baz']));
      await testFixture
          .update((InterpolationWithConditionBindingTest component) {
        component.condition = false;
      });
      expect(content.classes, equals(['foo']));
      await testFixture
          .update((InterpolationWithConditionBindingTest component) {
        component.condition = true;
      });
      expect(content.classes, equals(['foo', 'baz']));
    });
  });
}

class Base {
  var condition = true;
  var map = {'foo': true, 'bar': false};
  var list = ['foo'];
  var set = <String>{};
  var string = 'foo';
}

@Component(
  selector: 'ngclass-destroy',
  directives: [NgClass, NgFor],
  template: '<div *ngFor="let item of items" [ngClass]="item"></div>',
)
class DestroyClassTest {
  List<List<String>> items;
}

@Component(
  selector: 'class-with-names',
  directives: [NgClass],
  template: '<div [ngClass]="classes"></div>',
)
class ClassWithNames {
  static const classes = {
    'foo-bar': true,
    'fooBar': true,
  };
}

@Component(
  selector: 'condition-map-test',
  directives: [NgClass],
  template: '<div [ngClass]="conditionMap"></div>',
)
class ConditionMapTest extends Base {
  Map<String, bool> _conditionMap;
  bool _prevCondition;

  Map<String, bool> get conditionMap {
    if (_prevCondition != condition) {
      _conditionMap = {
        'foo': condition,
        'bar': !condition,
      };
      _prevCondition = condition;
    }
    return _conditionMap;
  }
}

@Component(
  selector: 'map-update-test',
  directives: [NgClass],
  template: '<div [ngClass]="map"></div>',
)
class MapUpdateTest extends Base {}

@Component(
  selector: 'string-literal-test',
  directives: [NgClass],
  template:
      '<div [ngClass]="[\'foo\', \'bar\', \'foo-bar\', \'fooBar\']"></div>',
)
class ListLiteralTest {}

@Component(
  selector: 'list-update-test',
  directives: [NgClass],
  template: '<div [ngClass]="list"></div>',
)
class ListUpdateTest extends Base {}

@Component(
  selector: 'list-update-with-initial-test',
  directives: [NgClass],
  template: '<div class="foo" [ngClass]="list"></div>',
)
class ListUpdateWithInitialTest extends Base {}

@Component(
  selector: 'list-update-test',
  directives: [NgClass],
  template: '<div [ngClass]="set"></div>',
)
class SetUpdateTest extends Base {}

@Component(
  selector: 'string-literal-test',
  directives: [NgClass],
  template: '<div [ngClass]="\'foo bar foo-bar fooBar\'"></div>',
)
class StringLiteralTest {}

@Component(
  selector: 'string-update-test',
  directives: [NgClass],
  template: '<div [ngClass]="string"></div>',
)
class StringUpdateTest extends Base {}

@Component(
  selector: 'string-update-with-initial-test',
  directives: [NgClass],
  template: '<div class="foo" [ngClass]="string"></div>',
)
class StringUpdateWithInitialTest extends Base {}

@Component(
  selector: 'map-update-with-initial-test',
  directives: [NgClass],
  template: '<div [ngClass]="map" class="init foo"></div>',
)
class MapUpdateWithInitialTest extends Base {}

@Component(
  selector: 'map-update-with-initial-interpolation-test',
  directives: [NgClass],
  template: '<div [ngClass]="map" class="{{\'init foo\'}}"></div>',
)
class MapUpdateWithInitialInterpolationTest extends Base {}

@Component(
  selector: 'map-update-with-initial-binding-test',
  directives: [NgClass],
  template: '<div [ngClass]="map" class="init" [class]="\'foo\'"></div>',
)
class MapUpdateWithInitialBindingTest extends Base {}

@Component(
  selector: 'map-update-with-condition-binding-test',
  directives: [NgClass],
  template:
      '<div class="init foo" [ngClass]="map" [class.baz]="condition"></div>',
)
class MapUpdateWithConditionBindingTest extends Base {}

@Component(
  selector: 'map-update-with-string-binding-test',
  directives: [NgClass],
  template: '<div class="init" [ngClass]="map" [class]="string"></div>',
)
class MapUpdateWithStringBindingTest extends Base {}

@Component(
  selector: 'interpolation-with-condition-binding-test',
  directives: [NgClass],
  template: '<div [class.baz]="condition" class="{{string}}" ngClass></div>',
)
class InterpolationWithConditionBindingTest extends Base {}
