import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analyzer/src/generated/source.dart' show Source, SourceRange;
import 'package:angular_analyzer_plugin/src/model/syntactic/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/directive.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/input.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/ng_content.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/output.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/reference.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:meta/meta.dart';

/// Syntactic model of an Angular component.
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
///
/// Note that the syntactic model of a component only includes its inline
/// [NgContent]s. See [ngContent]/README.md for more information.
class Component extends Directive {
  /// Directives references. May be `directives: LIST_OF_DIRECTIVES`, or
  /// `directives: [DirectiveA, DirectiveB, ...]`.
  final ListOrReference directives;

  /// Pipe references. May be `pipes: LIST_OF_PIPES`, or
  /// `pipes: [PipeA, PipeB, ...]`.
  final ListOrReference pipes;

  /// Export references. May be `exports: LIST_OF_CONST_VALUES`, or
  /// `exports: [foo, bar, ...]`.
  final ListOrReference exports;

  /// The inline [NgContent]s of this component. This is null when
  /// [templateText] is null/when `templateUrl` is specified. This is because
  /// external [NgContent]s are not purely syntactic. See README.md.
  final List<NgContent> inlineNgContents;

  final String templateText;
  final SourceRange templateTextRange;
  final String templateUrl;
  final SourceRange templateUrlRange;

  Component(String className, Source source,
      {@required String exportAs,
      @required SourceRange exportAsRange,
      @required List<Input> inputs,
      @required List<Output> outputs,
      @required Selector selector,
      @required List<ContentChild> contentChildFields,
      @required List<ContentChild> contentChildrenFields,
      @required this.directives,
      @required this.pipes,
      @required this.exports,
      @required this.templateText,
      @required this.templateTextRange,
      @required this.inlineNgContents,
      @required this.templateUrl,
      @required this.templateUrlRange})
      : super(className, source,
            exportAs: exportAs,
            exportAsRange: exportAsRange,
            inputs: inputs,
            outputs: outputs,
            selector: selector,
            contentChildFields: contentChildFields,
            contentChildrenFields: contentChildrenFields);
}
