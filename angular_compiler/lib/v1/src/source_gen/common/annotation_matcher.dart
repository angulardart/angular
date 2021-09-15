import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/meta.dart';
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';

// See internal bug b/35319372 for details.

/// Wraps an annotation [matcher] so that an error is not thrown.
AnnotationMatcher safeMatcher(
  AnnotationMatcher matcher,
) =>
    (annotation) {
      try {
        return matcher(annotation);
      } on ArgumentError catch (e) {
        logWarning('Could not resolve $annotation: $e');
        return false;
      }
    };

/// Checks if an [ElementAnnotation] node implements [Component].
bool isComponent(ElementAnnotation annotation) =>
    matchAnnotation($Component, annotation);

/// Checks if an [ElementAnnotation] node implements [Directive].
bool isDirective(ElementAnnotation annotation) =>
    isComponent(annotation) || matchAnnotation($Directive, annotation);

/// Checks if an [ElementAnnotation] node implements [Pipe].
bool isPipe(ElementAnnotation annotation) => matchAnnotation($Pipe, annotation);

/// Checks if an [ElementAnnotation] node is exactly the type specified by
/// [url].
///
/// The url is of the form `package:full.package.name/source/path.dart#Symbol`.
///
/// It will attempt to compute the constant value of the annotation in case the
/// annotation was declared in a file other than the one currently being
/// compiled.
///
/// If a [logger] is provided, a warning is output if it fails to resolve the
/// annotation, otherwise an [ArgumentError] is thrown.
bool matchAnnotation(TypeChecker typeChecker, ElementAnnotation annotation) {
  final object = annotation.computeConstantValue();
  // TODO(b/123715184) Surface the constantEvaluationErrors.
  try {
    return typeChecker.isExactlyType(object!.type!);
  } catch (_) {
    var message = ''
        'Could not determine type of annotation. It resolved to '
        '${annotation.computeConstantValue()}. '
        'Are you missing a dependency?';
    if (annotation is ElementAnnotationImpl) {
      message += ''
          '\n'
          '${annotation.annotationAst.toSource()} in '
          '${annotation.librarySource.uri.toString()}';
    }
    throw ArgumentError.value(
      annotation,
      'annotation',
      message,
    );
  }
}

/// Checks if an [ElementAnnotation] node matches specific [Type]s.
typedef AnnotationMatcher = bool Function(ElementAnnotation annotation);
