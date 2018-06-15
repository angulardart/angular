import 'package:args/args.dart';

/// Returns whether executing in "dry run" mode (i.e. for testing).
bool isDryRun(List<String> args) => _argParser.parse(args)['dry-run'] as bool;
final _argParser = ArgParser()
  ..addFlag(
    'dry-run',
    abbr: 'd',
    defaultsTo: false,
    negatable: false,
    help: 'Returns an exit code of "1" if we would update a pubspec.yaml.',
  );
