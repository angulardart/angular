import 'dart:io';

import 'package:git/git.dart' as git;
import 'package:logging/logging.dart';
import 'package:path/path.dart';

final log = Logger('Repository');

class Repository {
  /// Path to the root of repository.
  final String workspaceDir;

  /// Git repository URL.
  final String _gitUrl;

  /// Git repository ref.
  final String _gitRef;

  /// Path to working dir.
  String _workingDir;

  Repository._(this.workspaceDir, this._gitUrl, this._gitRef)
      : assert(workspaceDir != null && _gitUrl != null && _gitRef != null) {
    _workingDir = workspaceDir;
  }

  String get workingDir => _workingDir;

  /// Fetch and setup git repository locally.
  static Future<Repository> fetch(String gitUrl,
      {String gitRef = 'master'}) async {
    final workspaceDir = await Repository._setupWorkspace();
    final repository = Repository._(workspaceDir, gitUrl, gitRef);
    await repository._clone();
    await repository._checkout();
    return repository;
  }

  /// Create workspace dir in system temporary dir.
  static Future<String> _setupWorkspace() async {
    final systemTempDir = Directory.systemTemp;
    final workspaceDir = await systemTempDir.createTemp();
    log.info('Created workspace: "${workspaceDir.path}"');
    return workspaceDir.path;
  }

  /// Clone git repository in workspace.
  Future<void> _clone() async {
    log.info('Cloning from: "$_gitUrl" to: "$workspaceDir"');
    await git.runGit(['clone', _gitUrl, workspaceDir]);
  }

  /// Checkout repository to relevant ref.
  Future<void> _checkout() async {
    log.info('Checking out to ref: "$_gitRef"');
    await git.runGit([
      '--git-dir=$workspaceDir/.git',
      '--work-tree=$workspaceDir',
      'checkout',
      _gitRef
    ]);
  }

  /// Change working dir relatively to workspace.
  void changeTo(List<String> relativePath) {
    final path = [workspaceDir, ...relativePath];
    _workingDir = path.reduce(join);
    log.info('Changed working dir to: "$workingDir"');
  }
}
