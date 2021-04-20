import 'package:analyzer/dart/element/element.dart';
// ignore: implementation_imports
import 'package:analyzer/src/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_span/source_span.dart';

/// Base error type for all _known_ fatal errors encountered while compiling.
///
/// Errors that are not sub-types of [BuildError] are treated as _unhandled_
/// errors and are logged internally as invariants we should instead be fixing
/// or treating as build errors.
abstract class BuildError extends Error {
  // Default constructor for inheritance only.
  //
  // This is required because otherwise no default constructor is created.
  BuildError();

  /// Collapse multiple [errors] into a single error.
  ///
  /// This constructor is suitable when collecting lazy errors from another part
  /// of the compilation process (such as parsing HTML or CSS) to turn into a
  /// single but immediate error:
  /// ```
  /// void example(ExternalParser parser) {
  ///   final errors = parser.getErrors();
  ///   if (errors.isNotEmpty) {
  ///     // Impossible to continue
  ///     throw BuildError.fromMultiple(errors, 'Errors occured parsing');
  ///   }
  /// }
  /// ```
  ///
  /// When defining a custom [header], it should not end with `:`.
  factory BuildError.fromMultiple(
    Iterable<BuildError> errors, [
    String header = 'Multiple errors occurred',
  ]) =>
      _MultipleBuildError(errors.toList(), header);

  /// Create a build error using the provided source span as [context].
  factory BuildError.forSourceSpan(
    SourceSpan context,
    String message,
  ) = _SourceSpanBuildError;

  /// Creates a build error using the provided source annotation as [context].
  factory BuildError.forAnnotation(
    ElementAnnotation context,
    String message,
  ) {
    // TOOD(b/170758395): Replace w/ patches from upstream (see pkg/source_gen).
    // https://github.com/dart-lang/sdk/issues/32454
    final annotation = context as ElementAnnotationImpl;
    final astNode = annotation.annotationAst;
    final file = SourceFile.fromString(
      annotation.source.contents.data,
      url: annotation.source.uri,
    );
    return BuildError.forSourceSpan(
      file.span(astNode.offset, astNode.offset + astNode.length),
      message,
    );
  }

  /// Creates a build error using the provided source element as [context].
  factory BuildError.forElement(
    Element context,
    String message,
  ) {
    final source = context.source;
    if (source == null || source.contents.data.isEmpty) {
      final warning = source == null
          ? 'No source text available for $context'
          : 'No source text available for $context (${source.uri})';
      log.warning('$warning: the next error may be terse');
      return BuildError.withoutContext(message);
    }
    return BuildError.forSourceSpan(
      spanForElement(context),
      message,
    );
  }

  /// Create a simple build error with a [message]-only description.
  ///
  /// Where possible, it is greatly preferable to use another [BuildError]
  /// constructor or sub-type that provides context on why the error occurred;
  /// using [withoutContext] can be suitable when either the context is
  /// explicitly provided as part of the [message].
  factory BuildError.withoutContext(String message) = _SimpleBuildError;
}

class _SimpleBuildError extends BuildError {
  final String _message;

  _SimpleBuildError(this._message);

  @override
  String toString() => _message;
}

class _MultipleBuildError extends BuildError {
  final List<BuildError> _errors;
  final String? _header;

  _MultipleBuildError(
    this._errors, [
    this._header,
  ])  : assert(_errors.isNotEmpty),
        assert(_header != null && !_header.endsWith(':'));

  @override
  String toString() => '$_header:\n${_errors.join('\n')}';
}

class _SourceSpanBuildError extends BuildError {
  final SourceSpan _sourceSpan;
  final String _message;

  _SourceSpanBuildError(
    this._sourceSpan,
    this._message,
  );

  @override
  String toString() => _sourceSpan.message(_message);
}
