import 'dart:async';

import 'package:logging/logging.dart';

/// [Symbol] used to provide and lookup a zoned [Logger].
const loggerKey = #loggerKey;

/// [Logger] of the current zone.
///
/// If the current zone has no [Logger], a default singleton is returned.
Logger get logger => Zone.current[loggerKey] ?? new Logger('ng');
