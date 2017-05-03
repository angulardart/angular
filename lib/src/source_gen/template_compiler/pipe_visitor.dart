import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart';
import 'package:logging/logging.dart';

import 'compile_metadata.dart';
import 'dart_object_utils.dart';
import 'find_components.dart';

class PipeVisitor extends RecursiveElementVisitor<CompilePipeMetadata> {
  final Logger _logger;

  PipeVisitor(this._logger);

  @override
  CompilePipeMetadata visitClassElement(ClassElement element) {
    for (ElementAnnotation annotation in element.metadata) {
      if (isPipe(annotation)) {
        return _createPipeMetadata(annotation, element);
      }
    }
    return null;
  }

  CompilePipeMetadata _createPipeMetadata(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    var value = annotation.computeConstantValue();
    return new CompilePipeMetadata(
      type: element.accept(new CompileTypeMetadataVisitor(_logger)),
      name: coerceString(value, 'name'),
      pure: coerceBool(value, '_pure', defaultTo: true),
      lifecycleHooks: extractLifecycleHooks(element),
    );
  }
}
