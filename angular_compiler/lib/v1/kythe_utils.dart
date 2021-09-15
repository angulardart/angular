import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart' show AssetId;
import 'package:source_gen/source_gen.dart';
import 'package:angular_compiler/v1/src/compiler/template_compiler.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/component_visitor_exceptions.dart';
import 'package:angular_compiler/v1/src/source_gen/template_compiler/find_components.dart'
    show findComponentsAndDirectives;
import 'package:angular_compiler/v2/context.dart';

export 'package:angular_compiler/v1/src/compiler/compile_metadata.dart'
    show CompileDirectiveMetadata;
export 'package:angular_compiler/v1/src/compiler/template_compiler.dart'
    show AngularArtifacts, NormalizedComponentWithViewDirectives;
export 'package:angular_compiler/v1/src/compiler/template_parser/ast_template_parser.dart'
    show matchElementDirectives;

typedef UncaughtExceptionHandler = bool Function(
    Object exception, StackTrace stackTrace);

Future<AngularArtifacts?>? angularArtifactsForKythe(LibraryElement element,
    {UncaughtExceptionHandler? uncaughtExceptionHandler}) {
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
    try {
      return findComponentsAndDirectives(
          LibraryReader(element), exceptionHandler);
    } catch (e, s) {
      if (uncaughtExceptionHandler?.call(e, s) ?? false) {
        return null;
      } else {
        rethrow;
      }
    }
  });
}

AssetId? _toAssetId(String identifier) {
  var uri = Uri.parse(identifier);
  if (!(uri.scheme == 'package' || uri.scheme == 'asset')) {
    return null;
  }
  return AssetId.resolve(uri);
}
