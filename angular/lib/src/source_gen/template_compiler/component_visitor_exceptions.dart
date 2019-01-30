import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/analysis/results.dart';
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

  void handle(AsyncBuildError error) {
    _errors.add(error);
  }

  Future<void> maybeReportErrors() async {
    if (_errors.isEmpty) {
      return;
    }
    final buildErrors =
        await Future.wait(_errors.map((error) => error.resolve()));
    throw BuildError(
        buildErrors.map((buildError) => buildError.message).join("\n\n"));
  }
}

class AsyncBuildError extends BuildError {
  Future<BuildError> resolve() => Future.value(this);
}

class AngularAnalysisError extends AsyncBuildError {
  final List<AnalysisError> constantEvaluationErrors;
  final IndexedAnnotation<ClassElement> indexedAnnotation;

  AngularAnalysisError(this.constantEvaluationErrors, this.indexedAnnotation);

  @override
  Future<BuildError> resolve() async {
    bool hasOffsetInformation =
        constantEvaluationErrors.any((error) => error.offset != 0);
    // If this code is called from a tool using [AnalysisResolvers], then
    //   1) [constantEvaluationErrors] already has source location information
    //   2) [ResolvedLibraryResultImpl] will NOT have the errors.
    // So, we return immediately with the information in
    // [constantEvaluationErrors].
    if (hasOffsetInformation) {
      return Future.value(_buildErrorForAnalysisErrors(
          constantEvaluationErrors, indexedAnnotation.element));
    }

    var libraryElement = indexedAnnotation.element.library;
    var libraryResult = await ResolvedLibraryResultImpl.tmp(libraryElement);
    if (libraryResult.state == ResultState.NOT_A_FILE) {
      // We don't have access to source information in summarized libraries,
      // but another build step will likely emit the root cause errors.
      return BuildError("Analysis errors in summarized library "
          "${libraryElement.source.fullName}");
    }

    var classResult =
        libraryResult.getElementDeclaration(indexedAnnotation.element);
    var classDeclaration = classResult.node as ClassDeclaration;
    var resolvedAnnotation =
        classDeclaration.metadata[indexedAnnotation.annotationIndex];

    // Only include the errors that are inside the annotation.
    return _buildErrorForAnalysisErrors(
        classResult.resolvedUnit.errors.where((error) =>
            error.offset >= resolvedAnnotation.offset &&
            error.offset <= resolvedAnnotation.end),
        indexedAnnotation.element);
  }

  BuildError _buildErrorForAnalysisErrors(
      Iterable<AnalysisError> errors, ClassElement componentType) {
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
        reason: ''
            'Compiling @Component-annotated class "${componentType.name}" '
            'failed.\n\n${messages.analysisFailureReasons}',
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
    if (index == -1)
      throw ArgumentError("[element] must have a @Component annotation");
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

class ErrorMessageForAnnotation extends AsyncBuildError {
  final IndexedAnnotation indexedAnnotation;
  final String message;

  ErrorMessageForAnnotation(this.indexedAnnotation, this.message);

  /// Find the ancestor node that should have the metadata.
  /// Angular only looks at metadata on class declarations and
  /// class members.
  static AnnotatedNode _ancestorWithMetadata(AstNode node) {
    ArgumentError.checkNotNull(node);
    return node is ClassMember || node is ClassDeclaration
        ? node as AnnotatedNode
        : _ancestorWithMetadata(node.parent);
  }

  @override
  Future<BuildError> resolve() async {
    final element = indexedAnnotation.element;
    final annotationIndex = indexedAnnotation.annotationIndex;

    var libraryResult = await ResolvedLibraryResultImpl.tmp(element.library);
    var result = libraryResult.getElementDeclaration(element);
    AnnotatedNode annotatedNode = _ancestorWithMetadata(result.node);

    ElementAnnotation resolvedAnnotation =
        annotatedNode.metadata[annotationIndex].elementAnnotation;
    return BuildError.forAnnotation(resolvedAnnotation, message);
  }
}

class ErrorMessageForElement extends AsyncBuildError {
  final Element element;
  final String message;

  ErrorMessageForElement(this.element, this.message);

  @override
  Future<BuildError> resolve() =>
      Future.value(BuildError.forElement(element, message));
}
