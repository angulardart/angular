import 'package:analyzer/dart/element/element.dart' as engine;
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' as protocol;
import 'package:analyzer_plugin/protocol/protocol_constants.dart' as protocol;
import 'package:analyzer_plugin/utilities/analyzer_converter.dart' as protocol;
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/navigation_request.dart';

/// Collect navigation info from a template for the IDE.
class AngularNavigation implements NavigationContributor {
  final FileContentOverlay _contentOverlay;

  AngularNavigation(this._contentOverlay);

  @override
  void computeNavigation(
      NavigationRequest baseRequest, NavigationCollector collector,
      {bool templatesOnly = false}) {
    // cast this
    final request = baseRequest as AngularNavigationRequest;
    final length = request.length;
    final offset = request.offset;
    final result = request.result;

    if (result == null) {
      return;
    }

    final span =
        offset != null && length != null ? SourceRange(offset, length) : null;
    final directives = result.directives;
    final components = directives.whereType<Component>();

    if (!templatesOnly) {
      // special dart navigable regions
      for (final directive in directives) {
        _addDirectiveRegions(collector, directive, span);
      }
      for (final component in components) {
        _addComponentRegions(collector, component, span);
      }
    }

    final resolvedTemplates = result.fullyResolvedDirectives
        .map((d) => d is Component ? d.template : null)
        .where((v) => v != null);
    for (final template in resolvedTemplates) {
      _addTemplateRegions(collector, template, span);
    }
  }

  /// Check if a source range is currently targeted.
  ///
  /// A null [targetRange] indicates everything is targeted. Otherwise,
  /// intersect [toTest] with [targetRange].
  bool isTargeted(SourceRange toTest, {SourceRange targetRange}) =>
      // <a><b></b></a> or <a><b></a></b>, but not <a></a><b></b>.
      targetRange == null || targetRange.intersects(toTest);

  void _addComponentRegions(NavigationCollector collector, Component component,
      SourceRange targetRange) {
    if (component.templateUrlSource != null &&
        isTargeted(component.templateUrlRange, targetRange: targetRange)) {
      collector.addRegion(
          component.templateUrlRange.offset,
          component.templateUrlRange.length,
          protocol.ElementKind.UNKNOWN,
          protocol.Location(component.templateUrlSource.fullName, 0, 0, 1, 1));
    }
  }

  void _addDirectiveRegions(NavigationCollector collector,
      DirectiveBase directive, SourceRange targetRange) {
    for (final input in directive.inputs) {
      if (!isTargeted(input.setterRange, targetRange: targetRange)) {
        continue;
      }
      final setter = input.setter;
      if (setter == null) {
        continue;
      }

      final compilationElement =
          setter.getAncestor((e) => e is engine.CompilationUnitElement);
      final lineInfo =
          (compilationElement as engine.CompilationUnitElement).lineInfo;

      final offsetLineLocation = lineInfo.getLocation(setter.nameOffset);
      collector.addRegion(
          input.setterRange?.offset,
          input.setterRange?.length,
          protocol.AnalyzerConverter().convertElementKind(setter.kind),
          protocol.Location(
              setter.source.fullName,
              setter.nameOffset,
              setter.nameLength,
              offsetLineLocation.lineNumber,
              offsetLineLocation.columnNumber));
    }
  }

  void _addTemplateRegions(NavigationCollector collector, Template template,
      SourceRange targetRange) {
    for (final resolvedRange in template.ranges) {
      if (!isTargeted(resolvedRange.range, targetRange: targetRange)) {
        continue;
      }

      final offset = resolvedRange.range.offset;
      final element = resolvedRange.navigable;

      if (element.navigationRange?.offset == null) {
        continue;
      }

      final lineInfo =
          LineInfo.fromContent(_contentOverlay[element.source.fullName] ?? "");

      if (lineInfo == null) {
        continue;
      }

      final offsetLineLocation =
          lineInfo.getLocation(element.navigationRange.offset);
      collector.addRegion(
          offset,
          resolvedRange.range.length,
          protocol.ElementKind.UNKNOWN,
          protocol.Location(
              element.source.fullName,
              element.navigationRange.offset,
              element.navigationRange.length,
              offsetLineLocation.lineNumber,
              offsetLineLocation.columnNumber));
    }
  }
}
