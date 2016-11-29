import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:source_gen/src/annotation.dart' as source_gen;

/// Checks if any of the [Element]'s metadata is an injectable component.
bool isInjectable(Element element) => element.metadata.any(_isInjectable);

/// Checks if an [ElementAnnotation] node implements [Component].
bool isComponent(ElementAnnotation annotation) =>
    matchAnnotation(Component, annotation);

/// Checks if an [ElementAnnotation] node implements [Directive].
bool isDirective(ElementAnnotation annotation) =>
    matchTypes([Component, Directive], annotation);

/// Checks if an [ElementAnnotation] node implements [Pipe].
bool isPipe(ElementAnnotation annotation) => matchAnnotation(Pipe, annotation);

bool matchTypes(Iterable<Type> types, ElementAnnotation annotation) =>
    types.any((type) => matchAnnotation(type, annotation));

/// Checks if an [ElementAnnotation] node implements the specified [Type].
///
/// It will attempt to compute the constant value of the annotation in case the
/// annotation was declared in a file other than the one currently being
/// compiled.
bool matchAnnotation(Type type, ElementAnnotation annotation) {
  annotation.computeConstantValue();
  return source_gen.matchAnnotation(type, annotation);
}

/// Checks if an [ElementAnnotation] node matches specific [Type]s.
typedef bool AnnotationMatcher(ElementAnnotation annotation);

bool _isInjectable(ElementAnnotation element) => matchTypes(const [
      Component,
      Directive,
      Pipe,
      Injectable,
    ], element);
