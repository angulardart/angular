import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:angular2/src/compiler/compile_metadata.dart';
import 'package:angular2/src/core/metadata.dart';
import 'package:angular2/src/source_gen/common/annotation_matcher.dart'
    as annotation_matcher;
import 'package:angular2/src/source_gen/common/annotation_model.dart';
import 'package:angular2/src/source_gen/common/namespace_model.dart';
import 'package:angular2/src/source_gen/common/ng_deps_model.dart';
import 'package:angular2/src/source_gen/common/parameter_model.dart';
import 'package:angular2/src/source_gen/common/reflection_info_model.dart';
import 'package:angular2/src/source_gen/template_compiler/compile_type.dart';
import 'package:angular2/src/transform/common/names.dart';
import 'package:build/build.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

/// Create an [NgDepsModel] for the [LibraryElement] supplied.
Future<NgDepsModel> extractNgDepsModel(
    LibraryElement element, BuildStep buildStep) async {
  var reflectableVisitor = new ReflectableVisitor(buildStep);
  element.accept(reflectableVisitor);
  var namespaceVisitor = new NameSpaceVisitor(buildStep);
  element.accept(namespaceVisitor);
  return new NgDepsModel(
      reflectables: reflectableVisitor.reflectables,
      imports: namespaceVisitor.imports,
      exports: namespaceVisitor.exports,
      depImports: await namespaceVisitor.depImports);
}

class NameSpaceVisitor extends RecursiveElementVisitor {
  final BuildStep _buildStep;
  List<ImportModel> imports = [];
  List<ExportModel> exports = [];

  NameSpaceVisitor(this._buildStep);

  @override
  void visitImportElement(ImportElement element) {
    if (element.uri != null) {
      imports.add(new ImportModel.fromElement(element));
    }
  }

  @override
  void visitExportElement(ExportElement element) {
    if (element.uri != null) {
      exports.add(new ExportModel.fromElement(element));
    }
  }

  Future<List<ImportModel>> get depImports async {
    var deps = <ImportModel>[];
    for (var import in imports) {
      var templateAsset = _assetId(import).changeExtension(TEMPLATE_EXTENSION);
      if (await _buildStep.hasInput(templateAsset)) {
        deps.add(new ImportModel(
            uri: import.uri.replaceFirst('\.dart', TEMPLATE_EXTENSION)));
      }
    }
    return deps;
  }

  AssetId _assetId(ImportModel import) {
    var uri = Uri.parse(import.uri);
    if (uri.isAbsolute) {
      return _assetIdfromUri(uri);
    } else {
      var inputId = _buildStep.input.id;
      var templatePath = path.join(path.dirname(inputId.path), uri.path);
      return new AssetId(inputId.package, templatePath);
    }
  }

  /// Parse an [AssetId] from a [Uri].
  ///
  /// The [uri] argument must:
  /// - Be either a `package:` or `asset:` Uri.
  /// - Not be relative.
  /// - Use '/' as a separator
  // TODO(alorenzen): Merge into AssetId.
  AssetId _assetIdfromUri(Uri uri) {
    assert(uri.scheme == 'package' || uri.scheme == 'asset');
    var firstSlash = uri.path.indexOf('/');
    var package = uri.path.substring(0, firstSlash);
    var rawPath = uri.path.substring(firstSlash);
    var path = (uri.scheme == 'package') ? 'lib$rawPath' : rawPath.substring(1);
    return new AssetId(package, path);
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
