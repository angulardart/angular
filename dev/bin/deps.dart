import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:dev/find.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Verifies that non-dev dependency ranges for all packages are compatible.
void main() {
  final allDependencies = SplayTreeMap<String, List<VersionConstraint>>();
  for (final pubspec in findRelevantPubspecs()) {
    _dependenciesOf(pubspec).forEach((package, constraint) {
      allDependencies.putIfAbsent(package, () => []).add(constraint);
    });
  }
  stdout.writeln('All dependencies:');
  stdout.writeln(JsonEncoder.withIndent(
      '  ',
      (encodable) => encodable is VersionConstraint
          ? encodable.toString()
          : encodable.toJson()).convert(allDependencies));

  final failingDeps = List<String>();
  allDependencies.forEach((package, versions) {
    final intersection = VersionConstraint.intersection(versions);
    if (intersection.isEmpty) {
      failingDeps.add(package);
    }
  });

  // Example output:
  // https://gist.github.com/matanlurey/26b65129106a72e9461f2ac56f5bf51c
  if (failingDeps.isNotEmpty) {
    stderr.writeln('Incompatible version ranges for: $failingDeps');
    failingDeps.forEach((package) {
      stderr.writeln('$package: ${allDependencies[package]}');
    });
    exitCode = 1;
  } else {
    stdout.writeln('Versions OK!');
    exitCode = 0;
  }
}

Map<String, VersionConstraint> _dependenciesOf(File pubpsec) {
  final yamlDoc = loadYaml(pubpsec.readAsStringSync(), sourceUrl: pubpsec.uri);
  final deps = ((yamlDoc['dependencies'] ?? {}) as Map).cast<String, String>();
  return deps.map((k, v) => MapEntry(
        k,
        v == null || v.isEmpty
            ? VersionConstraint.any
            : VersionConstraint.parse(v),
      ));
}
