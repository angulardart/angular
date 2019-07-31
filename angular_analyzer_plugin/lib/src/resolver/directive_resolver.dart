import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/resolver/element_view_impl.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/standard_components.dart';

/// Resolve which directives match which tags in a template.
///
/// Stores these bindings in the AST as [DirectiveBinding]s, and also checks
/// content children for directives within directives (and stores those
/// [ContentChildBinding]- on the [DirectiveBinding]s it makes).
class DirectiveResolver extends AngularAstVisitor {
  final TypeSystem _typeSystem;
  final List<DirectiveBase> allDirectives;
  final Source templateSource;
  final Template template;
  final AnalysisErrorListener errorListener;
  final ErrorReporter _errorReporter;
  final StandardAngular _standardAngular;
  final StandardHtml _standardHtml;
  final outerBindings = <DirectiveBinding>[];
  final outerElements = <ElementInfo>[];
  final Set<String> customTagNames;

  DirectiveResolver(
      this._typeSystem,
      this.allDirectives,
      this.templateSource,
      this.template,
      this._standardAngular,
      this._standardHtml,
      this._errorReporter,
      this.errorListener,
      this.customTagNames);

  @override
  void visitElementInfo(ElementInfo element) {
    outerElements.add(element);
    if (element.templateAttribute != null) {
      visitTemplateAttr(element.templateAttribute);
    }

    final elementView = ElementViewImpl(element.attributes, element: element);
    final unmatchedDirectives = <DirectiveBase>[];

    final containingDirectivesCount = outerBindings.length;
    for (final directive in allDirectives) {
      final match = directive.selector.match(elementView, template);
      if (match != SelectorMatch.NoMatch) {
        final binding = DirectiveBinding(directive);
        element.boundDirectives.add(binding);
        if (match == SelectorMatch.TagMatch) {
          element.tagMatchedAsDirective = true;
        }

        // optimization: only add the bindings that care about content child
        if (directive.contentChildFields.isNotEmpty ||
            directive.contentChildrenFields.isNotEmpty) {
          outerBindings.add(binding);
        }

        // Specifically exclude NgIf and NgFor, they have their own error since
        // we *know* they require a template.
        if (directive.looksLikeTemplate &&
            !element.isTemplate &&
            directive is Directive &&
            directive.classElement.name != "NgIf" &&
            directive.classElement.name != "NgFor") {
          _reportErrorForRange(
              element.openingSpan,
              AngularWarningCode.CUSTOM_DIRECTIVE_MAY_REQUIRE_TEMPLATE,
              [directive.classElement.name]);
        }
      } else {
        unmatchedDirectives.add(directive);
      }
    }

    for (final directive in unmatchedDirectives) {
      if (directive is DirectiveBase &&
          directive.selector.availableTo(elementView) &&
          !directive.looksLikeTemplate) {
        element.availableDirectives[directive] =
            directive.selector.getAttributes(elementView);
      }
    }

    element.tagMatchedAsCustomTag = customTagNames.contains(element.localName);

    if (!element.isTemplate) {
      _checkNoStructuralDirectives(element.attributes);
    }

    _recordContentChildren(element);

    for (final child in element.childNodes) {
      child.accept(this);
    }

    for (final binding in element.boundDirectives
        .expand((binding) => binding.contentChildBindings.values)
        .where((binding) => binding.boundElements.length > 1)) {
      for (final element in binding.boundElements) {
        _errorReporter.reportErrorForOffset(
            AngularWarningCode.SINGULAR_CHILD_QUERY_MATCHED_MULTIPLE_TIMES,
            element.offset,
            element.length, [
          (binding.directive as Directive).classElement.name,
          binding.boundContentChild.fieldName
        ]);
      }
    }

    outerBindings.removeRange(containingDirectivesCount, outerBindings.length);
    outerElements.removeLast();
  }

  @override
  void visitTemplateAttr(TemplateAttribute attr) {
    final elementView =
        ElementViewImpl(attr.virtualAttributes, elementName: 'template');
    for (final directive in allDirectives) {
      if (directive.selector.match(elementView, template) !=
          SelectorMatch.NoMatch) {
        attr.boundDirectives.add(DirectiveBinding(directive));
      }
    }

    final templateAttrIsUsed =
        attr.directives.any((directive) => directive.looksLikeTemplate);

    if (!templateAttrIsUsed) {
      _reportErrorForRange(
          SourceRange(attr.originalNameOffset, attr.originalName.length),
          AngularWarningCode.TEMPLATE_ATTR_NOT_USED);
    }
  }

  void _checkNoStructuralDirectives(List<AttributeInfo> attributes) {
    for (final attribute in attributes) {
      if (attribute is! TextAttribute) {
        continue;
      }

      if (attribute.name == 'ngFor' || attribute.name == 'ngIf') {
        _reportErrorForRange(
            SourceRange(attribute.nameOffset, attribute.name.length),
            AngularWarningCode.STRUCTURAL_DIRECTIVES_REQUIRE_TEMPLATE,
            [attribute.name]);
      }
    }
  }

  void _reportErrorForRange(SourceRange range, ErrorCode errorCode,
      [List<Object> arguments]) {
    errorListener.onError(AnalysisError(
        templateSource, range.offset, range.length, errorCode, arguments));
  }

