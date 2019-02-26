import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/output/convert.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';

import 'annotation_information.dart';
import 'compile_metadata.dart';
import 'component_visitor_exceptions.dart';
import 'dart_object_utils.dart';
import 'lifecycle_hooks.dart';

class PipeVisitor extends RecursiveElementVisitor<CompilePipeMetadata> {
  final LibraryReader _library;
  final ComponentVisitorExceptionHandler _exceptionHandler;

  PipeVisitor(this._library, this._exceptionHandler);

  @override
  CompilePipeMetadata visitClassElement(ClassElement element) {
    final annotationInfo = annotationWhere(element, isPipe, _exceptionHandler);

    if (annotationInfo == null) return null;
    if (annotationInfo.hasErrors) {
      _exceptionHandler.handle(AngularAnalysisError(
          annotationInfo.constantEvaluationErrors, annotationInfo));
      return null;
    }
    if (element.isPrivate) {
      _exceptionHandler
          .handle(ErrorMessageForElement(element, 'Pipes must be public'));
      return null;
    }

    return _createPipeMetadata(annotationInfo);
  }

  CompilePipeMetadata _createPipeMetadata(
    AnnotationInformation<ClassElement> annotation,
  ) {
    InterfaceType elementType = annotation.element.type;
    FunctionType transformType;
    final transformMethod = elementType.lookUpInheritedMethod('transform');
    if (transformMethod != null) {
      // The pipe defines a 'transform' method.
      transformType = transformMethod.type;
    } else {
      // The pipe may define a function-typed 'transform' property. This is
      // supported for backwards compatibility.
      final transformGetter = elementType.lookUpInheritedGetter('transform');
      final transformGetterType = transformGetter?.returnType;
      if (transformGetterType is FunctionType) {
        transformType = transformGetterType;
      }
    }
    if (transformType == null) {
      _exceptionHandler.handle(ErrorMessageForElement(
          annotation.element, 'Pipes must implement a "transform" method'));
      return null;
    }
    final value = annotation.constantValue;
    return CompilePipeMetadata(
      type: annotation.element.accept(
          CompileTypeMetadataVisitor(_library, _exceptionHandler, annotation)),
      transformType: fromFunctionType(transformType),
      name: coerceString(value, 'name'),
      pure: coerceBool(value, 'pure', defaultTo: true),
      lifecycleHooks: extractLifecycleHooks(annotation.element),
    );
  }
}
