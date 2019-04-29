import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:meta/meta.dart';
import 'package:angular_analyzer_plugin/ast.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/resolver/element_view_impl.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// Visitor to check and report un-transcluded content.
///
/// This requires previously having resolved the directives, and their content
/// children.
///
/// Also reports unknown tag errors because only after checking component
/// transclusions have we seen all the ways that a tag can be matched.
class ComponentContentResolver extends AngularAstVisitor {
  final Source templateSource;
  final Template template;
  final AnalysisErrorListener errorListener;

  ComponentContentResolver(
      this.templateSource, this.template, this.errorListener);

  void checkTransclusionsContentChildren(
      Component component, List<NodeInfo> children,
      {@required bool tagIsStandard}) {
    if (component?.ngContents == null) {
      return;
    }

    final acceptAll = component.ngContents.any((s) => s.matchesAll);
    for (final child in children) {
      if (child is TextInfo && !acceptAll && child.text.trim() != "") {
        _reportErrorForRange(SourceRange(child.offset, child.length),
            AngularWarningCode.CONTENT_NOT_TRANSCLUDED);
      } else if (child is ElementInfo) {
        final view = ElementViewImpl(child.attributes, element: child);

        var matched = acceptAll;
        var matchedTag = false;

        for (final ngContent in component.ngContents) {
          final match = ngContent.matchesAll
              ? SelectorMatch.NonTagMatch
              : ngContent.selector.match(view, template);
          if (match != SelectorMatch.NoMatch) {
            matched = true;
            matchedTag = matchedTag || match == SelectorMatch.TagMatch;
          }
        }

        matched = matched || child.tagMatchedAsImmediateContentChild;

        if (!matched) {
          _reportErrorForRange(SourceRange(child.offset, child.length),
              AngularWarningCode.CONTENT_NOT_TRANSCLUDED);
        } else if (matchedTag) {
          child.tagMatchedAsTransclusion = true;
        }
      }
    }
  }

  @override
  void visitElementInfo(ElementInfo element) {
    // TODO should we visitTemplateAttr(element.templateAttribute) ??
    var tagIsStandard = _isStandardTagName(element.localName);
    Component component;

    for (final directive in element.directives) {
      if (directive is Component) {
        component = directive;
        // TODO better html tag detection, see #248
        tagIsStandard = component.isHtml;
      }
    }

    if (!tagIsStandard &&
        !element.tagMatchedAsTransclusion &&
        !element.tagMatchedAsDirective &&
        !element.tagMatchedAsCustomTag) {
      _reportErrorForRange(element.openingNameSpan,
          AngularWarningCode.UNRESOLVED_TAG, [element.localName]);
    }

    if (!tagIsStandard) {
      checkTransclusionsContentChildren(component, element.childNodes,
          tagIsStandard: tagIsStandard);
    }

    for (final child in element.childNodes) {
      child.accept(this);
    }
  }

  /// Check whether the given [name] is a standard HTML5 tag name.
  bool _isStandardTagName(String name) {
    // ignore: parameter_assignments
    name = name.toLowerCase();
    return !name.contains('-') ||
        name == 'ng-content' ||
        name == 'ng-container';
  }

  void _reportErrorForRange(SourceRange range, ErrorCode errorCode,
      [List<Object> arguments]) {
    errorListener.onError(AnalysisError(
        templateSource, range.offset, range.length, errorCode, arguments));
  }
}
