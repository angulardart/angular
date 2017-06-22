import 'package:analyzer/dart/ast/ast.dart';
import 'package:barback/barback.dart' show AssetId;

import 'class_matcher_base.dart';

export 'class_matcher_base.dart' show ClassDescriptor;

/// [ClassDescriptor]s for the default angular annotations that can appear
/// on a class. These classes are re-exported in many places so this covers all
/// the possible libraries which could provide them.
const _INJECTABLES = const [
  const ClassDescriptor(
      'Injectable', 'package:angular/src/core/di/decorators.dart'),
  const ClassDescriptor('Injectable', 'package:angular/core.dart'),
  const ClassDescriptor('Injectable', 'package:angular/src/core/di.dart'),
  const ClassDescriptor('Injectable', 'package:angular/angular.dart'),
  const ClassDescriptor('Injectable', 'package:angular/di.dart'),
  const ClassDescriptor('Injectable', 'package:angular/web_worker/worker.dart'),
];

const _DIRECTIVES = const [
  const ClassDescriptor(
      'Directive', 'package:angular/src/core/metadata/directive.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Directive', 'package:angular/src/core/metadata.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Directive', 'package:angular/angular.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Directive', 'package:angular/di.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Directive', 'package:angular/core.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Directive', 'package:angular/web_worker/worker.dart',
      superClass: 'Injectable'),
];

const _COMPONENTS = const [
  const ClassDescriptor(
      'Component', 'package:angular/src/core/metadata/directive.dart',
      superClass: 'Directive'),
  const ClassDescriptor('Component', 'package:angular/src/core/metadata.dart',
      superClass: 'Directive'),
  const ClassDescriptor('Component', 'package:angular/angular.dart',
      superClass: 'Directive'),
  const ClassDescriptor('Component', 'package:angular/core.dart',
      superClass: 'Directive'),
  const ClassDescriptor('Component', 'package:angular/web_worker/worker.dart',
      superClass: 'Directive'),
];

const _PIPES = const [
  const ClassDescriptor(
      'Pipe', 'package:angular/src/core/metadata/directive.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Pipe', 'package:angular/src/core/metadata.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Pipe', 'package:angular/angular.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Pipe', 'package:angular/di.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Pipe', 'package:angular/core.dart',
      superClass: 'Injectable'),
  const ClassDescriptor('Pipe', 'package:angular/web_worker/worker.dart',
      superClass: 'Injectable'),
];

const _VIEWS = const [
  const ClassDescriptor('View', 'package:angular/angular.dart'),
  const ClassDescriptor('View', 'package:angular/di.dart'),
  const ClassDescriptor('View', 'package:angular/web_worker/worker.dart'),
  const ClassDescriptor('View', 'package:angular/core.dart'),
  const ClassDescriptor('View', 'package:angular/src/core/metadata/view.dart'),
  const ClassDescriptor('View', 'package:angular/src/core/metadata.dart'),
];

const _ENTRYPOINTS = const [
  const ClassDescriptor('AngularEntrypoint', 'package:angular/angular.dart'),
  const ClassDescriptor('AngularEntrypoint', 'package:angular/di.dart'),
  const ClassDescriptor('AngularEntrypoint', 'package:angular/core.dart'),
  const ClassDescriptor(
      'AngularEntrypoint', 'package:angular/platform/browser.dart'),
  const ClassDescriptor(
      'AngularEntrypoint', 'package:angular/platform/worker_app.dart'),
  const ClassDescriptor(
      'AngularEntrypoint', 'package:angular/platform/browser_static.dart'),
  const ClassDescriptor(
      'AngularEntrypoint', 'package:angular/src/core/angular_entrypoint.dart'),
];

const _INJECTOR_MODULES = const [
  const ClassDescriptor(
      'InjectorModule', 'package:angular/src/core/metadata.dart'),
  const ClassDescriptor('InjectorModule', 'package:angular/angular.dart'),
  const ClassDescriptor('InjectorModule', 'package:angular/di.dart'),
  const ClassDescriptor('InjectorModule', 'package:angular/core.dart'),
  const ClassDescriptor(
      'InjectorModule', 'package:angular/web_worker/worker.dart'),
];

/// Checks if a given [Annotation] matches any of the given
/// [ClassDescriptors].
class AnnotationMatcher extends ClassMatcherBase {
  AnnotationMatcher._(List<ClassDescriptor> classDescriptors)
      : super(classDescriptors);

  factory AnnotationMatcher() {
    return new AnnotationMatcher._([]
      ..addAll(_COMPONENTS)
      ..addAll(_DIRECTIVES)
      ..addAll(_PIPES)
      ..addAll(_INJECTABLES)
      ..addAll(_VIEWS)
      ..addAll(_ENTRYPOINTS)
      ..addAll(_INJECTOR_MODULES));
  }

  bool _implementsWithWarning(Annotation annotation, AssetId assetId,
      List<ClassDescriptor> interfaces) {
    ClassDescriptor descriptor = firstMatch(annotation.name, assetId);
    if (descriptor == null) return false;
    return implements(descriptor, interfaces,
        missingSuperClassWarning:
            'Missing `custom_annotation` entry for `${descriptor.superClass}`.');
  }

  /// Checks if an [Annotation] node implements [Injectable].
  bool isInjectable(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _INJECTABLES);

  /// Checks if an [Annotation] node implements [Directive].
  bool isDirective(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _DIRECTIVES);

  /// Checks if an [Annotation] node implements [Component].
  bool isComponent(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _COMPONENTS);

  /// Checks if an [Annotation] node implements [View].
  bool isView(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _VIEWS);

  /// Checks if an [Annotation] node implements [Pipe].
  bool isPipe(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _PIPES);

  /// Checks if an [Annotation] node implements [AngularEntrypoint]
  bool isEntrypoint(Annotation annotation, AssetId assetId) =>
      _implementsWithWarning(annotation, assetId, _ENTRYPOINTS);
}
