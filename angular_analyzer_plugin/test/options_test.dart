import 'package:angular_analyzer_plugin/src/options.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AngularOptionsTest);
  });
}

@reflectiveTest
class AngularOptionsTest {
  // ignore: non_constant_identifier_names
  void test_buildEmpty() {
    final options = AngularOptions.defaults();
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildExact() {
    final options = AngularOptions(customTagNames: ['foo']);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, equals(['foo']));
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_defaults() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    - angular
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, isEmpty);
    expect(options.customEvents, isNotNull);
    expect(options.customEvents, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_defaults_emptyObject() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    - angular

angular:
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, isEmpty);
    expect(options.customEvents, isNotNull);
    expect(options.customEvents, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_defaults_legacy_emptyObject() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    angular:
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, isEmpty);
    expect(options.customEvents, isNotNull);
    expect(options.customEvents, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_dynamic_events() {
    final code = '''
analyzer:
  plugins:
    - angular

angular:
  custom_events:
    foo:
      type: String
    bar:
      type: BarEvent
      path: 'package:foo/bar/baz.dart'
    empty:
''';
    final options = AngularOptions.fromString(code, null);
    expect(options.customEvents, isNotNull);
    expect(options.customEvents, hasLength(3));

    {
      final event = options.customEvents['foo'];
      expect(event, isNotNull);
      expect(event.name, 'foo');
      expect(event.typeName, 'String');
      expect(event.typePath, isNull);
      expect(event.nameOffset, code.indexOf('foo'));
    }

    {
      final event = options.customEvents['bar'];
      expect(event, isNotNull);
      expect(event.name, 'bar');
      expect(event.typeName, 'BarEvent');
      expect(event.typePath, 'package:foo/bar/baz.dart');
      expect(event.nameOffset, code.indexOf('bar'));
    }

    {
      final event = options.customEvents['empty'];
      expect(event, isNotNull);
      expect(event.name, 'empty');
      expect(event.typeName, null);
      expect(event.typePath, null);
      expect(event.nameOffset, code.indexOf('empty'));
    }
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_events_hashString() {
    final code = '''
analyzer:
  plugins:
    angular:
      custom_events:
        foo:
          type: String
        bar:
          type: BarEvent
          path: 'package:foo/bar/baz.dart'
        empty:

''';
    final options = AngularOptions.fromString(code, null);
    expect(options.customEvents, isNotNull);
    expect(options.customEventsHashString,
        'e:bar,BarEvent,package:foo/bar/baz.dart,empty,,,foo,String,,');
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_legacy_dynamic_events() {
    final code = '''
analyzer:
  plugins:
    angular:
      custom_events:
        foo:
          type: String
        bar:
          type: BarEvent
          path: 'package:foo/bar/baz.dart'
        empty:

''';
    final options = AngularOptions.fromString(code, null);
    expect(options.customEvents, isNotNull);
    expect(options.customEvents, hasLength(3));

    {
      final event = options.customEvents['foo'];
      expect(event, isNotNull);
      expect(event.name, 'foo');
      expect(event.typeName, 'String');
      expect(event.typePath, isNull);
      expect(event.nameOffset, code.indexOf('foo'));
    }

    {
      final event = options.customEvents['bar'];
      expect(event, isNotNull);
      expect(event.name, 'bar');
      expect(event.typeName, 'BarEvent');
      expect(event.typePath, 'package:foo/bar/baz.dart');
      expect(event.nameOffset, code.indexOf('bar'));
    }

    {
      final event = options.customEvents['empty'];
      expect(event, isNotNull);
      expect(event.name, 'empty');
      expect(event.typeName, null);
      expect(event.typePath, null);
      expect(event.nameOffset, code.indexOf('empty'));
    }
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_legacy_mangledValueIgnored() {
    // TODO(mfairhurst) this should be an error/warning.
    // However, the most important thing is that we don't propagate the mangled
    // values which can cause later crashes.
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    angular:
      custom_tag_names: true
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, const TypeMatcher<List>());
    expect(options.customTagNames, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_legacy_selfLoading() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    angular_analyzer_plugin:
      custom_tag_names:
        - foo
        - bar
        - baz

''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, equals(['foo', 'bar', 'baz']));
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_legacy_simple_tags() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    angular:
      custom_tag_names:
        - foo
        - bar
        - baz
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, equals(['foo', 'bar', 'baz']));
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_mangledValueIgnored() {
    // TODO(mfairhurst) this should be an error/warning.
    // However, the most important thing is that we don't propagate the mangled
    // values which can cause later crashes.
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    - angular

angular:
  custom_tag_names: true
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, const TypeMatcher<List>());
    expect(options.customTagNames, isEmpty);
  }

  // ignore: non_constant_identifier_names
  void test_buildYaml_simple_tags() {
    final options = AngularOptions.fromString('''
analyzer:
  plugins:
    - angular

angular:
  custom_tag_names:
    - foo
    - bar
    - baz
''', null);
    expect(options.customTagNames, isNotNull);
    expect(options.customTagNames, equals(['foo', 'bar', 'baz']));
  }
}
