import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:angular_analyzer_plugin/src/model/navigable.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/content_child.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/input.dart';
import 'package:angular_analyzer_plugin/src/model/resolved/output.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:meta/meta.dart';

/// The resolved model of a functional directive declaration.
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
/// have inputs, outputs, etc. But for the sake of clean code, those methods are
/// implemented to return null, empty list, etc.
class FunctionalDirective implements DirectiveBase {
  /// The [dart.FunctionElement] behind this functional directive.
  final dart.FunctionElement functionElement;

  @override
  final Selector selector;

  @override
  final bool looksLikeTemplate;

  FunctionalDirective(this.functionElement, this.selector,
      {@required this.looksLikeTemplate});

  // We don't support `@Attribute`s on functional directives.
  @override
  List<NavigableString> get attributes => const [];

  // Functional directives cannot have content children.
  @override
  List<ContentChild> get contentChildFields => const [];

  // Functional directives cannot have content children.
  @override
  List<ContentChild> get contentChildrenFields => const [];

  /// Functional directives cannot be exported.
  @override
  NavigableString get exportAs => null;

  @override
  int get hashCode => functionElement.hashCode;

  @override
  List<Input> get inputs => const [];

  /// HTML does not define any functional directives.
  @override
  bool get isHtml => false;

  @override
  List<Output> get outputs => const [];

  /// The source that contains this directive.
  @override
  Source get source => functionElement.source;

  @override
  bool operator ==(Object other) =>
      other is FunctionalDirective && other.functionElement == functionElement;

  @override
  String toString() => 'FunctionalDirective(${functionElement.displayName} '
      'selector=$selector ';
}
