import 'dart:io';

import 'package:glob/glob.dart';

/// Returns a list of all `pubspec.yaml` files that are relevant to us.
List<File> findRelevantPubspecs() => (_include.listSync().toList()
      ..sort((a, b) => a.path.compareTo(b.path))
      ..removeWhere((f) => _exclude.any((g) => g.matches(f.path))))
    .cast<File>();

// Find all packages.
final _include = Glob('**/pubspec.yaml');

// ... But exclude ones not relevant here.
// TODO: Perhaps just import .gitignore as well.
final _exclude = [
  Glob('dev/**'),
  Glob('angular/tools/**'),
  Glob('**/build/**'),
];
