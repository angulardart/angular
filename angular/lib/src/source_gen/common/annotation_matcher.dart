import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:angular_compiler/cli.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/core/metadata.dart';

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

/// Creates a matcher that checks for [type], warning if an error is thrown.
AnnotationMatcher safeMatcherType(
  Type type,
) =>
    safeMatcher(
      (annotation) => matchAnnotation(type, annotation),
    );

/// Creates a matcher that checks for [types], warning if an error is thrown.
AnnotationMatcher safeMatcherTypes(Iterable<Type> types) => safeMatcher(
      (annotation) => _matchTypes(types, annotation),
    );

/// Checks if an [ElementAnnotation] node implements [Component].
bool isComponent(ElementAnnotation annotation) =>
    matchAnnotation(Component, annotation);

/// Checks if an [ElementAnnotation] node implements [Directive].
bool isDirective(ElementAnnotation annotation) =>
    _matchTypes([Component, Directive], annotation);

/// Checks if an [ElementAnnotation] node implements [Pipe].
bool isPipe(ElementAnnotation annotation) => matchAnnotation(Pipe, annotation);

bool _matchTypes(Iterable<Type> types, ElementAnnotation annotation) =>
    types.any((type) => matchAnnotation(type, annotation));

/// Checks if an [ElementAnnotation] node is exactly the specified [Type].
///
/// It will attempt to compute the constant value of the annotation in case the
/// annotation was declared in a file other than the one currently being
/// compiled.
///
/// If a [logger] is provided, a warning is output if it fails to resolve the
/// annotation, otherwise an [ArgumentError] is thrown.
bool matchAnnotation(Type type, ElementAnnotation annotation) {
  annotation.computeConstantValue();
  try {
    final checker = TypeChecker.fromRuntime(type);
    final objectType = annotation.constantValue.type;
    return checker.isExactlyType(objectType);
  } catch (_) {
    String message = ''
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
typedef bool AnnotationMatcher(ElementAnnotation annotation);
