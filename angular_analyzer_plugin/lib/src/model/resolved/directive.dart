import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/annotated_class.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/input.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/output.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:meta/meta.dart';

/// Resolved model of an Angular directive. This excludes functional
/// directives, if you want to include functional directives then use
/// BaseDirective.
///
/// ```dart
/// @Directive(
///   selector: 'my-selector', // required
///   exportAs: 'foo', // optional
/// )
/// class MyDirective { // must be a class
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
class Directive extends AnnotatedClass implements DirectiveBase {
  @override
  final Selector selector;

  @override
  final NavigableString exportAs;

  @override
  final bool looksLikeTemplate;

  Directive(dart.ClassElement classElement,
      {@required this.exportAs,
      @required List<Input> inputs,
      @required List<Output> outputs,
      @required this.selector,
      @required this.looksLikeTemplate,
      @required List<ContentChild> contentChildFields,
      @required List<ContentChild> contentChildrenFields})
      : super(classElement,
            inputs: inputs,
            outputs: outputs,
            contentChildFields: contentChildFields,
            contentChildrenFields: contentChildrenFields);

  /// Directives do not have attributes.
  @override
  List<NavigableString> get attributes => const [];

  @override
  bool get isHtml => false;
}
