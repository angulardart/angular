import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:source_span/source_span.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';
import 'package:angular_compiler/cli.dart';

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

  Future<void> maybeReportErrors() async {
    if (_warnings.isNotEmpty) {
      final buildWarnings =
          await Future.wait(_warnings.map((warning) => warning.resolve()));
      buildWarnings.forEach((buildWarning) => logWarning(buildWarning.message));
    }
    if (_errors.isEmpty) {
      return;
    }
    final buildErrors =
        await Future.wait(_errors.map((error) => error.resolve()));
    throw BuildError(
        buildErrors.map((buildError) => buildError.message).join("\n\n"));
  }
}

Future<ElementDeclarationResult> _resolvedClassResult(Element element) async {
  var libraryElement = element.library;
  var libraryResult =
      await libraryElement.session.getResolvedLibraryByElement(libraryElement);
  if (libraryResult.state == ResultState.NOT_A_FILE) {
    // We don't have access to source information in summarized libraries,
    // but another build step will likely emit the root cause errors.
    throw BuildError("Analysis errors in summarized library "
        "${libraryElement.source.fullName}");
  }
  return libraryResult.getElementDeclaration(element);
}

class AsyncBuildError extends BuildError {
  AsyncBuildError([String message]) : super(message);

  Future<BuildError> resolve() => Future.value(this);
}

class AngularAnalysisError extends AsyncBuildError {
  final List<AnalysisError> constantEvaluationErrors;
  final IndexedAnnotation<Element> indexedAnnotation;

  AngularAnalysisError(this.constantEvaluationErrors, this.indexedAnnotation);

  @override
  Future<BuildError> resolve() async {
    final annotationSource = indexedAnnotation.annotation.toSource();

    bool hasOffsetInformation =
        constantEvaluationErrors.any((error) => error.offset != 0);
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
      result = await _resolvedClassResult(indexedAnnotation.element);
    } on BuildError catch (buildError) {
      return BuildError(
          '${buildError.message} while compiling $annotationSource');
    }

    List<Annotation> resolvedMetadata =
        _metadataWithWorkaround(result.node, indexedAnnotation.element);

    if (resolvedMetadata == null) {
      return BuildError.forElement(indexedAnnotation.element, message);
    }

    var resolvedAnnotation =
        resolvedMetadata[indexedAnnotation.annotationIndex];

    // Only include the errors that are inside the annotation.
    return _buildErrorForAnalysisErrors(
        result.resolvedUnit.errors.where((error) =>
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

    return BuildError(
      messages.unresolvedSource(
        errors.map((e) {
          final sourceUrl = e.source.uri;
          final sourceContent = e.source.contents.data;

          if (sourceContent.isEmpty) {
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
  Future<BuildError> resolve() =>
      Future.value(_buildErrorForUnresolvedExpressions(
          expressions, componentType, compilationUnit));

  // TODO(deboer): Since we are checking ElementAnnotation.constantValueErrors,
  // all code paths that call this function are unreachable.
  // If we don't see any errors in the wild, delete this code.
  BuildError _buildErrorForUnresolvedExpressions(Iterable<AstNode> expressions,
      ClassElement componentType, CompilationUnitElement compilationUnit) {
    return BuildError(
      messages.unresolvedSource(
        expressions.map((e) {
          return SourceSpanMessageTuple(
            sourceSpanWithLineInfo(
              e.offset,
              e.length,
              componentType.source.contents.data,
              componentType.source.uri,
              lineInfo: compilationUnit.lineInfo,
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
      throw ArgumentError("[element] must have a @Component annotation");
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
  return _metadataFromAncestry(node.parent);
}

List<Annotation> _metadataWithWorkaround(
    AstNode node, Element originalElement) {
  List<Annotation> resolvedMetadata = _metadataFromAncestry(node);

  // TODO(b/124524319): Remove this check when the Analyzer is fixed.
  if (resolvedMetadata.isEmpty &&
      originalElement is ParameterElement &&
      node is ConstructorDeclaration) {
    return null;
  }
  return resolvedMetadata;
}

class ErrorMessageForAnnotation extends AsyncBuildError {
  final IndexedAnnotation indexedAnnotation;

  ErrorMessageForAnnotation(
    this.indexedAnnotation,
    String message,
  ) : super(message);

  @override
  Future<BuildError> resolve() async {
    final annotationIndex = indexedAnnotation.annotationIndex;

    ElementDeclarationResult result;
    try {
      result = await _resolvedClassResult(indexedAnnotation.element);
    } on BuildError catch (buildError) {
      return buildError;
    }

    List<Annotation> resolvedMetadata =
        _metadataWithWorkaround(result.node, indexedAnnotation.element);

    if (resolvedMetadata == null) {
      return BuildError.forElement(indexedAnnotation.element, message);
    }

    ElementAnnotation resolvedAnnotation =
        resolvedMetadata[annotationIndex].elementAnnotation;
    return BuildError.forAnnotation(resolvedAnnotation, message);
  }
}

class ErrorMessageForElement extends AsyncBuildError {
  final Element element;

  ErrorMessageForElement(this.element, String message) : super(message);

  @override
  Future<BuildError> resolve() =>
      Future.value(BuildError.forElement(element, message));
}
