import 'dart:io';

import 'package:yaml/yaml.dart';

import 'package:dev/dry.dart';
import 'package:dev/find.dart';

/// What Dart SDK version to require for all pub packages.
///
/// This allows us to (more) safely use new language/library features.
const useSdkRange = '>=2.5.0-dev.1.0 <3.0.0';

void main(List<String> args) {
  final dryRun = isDryRun(args);
  final pubspecs = findRelevantPubspecs();
  stdout.writeln('Configured SDK version: $useSdkRange');
  stdout.writeln('Reviewing ${pubspecs.length} pubspec.yaml files...');
  var hasStale = 0;

  for (final pubspec in pubspecs) {
    final contents = pubspec.readAsStringSync();
    final yaml = loadYamlDocument(
      pubspec.readAsStringSync(),
      sourceUrl: pubspec.path,
    ).contents;
    if (yaml is YamlMap && yaml.containsKey('environment')) {
      final node = yaml.nodes['environment'];
      if (node is YamlMap && node.containsKey('sdk')) {
        final sdk = node.nodes['sdk'];
        if ('${sdk.value}' == '$useSdkRange') {
          continue;
        }
        stderr.writeln('${pubspec.path} has a stale SDK: ${sdk.value}');
        hasStale++;

        if (!dryRun) {
          final patched = contents.replaceRange(
            sdk.span.start.offset,
            sdk.span.end.offset,
            '"$useSdkRange"',
          );
          stdout.writeln('Updating...');
          pubspec.writeAsStringSync(patched);
        }
      }
    }
  }

  stdout.writeln('Done!');

  if (!dryRun) {
    return;
  }
  if (hasStale == 0) {
    exitCode = 0;
  } else {
    stderr.writeln('$hasStale files are out of date!');
    exitCode = 1;
  }
}
