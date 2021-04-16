/// Supports the compiler running in a command-line interface (CLI).
///
/// Utilities and classes here are not directly related to the compilation
/// pipeline, but instead are used to manage the process, logging, exception
/// handling, and other related functionality.
///
/// **NOTE**: This is not an externally stable API. Use at your own risk.
@experimental
library angular_compiler.cli;

import 'package:meta/meta.dart';

export 'src/angular_compiler/cli/builder.dart';
export 'src/angular_compiler/cli/flags.dart';
export 'src/angular_compiler/cli/logging.dart';
export 'src/angular_compiler/cli/messages.dart'
    show messages, SourceSpanMessageTuple;
