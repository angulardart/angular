import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/directive.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/export.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/input.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/output.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/pipe.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/template.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:angular_analyzer_plugin/src/selector/element_name_selector.dart';
import 'package:meta/meta.dart';

/// Resolved model of an Angular component.
///
/// A component is a directive with a template, which also has additional
/// information used to render and interact with that template.
///
/// ```dart
/// @Component(
///   selector: 'my-selector', // required
///   exportAs: 'foo', // optional
///   directives: [SubDirectiveA, SubDirectiveB], // optional
///   pipes: [PipeA, PipeB], // optional
///   exports: [foo, bar], // optional
///
///   // Template required. May be an inline body or a URI
///   template: '...', // or
///   templateUri: '...',
/// )
/// class MyComponent { // must be a class
///   @Input() input; // may have inputs
///   @Output() output; // may have outputs
///
///   // may have content child(ren).
///   @ContentChild(...) child;
///   @ContentChildren(...) children;
///
///   MyComponent(
///     @Attribute() String attr, // may have attributes
///   );
/// }
/// ```
class Component extends Directive {
  /// The directives used in the template of this component.
  final List<DirectiveBase> directives;

  /// The pipes used in the template of this component.
  final List<Pipe> pipes;

  /// The template text if it is an inline template.
  final String templateText;

  /// The [SourceRange] of the template text if it is an inline template.
  final SourceRange templateTextRange;

  /// The [Source] of the template if it defines a `templateUrl`
  final Source templateUrlSource;

  /// The [SourceRange] of the `templateUrl` if it defines one.
  final SourceRange templateUrlRange;

  Map<String, List<DirectiveBase>> _elementTagsInfo;

  /// The [Template] of this component.
  Template _template;

  @override
  final bool isHtml;

  /// List of `<ng-content>` selectors in this component's template.
  final List<NgContent> ngContents;

  /// List of exported identifiers in this component's template.
  final List<Export> exports;

  /// List of `@Attribute() foo` arguments in this component's ctor.
  @override
  final List<NavigableString> attributes;

  Component(dart.ClassElement classElement,
      {@required NavigableString exportAs,
      @required this.directives,
      @required this.pipes,
      @required this.templateTextRange,
      @required this.templateText,
      @required this.templateUrlSource,
      @required this.templateUrlRange,
      @required this.exports,
      @required this.ngContents,
      @required List<Input> inputs,
      @required List<Output> outputs,
      @required Selector selector,
      @required bool looksLikeTemplate,
      @required this.isHtml,
      @required List<ContentChild> contentChildFields,
      @required List<ContentChild> contentChildrenFields,
      @required this.attributes})
      : super(classElement,
            exportAs: exportAs,
            inputs: inputs,
            outputs: outputs,
            looksLikeTemplate: looksLikeTemplate,
            selector: selector,
            contentChildFields: contentChildFields,
            contentChildrenFields: contentChildrenFields);

  Map<String, List<DirectiveBase>> get elementTagsInfo {
    if (_elementTagsInfo == null) {
      _elementTagsInfo = <String, List<DirectiveBase>>{};
      for (final directive in directives) {
        final elementNameSelectors = <ElementNameSelector>[];
        directive.selector.recordElementNameSelectors(elementNameSelectors);
        for (final elementTag in elementNameSelectors) {
          final tagName = elementTag.toString();
          _elementTagsInfo.putIfAbsent(tagName, () => <DirectiveBase>[]);
          _elementTagsInfo[tagName].add(directive);
        }
      }
    }
    return _elementTagsInfo;
  }

  /// The source that contains this view.
  @override
  Source get source => classElement.source;

  Template get template => _template;

  set template(Template template) {
    assert(_template == null, 'template cannot be changed');
    _template = template;
  }

  /// The source that contains this template, [source] or [templateUrlSource].
  Source get templateSource => templateUrlSource ?? source;
}
