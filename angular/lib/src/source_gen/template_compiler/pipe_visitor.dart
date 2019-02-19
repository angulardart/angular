import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/compiler/output/convert.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';
import 'package:angular_compiler/cli.dart';

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
    final annotation = element.metadata.firstWhere(isPipe, orElse: () => null);
    if (annotation == null) return null;
    if (element.isPrivate) {
      BuildError.throwForElement(element, 'Pipes must be public');
    }
    return _createPipeMetadata(annotation, element);
  }

  CompilePipeMetadata _createPipeMetadata(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    FunctionType transformType;
    final transformMethod = element.type.lookUpInheritedMethod('transform');
    if (transformMethod != null) {
      // The pipe defines a 'transform' method.
      transformType = transformMethod.type;
    } else {
      // The pipe may define a function-typed 'transform' property. This is
      // supported for backwards compatibility.
      final transformGetter = element.type.lookUpInheritedGetter('transform');
      final transformGetterType = transformGetter?.returnType;
      if (transformGetterType is FunctionType) {
        transformType = transformGetterType;
      }
    }
    if (transformType == null) {
      BuildError.throwForElement(
          element, 'Pipes must implement a "transform" method');
    }
    final value = annotation.computeConstantValue();
    return CompilePipeMetadata(
      type: element
          .accept(CompileTypeMetadataVisitor(_library, _exceptionHandler)),
      transformType: fromFunctionType(transformType),
      name: coerceString(value, 'name'),
      pure: coerceBool(value, 'pure', defaultTo: true),
      lifecycleHooks: extractLifecycleHooks(element),
    );
  }
}
