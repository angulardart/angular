import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';
import 'package:angular_compiler/cli.dart';
import 'package:source_gen/source_gen.dart';

import '../../compiler/output/convert.dart';
import 'compile_metadata.dart';
import 'dart_object_utils.dart';
import 'find_components.dart';

class PipeVisitor extends RecursiveElementVisitor<CompilePipeMetadata> {
  final LibraryReader _library;

  PipeVisitor(this._library);

  @override
  CompilePipeMetadata visitClassElement(ClassElement element) {
    final annotation = element.metadata.firstWhere(isPipe, orElse: () => null);
    if (annotation == null) return null;
    if (element.isPrivate) {
      throwFailure('Pipes must be public: $element');
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
      throwFailure("Pipe has no 'transform' method: $element");
    }
    final value = annotation.computeConstantValue();
    return new CompilePipeMetadata(
      type: element.accept(new CompileTypeMetadataVisitor(_library)),
      transformType: fromFunctionType(transformType),
      name: coerceString(value, 'name'),
      pure: coerceBool(value, 'pure', defaultTo: true),
      lifecycleHooks: extractLifecycleHooks(element),
    );
  }
}
