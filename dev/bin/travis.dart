import 'dart:io' show exitCode, stderr, stdout, File;

import 'package:dev/dry.dart';
import 'package:dev/repository.dart';
import 'package:dev/travis.dart';
import 'package:path/path.dart' as p;

/// Writes `<root>/.travis.yml` based on the configuration in this file.
void main(List<String> args) {
  final dryRun = isDryRun(args);
  final repository = Repository.current;
  final generator = TravisGenerator.generate(repository);
  final travisDotYaml = File('.travis.yml');
  final presubmitDotSh = File(p.join('tool', 'presubmit.sh'));

  if (dryRun) {
    if (travisDotYaml.readAsStringSync().trim() == generator.travisConfig ||
        presubmitDotSh.readAsStringSync().trim() == generator.presubmitScript) {
      stdout.writeln('>>> No updates needed <<<');
      return;
    }
    stderr.writeln('Run "pub run dev:travis" to update scripts');
    exitCode = 1;
    return;
  }

  travisDotYaml.writeAsStringSync(generator.travisConfig);
  presubmitDotSh.writeAsStringSync(generator.presubmitScript);
}
