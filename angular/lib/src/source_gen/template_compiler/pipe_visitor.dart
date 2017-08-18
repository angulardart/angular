import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:logging/logging.dart';
import 'package:angular/src/compiler/compile_metadata.dart';
import 'package:angular/src/source_gen/common/annotation_matcher.dart';

import 'compile_metadata.dart';
import 'dart_object_utils.dart';
import 'find_components.dart';

class PipeVisitor extends RecursiveElementVisitor<CompilePipeMetadata> {
  final Logger _logger;

  PipeVisitor(this._logger);

  @override
  CompilePipeMetadata visitClassElement(ClassElement element) {
    final annotation = element.metadata.firstWhere(isPipe, orElse: () => null);
    if (annotation == null) return null;
    if (element.isPrivate) {
      _logger.severe('Pipes must be public: $element');
      return null;
    }
    return _createPipeMetadata(annotation, element);
  }

  CompilePipeMetadata _createPipeMetadata(
    ElementAnnotation annotation,
    ClassElement element,
  ) {
    var value = annotation.computeConstantValue();
    return new CompilePipeMetadata(
      type: element.accept(new CompileTypeMetadataVisitor(_logger)),
      name: coerceString(value, 'name'),
      pure: coerceBool(value, 'pure', defaultTo: true),
      lifecycleHooks: extractLifecycleHooks(element),
    );
  }
}
