import 'dart:io';

import 'package:dev/find.dart';
import 'package:path/path.dart' as p;

/// Finds and runs `pub upgrade` for all sub-packages.
void main(List<String> args) {
  final pubspecs = findRelevantPubspecs();
  stdout.writeln('Found ${pubspecs.length} packages...');

  for (final package in pubspecs.map((f) => p.dirname(f.path))) {
    stdout.writeln('Running "pub upgrade" in "$package"...');
    Process.runSync('pub', const ['upgrade'], workingDirectory: package);
  }
}
