import 'dart:async';

import 'package:angular/src/compiler/offline_compiler.dart';

final _templateCompilerKey = #templateCompilerKey;

/// The [OfflineCompiler] for the current zone.
///
/// This will return `null` if there is no [OfflineCompiler] registered on the
/// current zone.
OfflineCompiler get templateCompiler =>
    Zone.current[_templateCompilerKey] as OfflineCompiler;
