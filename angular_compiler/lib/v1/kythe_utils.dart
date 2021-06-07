import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' show AssetId;
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/find_components.dart'
    show findComponentsAndDirectives;
import 'package:angular_compiler/v2/context.dart';

export 'package:angular_compiler/v1/src/compiler/template_compiler.dart'
    show AngularArtifacts, NormalizedComponentWithViewDirectives;
export 'package:angular_compiler/v1/src/compiler/template_parser/ast_template_parser.dart'
    show matchElementDirectives;

Future<AngularArtifacts>? angularArtifactsForKythe(LibraryElement element) {
  final assetId = _toAssetId(element.identifier);
  if (assetId == null) return null;
  final exceptionHandler = ComponentVisitorExceptionHandler();
  return runWithContext(
      CompileContext(
        assetId,
        policyExceptions: {},
        policyExceptionsInPackages: {},
        isNullSafe: element.isNonNullableByDefault,
        enableDevTools: false,
      ), () async {
    return findComponentsAndDirectives(
        LibraryReader(element), exceptionHandler);
  });
}

AssetId? _toAssetId(String identifier) {
  var uri = Uri.parse(identifier);
  if (!(uri.scheme == 'package' || uri.scheme == 'asset')) {
    return null;
  }
  return AssetId.resolve(uri);
}
