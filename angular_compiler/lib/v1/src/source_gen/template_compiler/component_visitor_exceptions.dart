import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:build/build.dart';
import 'package:source_span/source_span.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v1/src/compiler/compile_metadata.dart';
import 'package:angular_compiler/v1/src/source_gen/common/annotation_matcher.dart';
import 'package:angular_compiler/v2/context.dart';

class IndexedAnnotation<T extends Element> {
  final T element;
  final ElementAnnotation annotation;
  final int annotationIndex;

  IndexedAnnotation(this.element, this.annotation, this.annotationIndex);
}

class ComponentVisitorExceptionHandler {
  final List<AsyncBuildError> _errors = [];
  final List<AsyncBuildError> _warnings = [];

  void handle(AsyncBuildError error) {
    _errors.add(error);
  }

  void handleWarning(AsyncBuildError warning) {
    _warnings.add(warning);
  }

  Future<void> maybeReportErrors(Resolver resolver) async {
    if (_warnings.isNotEmpty) {
      final buildWarnings = await Future.wait(
          _warnings.map((warning) => warning.resolve(resolver)));
      buildWarnings
          .forEach((buildWarning) => logWarning(buildWarning.toString()));
    }
    if (_errors.isEmpty) {
      return;
    }
    final buildErrors = await Future.wait(
      _errors.map((error) => error.resolve(resolver)),
    );
    throw BuildError.fromMultiple(buildErrors);
  }
}

Future<ElementDeclarationResult> _resolvedClassResult(
  Resolver resolver,
  Element element,
) async {
  late AssetId assetId;
  try {
    assetId = await resolver.assetIdForElement(element);
  } on UnresolvableAssetException catch (_) {
    _throwInvalidSummaryError(element.source!.fullName);
  }
  // A `part of` dart file is not a standalone dart library. Thus,
  // [library] is null when an error occurs in a `part of` dart file.
  // It loses all actionable information for clients and returns an unhandled
  // error. The build error below is to reconstruct sufficient information for
  // clients.
  if (!await resolver.isLibrary(assetId)) {
    throw BuildError.withoutContext('Errors in part file $assetId');
  }
  final library = await resolver.libraryFor(
    assetId,
    allowSyntaxErrors: true,
  );
  final result = await element.session!.getResolvedLibraryByElement2(library);
  if (result is ResolvedLibraryResult) {
    return result.getElementDeclaration(element)!;
  }
  _throwInvalidSummaryError(library.source.fullName);
}

Never _throwInvalidSummaryError(String summaryName) {
  // We don't have access to source information in summarized libraries,
  // but another build step will likely emit the root cause errors.
  throw BuildError.withoutContext(
    'Errors in summarized library $summaryName',
  );
}

abstract class AsyncBuildError {
  final String _message;

  AsyncBuildError([this._message = '']);

  Future<BuildError> resolve(Resolver resolver);

  @override
  String toString() => _message;
}

class AngularAnalysisError extends AsyncBuildError {
  final List<AnalysisError> constantEvaluationErrors;
  final IndexedAnnotation<Element> indexedAnnotation;

  AngularAnalysisError(this.constantEvaluationErrors, this.indexedAnnotation);

  @override
  Future<BuildError> resolve(Resolver resolver) async {
    final annotationSource = indexedAnnotation.annotation.toSource();

    var hasOffsetInformation =
        constantEvaluationErrors.any((error) => error.offset >= 0);

    // If this code is called from a tool using [AnalysisResolvers], then
    //   1) [constantEvaluationErrors] already has source location information
    //   2) [ResolvedLibraryResultImpl] will NOT have the errors.
    // So, we return immediately with the information in
    // [constantEvaluationErrors].
    if (hasOffsetInformation) {
      return Future.value(_buildErrorForAnalysisErrors(constantEvaluationErrors,
          indexedAnnotation.element, annotationSource));
    }

    ElementDeclarationResult result;
    try {
      result = await _resolvedClassResult(resolver, indexedAnnotation.element);
    } on BuildError catch (buildError) {
      return BuildError.withoutContext(
        '$buildError while compiling $annotationSource',
      );
    }

    var resolvedMetadata = _metadataFromAncestry(result.node);

    var resolvedAnnotation =
        resolvedMetadata[indexedAnnotation.annotationIndex];

    // Only include the errors that are inside the annotation.
    return _buildErrorForAnalysisErrors(
        result.resolvedUnit!.errors.where((error) =>
            error.offset >= resolvedAnnotation.offset &&
            error.offset <= resolvedAnnotation.end),
        indexedAnnotation.element,
        annotationSource);
  }

