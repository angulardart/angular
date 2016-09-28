import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:source_gen/src/annotation.dart' as source_gen;

class AnnotationMatcher {
  bool isComponent(ElementAnnotation annotation) =>
      matchAnnotation(Component, annotation);

  bool isDirective(ElementAnnotation annotation) =>
      matchAnnotation(Directive, annotation);

  /// Checks if an [Annotation] node implements [Pipe].
  bool isPipe(ElementAnnotation annotation) =>
      matchAnnotation(Pipe, annotation);

  bool matchAnnotation(Type type, ElementAnnotation annotation) {
    annotation.computeConstantValue();
    return source_gen.matchAnnotation(type, annotation);
  }
}
