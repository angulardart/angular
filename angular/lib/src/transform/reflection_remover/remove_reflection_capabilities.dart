import 'dart:async';

import 'package:analyzer/analyzer.dart';
import 'package:barback/barback.dart';
import 'package:angular_compiler/angular_compiler.dart';

import 'codegen.dart';
import 'entrypoint_matcher.dart';
import 'rewriter.dart';

/// Finds the call to the Angular2 `ReflectionCapabilities` constructor
/// in `reflectionEntryPoint` and replaces it with a call to
/// `setupReflection` in `newEntryPoint`.
///
/// This only searches the code in `reflectionEntryPoint`, not `part`s,
/// `import`s, `export`s, etc.
Future<String> removeReflectionCapabilities(
  NgAssetReader reader,
  AssetId reflectionEntryPoint,
) async {
  var code = await reader.readText(reflectionEntryPoint.toString());
  var codegen = new Codegen(reflectionEntryPoint);
  return new Rewriter(
    code,
    codegen,
    new EntrypointMatcher(reflectionEntryPoint),
  )
      .rewrite(parseCompilationUnit(code, name: reflectionEntryPoint.path));
}