  BuildError _buildErrorForAnalysisErrors(Iterable<AnalysisError> errors,
      Element element, String annnotationSouce) {
    String reason;
    if (element is ClassElement && annnotationSouce.startsWith('@Component')) {
      reason = ''
          'Compiling @Component-annotated class "${element.name}" '
          'failed.\n\n${messages.analysisFailureReasons}';
    } else {
      reason =
          'Compiling annotation $annnotationSouce on element $element failed.';
    }

    return BuildError.withoutContext(
      messages.unresolvedSource(
        errors.map((e) {
          final sourceUrl = e.source.uri;
          final sourceContent = e.source.contents.data;

          // TODO(b/180549869): remove the negative length check.
          if (sourceContent.isEmpty || e.length.isNegative) {
            return SourceSpanMessageTuple(
                SourceSpan(
                    SourceLocation(0, sourceUrl: sourceUrl, line: 0, column: 0),
                    SourceLocation(0, sourceUrl: sourceUrl, line: 0, column: 0),
                    ''),
                '${e.message} [with offsets into source file missing]');
          }

          return SourceSpanMessageTuple(
            sourceSpanWithLineInfo(
              e.offset,
              e.length,
              sourceContent,
              sourceUrl,
            ),
            e.message,
          );
        }),
        reason: reason,
      ),
    );
  }
}

class UnresolvedExpressionError extends AsyncBuildError {
  final Iterable<AstNode> expressions;
  final ClassElement componentType;
  final CompilationUnitElement compilationUnit;

  UnresolvedExpressionError(
      this.expressions, this.componentType, this.compilationUnit);

  @override
  Future<BuildError> resolve(Resolver resolver) =>
      Future.value(_buildErrorForUnresolvedExpressions(
          expressions, componentType, compilationUnit));

  // TODO(deboer): Since we are checking ElementAnnotation.constantValueErrors,
  // all code paths that call this function are unreachable.
  // If we don't see any errors in the wild, delete this code.
  BuildError _buildErrorForUnresolvedExpressions(Iterable<AstNode> expressions,
      ClassElement componentType, CompilationUnitElement compilationUnit) {
    return BuildError.withoutContext(
      messages.unresolvedSource(
        expressions.map((e) {
          return SourceSpanMessageTuple(
            sourceSpanWithLineInfo(
              e.offset,
              e.length,
              componentType.source.contents.data,
              componentType.source.uri,
            ),
            'This argument *may* have not been resolved',
          );
        }),
        reason: ''
            'Compiling @Component annotated class "${componentType.name}" '
            'failed.\n'
            'NOTE: Your build triggered an error in the Angular error reporting\n'
            'code. Please report a bug: ${messages.urlFileBugs}\n'
            '\n\n${messages.analysisFailureReasons}',
      ),
    );
  }
}

class UnusedDirectiveTypeError extends ErrorMessageForAnnotation {
  final ClassElement element;
  final CompileTypedMetadata directiveType;

  static IndexedAnnotation firstComponentAnnotation(ClassElement element) {
    final index = element.metadata.indexWhere(isComponent);
    if (index == -1) {
      throw ArgumentError('[element] must have a @Component annotation');
    }
    return IndexedAnnotation(element, element.metadata[index], index);
  }

  UnusedDirectiveTypeError(this.element, this.directiveType)
      : super(
            firstComponentAnnotation(element),
            'Entry in "directiveTypes" missing corresponding entry in '
            '"directives" for "${directiveType.name}".\n\n'
            'If you recently removed "${directiveType.name}" from "directives", '
            'please also remove its corresponding entry from "directiveTypes".');
}

/// Find the ancestor node that should have the metadata and return
/// that metadata.
/// Angular only looks at metadata on class declarations,
/// class members and formal parameters.
List<Annotation> _metadataFromAncestry(AstNode node) {
// NOTE: We check for [ClassMember] or [ClassDeclaration] explicitly
// as some [AnnotatedNode]s in the ancestor chain do not have
// the metadata we are looking for.  See
// 519_missing_query_selector_test.dart for an example of this condition.
  if (node is ClassMember ||
      node is ClassDeclaration ||
      node is EnumDeclaration ||
      node is FunctionDeclaration) {
    return (node as AnnotatedNode).metadata;
  } else if (node is FormalParameter) {
    return node.metadata;
  }
  return _metadataFromAncestry(node.parent!);
}

class ErrorMessageForAnnotation extends AsyncBuildError {
  final IndexedAnnotation indexedAnnotation;

  ErrorMessageForAnnotation(
    this.indexedAnnotation,
    String message,
  ) : super(message);

  @override
  Future<BuildError> resolve(Resolver resolver) async {
    final annotationIndex = indexedAnnotation.annotationIndex;

    ElementDeclarationResult result;
    try {
      result = await _resolvedClassResult(resolver, indexedAnnotation.element);
    } on BuildError catch (buildError) {
      final annotationSource = indexedAnnotation.annotation.toSource();
      return BuildError.withoutContext(
        '$buildError while compiling $annotationSource: $this',
      );
    }

    var resolvedMetadata = _metadataFromAncestry(result.node);

    var resolvedAnnotation =
        resolvedMetadata[annotationIndex].elementAnnotation!;
    return BuildError.forAnnotation(resolvedAnnotation, toString());
  }
}