  void _recordContentChildren(ElementInfo element) {
    for (final binding in outerBindings) {
      for (var contentChild in binding.boundDirective.contentChildFields) {
        _matchContentChild(element, binding.boundDirective, contentChild,
            binding.contentChildBindings,
            immediateChild: element.parent.boundDirectives.contains(binding));
      }

      for (var contentChildren
          in binding.boundDirective.contentChildrenFields) {
        _matchContentChild(element, binding.boundDirective, contentChildren,
            binding.contentChildrenBindings,
            immediateChild: element.parent.boundDirectives.contains(binding));
      }
    }
  }

  void _matchContentChild(
      ElementInfo element,
      Directive boundDirective,
      ContentChild contentChild,
      Map<ContentChild, ContentChildBinding> contentChildBindings,
      {@required bool immediateChild}) {
    // an already matched ContentChild shouldn't look inside that match
    if (contentChildBindings[contentChild]
            ?.boundElements
            ?.any(outerElements.contains) ??
        false) {
      return;
    }

    if (contentChild.query.accept(_MatchContentChildQueryVisitor(_typeSystem,
        element, _standardAngular, _standardHtml, _errorReporter))) {
      contentChildBindings.putIfAbsent(contentChild,
          () => ContentChildBinding(boundDirective, contentChild));

      contentChildBindings[contentChild].boundElements.add(element);

      if (immediateChild) {
        element.tagMatchedAsImmediateContentChild = true;
      }
    }
  }
}

/// A visitor for content child queries that checks if a query matches a tag.
class _MatchContentChildQueryVisitor implements QueriedChildTypeVisitor<bool> {
  final TypeSystem typeSystem;
  final NodeInfo element;
  final StandardAngular standardAngular;
  final StandardHtml standardHtml;
  final ErrorReporter errorReporter;

  _MatchContentChildQueryVisitor(this.typeSystem, this.element,
      this.standardAngular, this.standardHtml, this.errorReporter);

  @override
  bool visitDirectiveQueriedChildType(DirectiveQueriedChildType query) =>
      _whenElementInfo((elementInfo) => elementInfo.directives
          .any((boundDirective) => boundDirective == query.directive));

  @override
  bool visitElementQueriedChildType(ElementQueriedChildType query) =>
      _whenElementInfo((elementInfo) =>
          elementInfo.localName != 'template' &&
          !elementInfo.directives.any((boundDirective) =>
              boundDirective is Component && !boundDirective.isHtml));

  @override
  bool visitLetBoundQueriedChildType(LetBoundQueriedChildType query) =>
      _whenElementInfo((elementInfo) => elementInfo.attributes.any((attribute) {
            if (attribute is TextAttribute &&
                attribute.name == '#${query.letBoundName}') {
              _validateLetBoundMatch(elementInfo, attribute, query);
              return true;
            }
            return false;
          }));

  @override
  bool visitTemplateRefQueriedChildType(TemplateRefQueriedChildType query) =>
      _whenElementInfo((elementInfo) => elementInfo.localName == 'template');

  /// Validate against a matching [TextAttribute] on a matching [ElementInfo],
  /// for assignability to [containerType] errors.
  void _validateLetBoundMatch(
      ElementInfo element, TextAttribute attr, LetBoundQueriedChildType query) {
    // For Html, the possible match types is plural. So use a list in all cases
    // instead of a single value for most and then have some exceptional code.
    final matchTypes = <DartType>[];

    if (attr.value != "" && attr.value != null) {
      final possibleDirectives = List<Directive>.from(element.directives.where(
          (d) =>
              d.exportAs.string == attr.value &&
              d is Directive)); // No [FunctionalDirective]s/not [DirectiveBase]
      if (possibleDirectives.isEmpty || possibleDirectives.length > 1) {
        // Don't validate based on an invalid state (that's reported as such).
        return;
      }
      // TODO instantiate this type to bounds
      matchTypes.add(possibleDirectives.first.classElement.type);
    } else if (element.localName == 'template') {
      matchTypes.add(standardAngular.templateRef.type);
    } else {
      final possibleComponents = List<Component>.from(
          element.directives.where((d) => d is Component && !d.isHtml));
      if (possibleComponents.length > 1) {
        // Don't validate based on an invalid state (that's reported as such).
        return;
      }

      if (possibleComponents.isEmpty) {
        // TODO differentiate between SVG (Element) and HTML (HtmlElement)
        matchTypes
          ..add(standardAngular.elementRef.type)
          ..add(standardHtml.elementClass.type)
          ..add(standardHtml.htmlElementClass.type);
      } else {
        // TODO instantiate this type to bounds
        matchTypes.add(possibleComponents.first.classElement.type);
      }
    }

    // Don't do isAssignable. Because we KNOW downcasting makes no sense here.
    if (!matchTypes
        .any((t) => typeSystem.isSubtypeOf(t, query.containerType))) {
      errorReporter.reportErrorForOffset(
          AngularWarningCode.MATCHED_LET_BINDING_HAS_WRONG_TYPE,
          element.offset,
          element.length,
          [query.letBoundName, query.containerType, matchTypes]);
    }
  }

  bool _whenElementInfo(bool Function(ElementInfo) fn) {
    if (element is ElementInfo) {
      return fn(element as ElementInfo);
    }
    return false;
  }
}
