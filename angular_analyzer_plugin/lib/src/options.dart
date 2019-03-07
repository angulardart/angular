import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:yaml/yaml.dart';

/// Class representing the plugin options in `analysis_options.yaml`.
///
/// Not much configuration is currently supported, but users may add custom
/// tags and events so that they can integrate with web components/polymer.
///
/// It is important that we can accurately hash the options, so that if users
/// change their analysis options, the plugin will rerun its analysis instead of
/// using out-of-date cache results.
class AngularOptions {
  final List<String> customTagNames;
  final Map<String, CustomEvent> customEvents;
  final Source source;

  String _customEventsHashString;

  AngularOptions({this.customTagNames, this.customEvents, this.source});

  factory AngularOptions.defaults() => new _OptionsBuilder.empty().build();

  factory AngularOptions.from(Source source) =>
      new _OptionsBuilder(null, source).build();

  /// For tests, its easier to pass the Source's contents directly rather than
  /// creating mocks that returned mocked data that mocked contents.
  @visibleForTesting
  factory AngularOptions.fromString(String content, Source source) =>
      new _OptionsBuilder(content, source).build();

  /// A unique signature based on the events for hashing the settings into the
  /// resolution hashes.
  String get customEventsHashString =>
      _customEventsHashString ??= _computeCustomEventsHashString();

  /// When events are present, generate a string in the form of
  /// 'e:name,type,path,name,type,path'. Take care we sort before emitting. And
  /// in theory we could/should escape colon and comma, but the only one of
  /// those that should appear in a valid config is the colon in 'package:',
  /// and due to its position between the fixed placement of commas, it should
  /// not be able to make one signature look like another.
  String _computeCustomEventsHashString() {
    if (customEvents.isEmpty) {
      return '';
    }

    final buffer = new StringBuffer()..write('e:');
    for (final key in customEvents.keys.toList()..sort()) {
      final event = customEvents[key];
      buffer
        ..write(event.name ?? '')
        ..write(',')
        ..write(event.typeName ?? '')
        ..write(',')
        ..write(event.typePath ?? '')
        ..write(',');
    }
    return buffer.toString();
  }
}

/// A custom event allows interaction with web components/polymer.
class CustomEvent {
  final String name;
  final String typeName;
  final String typePath;
  final int nameOffset;

  DartType resolvedType;

  CustomEvent(this.name, this.typeName, this.typePath, this.nameOffset);
}

class _OptionsBuilder {
  dynamic analysisOptions;
  dynamic angularOptions;

  List<String> customTagNames = const [];
  Map<String, CustomEvent> customEvents = {};
  final Source source;

  _OptionsBuilder(String content, Source source)
      : source = source,
        analysisOptions = loadYaml(content ?? source.contents.data) {
    load();
  }
  _OptionsBuilder.empty() : source = null;

  AngularOptions build() => new AngularOptions(
      customTagNames: customTagNames, customEvents: customEvents);

  T getOption<T>(String key, bool validator(input)) {
    if (angularOptions != null && validator(angularOptions[key])) {
      return angularOptions[key] as T;
    }
    return null;
  }

  bool isListOfStrings(values) =>
      values is List && values.every((value) => value is String);

  bool isMapOfObjects(values) =>
      values is YamlMap &&
      values.values.every((value) => value is YamlMap || value == null);

  void load() {
    if (analysisOptions['analyzer'] == null ||
        analysisOptions['analyzer']['plugins'] == null) {
      return;
    }

    if (loadTopLevelSection() ||
        loadPluginSection('angular') ||
        loadPluginSection('angular_analyzer_plugin')) {
      resolve();
    }
  }

  /// Look for a plugin enabled by name [key], which for historical purposes is
  /// allowed via "angular" or "angular_analyzer_plugin." Return true if that
  /// plugin is specified, and as an edge case, it may have config to load into
  /// [angularOptions]. This will soon be removed.
  bool loadPluginSection(String key) {
    final pluginsSection = analysisOptions['analyzer']['plugins'];

    // This is common. This means the plugin is turned on but has no config.
    if (pluginsSection is List) {
      return pluginsSection.contains(key);
    }

    // Protect against confusing configs
    if (pluginsSection is! Map) {
      return false;
    }

    // Outdated edge case, support a map of options under `plugins: x: ...`.
    final specified = (pluginsSection as Map).containsKey(key);
    if (specified) {
      angularOptions = pluginsSection[key];
    }
    return specified;
  }

  /// Attempt to load the top level `angular` config section into
  /// [angularOptions]. If the section exists and is a map, return true. This is
  /// the going-forward default case.
  bool loadTopLevelSection() {
    if (analysisOptions['angular'] is Map) {
      angularOptions = analysisOptions['angular'];
      return true;
    }
    return false;
  }

  void resolve() {
    customTagNames = new List<String>.from(
        getOption<List>('custom_tag_names', isListOfStrings) ?? []);
    getOption<YamlMap>('custom_events', isMapOfObjects)
        ?.nodes
        ?.forEach((nameNodeKey, props) {
      final nameNode = nameNodeKey as YamlScalar;
      final name = nameNode.value as String;
      final offset = nameNode.span.start.offset;
      customEvents[name] = props is YamlMap
          ? new CustomEvent(
              name, props['type'] as String, props['path'] as String, offset)
          // Handle `event:` with no value, a shortcut for dynamic.
          : new CustomEvent(name, null, null, offset);
    });
  }
}
