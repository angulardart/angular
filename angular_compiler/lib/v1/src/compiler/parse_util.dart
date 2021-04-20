import 'package:source_span/source_span.dart';
import 'package:angular_ast/angular_ast.dart';
import 'package:angular_compiler/v2/context.dart';

/// Collects parsing exceptions from `angular_ast`, converting to [BuildError].
///
/// See [throwErrorsIfAny].
class AstExceptionHandler extends RecoveringExceptionHandler {
  /// Contents of the source file.
  final String _contents;

  /// URL to the source file.
  final String _sourceUrl;

  /// Directive that is being compiled.
  final String _directiveName;

  AstExceptionHandler(
    this._contents,
    this._sourceUrl,
    this._directiveName,
  );

  /// Converts and throws [exceptions] as a [BuildError].
  ///
  /// If no [exceptions] were collected during parsing no error is thrown.
  void throwErrorsIfAny() {
    if (exceptions.isEmpty) {
      return;
    }
    final sourceFile = SourceFile.fromString(_contents, url: _sourceUrl);
    throw BuildError.fromMultiple(
      exceptions.map(
        (e) => BuildError.forSourceSpan(
          sourceFile.span(e.offset!, e.offset! + e.length!),
          e.errorCode.message,
        ),
      ),
      'Errors in $_sourceUrl while compiling component $_directiveName',
    );
  }
}
