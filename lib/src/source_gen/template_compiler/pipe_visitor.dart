import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart';
import 'package:angular2/src/source_gen/template_compiler/async_element_visitor.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:angular2/src/source_gen/template_compiler/dart_object_utils.dart';
import 'package:build/build.dart';

class PipeVisitor extends AsyncRecursiveElementVisitor<CompilePipeMetadata> {
  final BuildStep _buildStep;
  final AnnotationMatcher _annotationMatcher;
  PipeVisitor(this._buildStep) : _annotationMatcher = new AnnotationMatcher();

  @override
  Future<CompilePipeMetadata> visitClassElement(ClassElement element) async {
    await super.visitClassElement(element);
    for (ElementAnnotation annotation in element.metadata) {
      if (_annotationMatcher.isPipe(annotation)) {
        var compilePipeMetadata =
            await _createPipeMetadata(annotation, element);
        return compilePipeMetadata;
      }
    }
    return null;
  }

  Future<CompilePipeMetadata> _createPipeMetadata(
      ElementAnnotation annotation, ClassElement element) async {
    var value = annotation.computeConstantValue();
    return new CompilePipeMetadata(
        type: getType(element, _buildStep.input.id),
        name: getString(value, 'name'),
        pure: getBool(value, 'pure', defaultValue: true),
        lifecycleHooks: []);
  }
}
