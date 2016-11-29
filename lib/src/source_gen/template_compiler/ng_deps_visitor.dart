import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';

/// An [ElementVisitor] which creates an [NgDepsModel] for the [LibraryElement]
/// supplied.
class NgDepsVisitor extends SimpleElementVisitor<NgDepsModel> {
  final BuildStep _buildStep;

  NgDepsVisitor(this._buildStep);

  @override
  NgDepsModel visitLibraryElement(LibraryElement element) {
    var reflectableVisitor = new ReflectableVisitor(_buildStep);
    element.accept(reflectableVisitor);
    return new NgDepsModel(reflectables: reflectableVisitor.reflectables,
        // TODO(alorenzen): Implement.
        depImports: [], imports: [], exports: []);
  }
}

/// An [ElementVisitor] which extracts all [ReflectableInfoModel]s found in the
/// given element or its children.
class ReflectableVisitor extends RecursiveElementVisitor {
  final BuildStep _buildStep;
  List<ReflectionInfoModel> _reflectables = [];

  ReflectableVisitor(this._buildStep);

  Logger get _logger => _buildStep.logger;

  List<ReflectionInfoModel> get reflectables =>
      _reflectables.where((model) => model != null).toList();

  @override
  void visitClassElement(ClassElement element) {
    CompileTypeMetadata compileType =
        element.accept(new CompileTypeMetadataVisitor(_buildStep));
    if (compileType == null) return;
    var constructor = _constructor(element);
    if (constructor == null) return;
    _reflectables.add(new ReflectionInfoModel(
        isFunction: false,
        name: compileType.name,
        ctorName: constructor.name,
        parameters: _parameters(constructor),
        annotations: _annotations(element.metadata),
        interfaces: _interfaces(element)));
  }

  /// Finds the unnamed constructor if it is present.
  ///
  /// Otherwise, use the first encountered.
  ConstructorElement _constructor(ClassElement element) {
    var constructors = element.constructors;
    if (constructors.isEmpty) {
      _logger.severe('Invalid @Injectable() annotation: '
          'No constructors found for class ${element.name}.');
      return null;
    }

    var constructor = constructors.firstWhere(
        (constructor) => constructor.name == null,
        orElse: () => constructors.first);

    if (constructor.isPrivate) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Cannot use private constructor on class ${element.name}');
      return null;
    }
    if (element.isAbstract && !constructor.isFactory) {
      _logger.severe('Invalid @Injectable() annotation: '
          'Found a constructor for abstract class ${element.name} but it is '
          'not a "factory", and cannot be invoked');
      return null;
    }
    if (element.constructors.length > 1 && constructor.name != null) {
      _logger.warning(
          'Found ${element.constructors.length} constructors for class '
          '${element.name}; using constructor ${constructor.name}.');
    }
    return constructor;
  }

  List<ParameterModel> _parameters(ConstructorElement constructor) =>
      constructor.parameters
          .map((parameter) => new ParameterModel.fromElement(parameter))
          .toList();

  // TODO(alorenzen): Verify that this works for interfaces of superclasses.
  List<String> _interfaces(ClassElement element) =>
      element.interfaces.map((interface) => interface.name).toList();

  List<AnnotationModel> _annotations(List<ElementAnnotation> metadata) =>
      metadata
          .where((annotation) => !annotation_matcher
              .matchTypes([Component, View, Directive], annotation))
          .map((annotation) => new AnnotationModel.fromElement(annotation))
          .toList();
}
