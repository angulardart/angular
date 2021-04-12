import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart';

final log = Logger('Pub');

class Pub {
  /// Pub invocation e.g. "pub", "/path/to/pub".
  final String invocation;

  /// The context for pub invocations.
  final String workspaceDir;

  Pub._(this.invocation, this.workspaceDir);

  /// Setup pub invocation and verify it by checking pub's version.
  static Future<Pub> init(String workspaceDir, {String sdk}) async {
    String pub;
    if (sdk != null) {
      log.info('Use custom SDK: "$sdk"');
      pub = join(sdk, 'bin', 'pub');
    } else {
      log.info('Use SDK from PATH');
      pub = 'pub';
    }
    var args = '--version';
    var pubVersion = '$pub $args';

    log.info('Run "$pubVersion"');
    await Process.start(pub, args.split(' ')).then((process) async {
      await stdout.addStream(process.stdout);
      await stderr.addStream(process.stderr);
      await process.exitCode.then((exitCode) {
        if (exitCode != 0) {
          log.severe('"$pubVersion" failed with exit code: $exitCode');
          throw ('"$pubVersion" failure');
        }
      });
    });
    return Pub._(pub, workspaceDir);
  }

  /// Wrapper that invokes 'pub update' inside workspace dir.
  Future<void> update() async {
    var args = 'update';
    var pubUpdate = '$invocation $args';

    log.info('Run "$pubUpdate" inside "$workspaceDir"');
    await Process.start(invocation, args.split(' '),
            workingDirectory: workspaceDir)
        .then((process) async {
      await stdout.addStream(process.stdout);
      await stderr.addStream(process.stderr);
      await process.exitCode.then((exitCode) {
        if (exitCode == 0) {
          log.info('"$pubUpdate" finished successfully');
        } else {
          log.severe('"$pubUpdate" failed with exit code: $exitCode');
          throw ('"$pubUpdate" failure');
        }
      });
    });
  }

  /// Wrapper that invokes 'pub run build_runner build web'
  /// inside workspace dir.
  Future<void> build() async {
    var args = 'run build_runner build web';
    var pubBuild = '$invocation $args';

    log.info('Run "$pubBuild" inside "$workspaceDir"');
    await Process.start(invocation, args.split(' '),
            workingDirectory: workspaceDir)
        .then((process) async {
      await stdout.addStream(process.stdout);
      await stderr.addStream(process.stderr);
      await process.exitCode.then((exitCode) {
        if (exitCode == 0) {
          log.info('"$pubBuild" finished successfully');
        } else {
          log.severe('"$pubBuild" failed with exit code: $exitCode');
          throw ('"$pubBuild" failure');
        }
      });
    });
  }
}
