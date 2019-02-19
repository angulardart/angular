import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:angular/src/core/metadata.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';

import 'component_visitor_exceptions.dart';

/// Manages an annotation giving sane error handling behaviour.
///
/// Users who want to ignore errors, skipping bad annotations, will call the is*
/// getters directly. This class will issue one warning to the exception\
/// handler.
///
/// Users who want to fail on bad annotations can check [hasErrors] and then
/// report errors directly to their exception handlers. In this case, this class
/// will not issue warnings to the exception handler.
class AnnotationInformation<T extends Element> extends IndexedAnnotation<T> {
  final ComponentVisitorExceptionHandler _exceptionHandler;
  final DartObject constantValue;
  final List<AnalysisError> constantEvaluationErrors;

  AnnotationInformation(T element, ElementAnnotation annotation,
      int annotationIndex, this._exceptionHandler)
      : constantValue = annotation.computeConstantValue(),
        constantEvaluationErrors = annotation.constantEvaluationErrors,
        super(element, annotation, annotationIndex);

  bool get isInputType => _isTypeExactly(Input);
  bool get isOutputType => _isTypeExactly(Output);
  bool get isContentType =>
      _isTypeExactly(ContentChild) || _isTypeExactly(ContentChildren);
  bool get isViewType =>
      _isTypeExactly(ViewChild) || _isTypeExactly(ViewChildren);
  bool get isComponent => _isTypeExactly(Component);

  bool get hasErrors =>
      constantValue == null || constantEvaluationErrors.isNotEmpty;

  bool sentWarning = false;

  bool _isTypeExactly(Type type) {
    if (hasErrors) {
      if (!sentWarning) {
        // NOTE: Upcast to satisfy Dart's type system.
        // See https://github.com/dart-lang/sdk/issues/33932
        final IndexedAnnotation annotation = this;
        _exceptionHandler.handleWarning(
            AngularAnalysisError(constantEvaluationErrors, annotation));
        sentWarning = true;
      }
      return false;
    }
    return matchTypeExactly(type, constantValue);
  }
}

/// Returns the [AnnotationInformation] for the first annotation on [element]
/// that matches [test] or null if no such annotation exists.
AnnotationInformation<T> annotationWhere<T extends Element>(
    T element,
    bool test(ElementAnnotation element),
    ComponentVisitorExceptionHandler exceptionHandler) {
  for (var annotationIndex = 0;
      annotationIndex < element.metadata.length;
      annotationIndex++) {
    final annotation = element.metadata[annotationIndex];

    final annotationInfo = AnnotationInformation(
        element, annotation, annotationIndex, exceptionHandler);

    if (annotationInfo.constantValue == null) {
      exceptionHandler.handleWarning(AngularAnalysisError(
          annotationInfo.constantEvaluationErrors, annotationInfo));
    } else if (test(annotationInfo.annotation)) {
      return annotationInfo;
    }
  }
  return null;
}
