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
///
/// Currently the plugin may be configured one of two ways:
///
/// ```
/// analyzer:
///   plugins:
///     angular:
///       # options here
/// ```
///
/// or:
///
/// ```
/// analyzer:
///   plugins:
///     - angular
///
/// angular:
///   # options here
/// ```
///
/// Currently we support both. However, we ideally would only support option #2
/// some time in the future, for three reasons:
///
/// - Option #1 mixes with the analyzer namespace, confusing whose job it is to
///   validate the plugin config.
/// - Users cannot mix list syntax & map syntax in YAML. So enabling a second
///   plugin where one has a map config means all must have a map config.
/// - Forks of the plugin (such as using the exact-version loading method where
///   you load angular_analyzer_plugin as itself) are not loaded the same way,
///   and require modifying this code to find their specific settings.
class AngularOptions {
  final List<String> customTagNames;
  final Map<String, CustomEvent> customEvents;
  final Source source;

  String _customEventsHashString;

  AngularOptions({this.customTagNames, this.customEvents, this.source});

  factory AngularOptions.defaults() => _OptionsBuilder.empty().build();

  factory AngularOptions.from(Source source) =>
      _OptionsBuilder(null, source).build();

  /// Testing-only constructor accepting String contents directly.
  @visibleForTesting
  factory AngularOptions.fromString(String content, Source source) =>
      _OptionsBuilder(content, source).build();

  /// A unique signature based on the events, for creating summary hashes.
  String get customEventsHashString =>
      _customEventsHashString ??= _computeCustomEventsHashString();

  /// Lazy generator for [customEventsHashString].
  ///
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

    final buffer = StringBuffer()..write('e:');
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

  _OptionsBuilder(String content, this.source)
      : analysisOptions = loadYaml(content ?? source.contents.data) {
    load();
  }
  _OptionsBuilder.empty() : source = null;

  AngularOptions build() => AngularOptions(
      customTagNames: customTagNames,
      customEvents: customEvents,
      source: source);

  T getOption<T>(String key, bool validator(input)) {
    if (angularOptions != null && validator(angularOptions[key])) {
      return angularOptions[key] as T;
    }
    return null;
  }

  bool isListOfStrings(values) =>
      values is List && values.every((value) => value is String);

  bool isMapOfMapsOrNull(values) =>
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

  /// Load the options section where custom events etc are defined.
  ///
  /// Look for a plugin enabled by name [key], which for is allowed via
  /// "angular" or "angular_analyzer_plugin." Return true if that plugin is
  /// specified, for backwards compatibility, it may have config to load into
  /// [angularOptions].
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

    // Backwards compat: support a map of options under `plugins: x: ...`.
    if ((pluginsSection as Map).containsKey(key)) {
      angularOptions = pluginsSection[key];
      return true;
    }

    return false;
  }

  /// Attempt to load the top level `angular` section into [angularOptions].
  ///
  /// If the section exists and is a map, return true. This is the going-forward
  /// default case.
  bool loadTopLevelSection() {
    if (analysisOptions['angular'] is Map) {
      angularOptions = analysisOptions['angular'];
      return true;
    }
    return false;
  }

  void resolve() {
    customTagNames = List<String>.from(
        getOption<List>('custom_tag_names', isListOfStrings) ?? []);
    getOption<YamlMap>('custom_events', isMapOfMapsOrNull)
        ?.nodes
        ?.forEach((nameNodeKey, props) {
      final nameNode = nameNodeKey as YamlScalar;
      final name = nameNode.value as String;
      final offset = nameNode.span.start.offset;
      customEvents[name] = props is YamlMap
          ? CustomEvent(
              name, props['type'] as String, props['path'] as String, offset)
          // Handle `event:` with no value, a shortcut for dynamic.
          : CustomEvent(name, null, null, offset);
    });
  }
}
