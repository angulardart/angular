import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model/syntactic/directive_base.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';

/// The syntactic model of a functional directive declaration.
///
/// ```dart
/// @Directive(
///   selector: 'my-selector'
/// ),
/// void myDirective(...) {...}
/// ```
///
/// A functional directive is applied to an angular app at runtime when the
/// directive is linked, but does nothing later in the program. Thus it cannot
/// have inputs, outputs, etc.
class FunctionalDirective implements DirectiveBase {
  final String functionName;

  @override
  final Source source;

  @override
  final Selector selector;

  FunctionalDirective(this.functionName, this.source, this.selector);

  @override
  String toString() =>
      'FunctionalDirective($functionName ' 'selector=$selector ';
}
