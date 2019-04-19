import 'package:analyzer/dart/ast/ast.dart' as dart;
import 'package:analyzer/dart/element/element.dart' as dart;
import 'package:analyzer/dart/element/type.dart' as dart;
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/src/model/resolved/directive_base.dart';
import 'package:angular_analyzer_plugin/src/model/syntactic/content_child.dart'
    as syntactic;
import 'package:meta/meta.dart';

/// A resolved version of a content child.
///
/// In addition to syntactic information, contains [QueriedChildType] which
/// abstracts how a content child is matched, and an optional [read] [DartType].
class ContentChild extends syntactic.ContentChild {
  final QueriedChildType query;

  /// Look up a symbol from the injector. We don't track the injector yet.
  final dart.DartType read;

  ContentChild(String fieldName,
      {@required SourceRange nameRange,
      @required SourceRange typeRange,
      @required this.query,
      @required this.read})
      : super(fieldName, nameRange: nameRange, typeRange: typeRange);
}

/// Represents `@ContentChild(SomeDirective)` queries.
class DirectiveQueriedChildType extends QueriedChildType {
  final DirectiveBase directive;
  DirectiveQueriedChildType(this.directive);
  @override
  T accept<T>(QueriedChildTypeVisitor<T> visitor) =>
      visitor.visitDirectiveQueriedChildType(this);
}

/// Represents both Element and HtmlElement queries.
///
/// Note that in a perfect analysis we would distinguish these because SVG is
/// not an HtmlElement.
class ElementQueriedChildType extends QueriedChildType {
  @override
  T accept<T>(QueriedChildTypeVisitor<T> visitor) =>
      visitor.visitElementQueriedChildType(this);
}

/// `@ContentChild('foo')` queries, which match `<el #foo>` in the template.
class LetBoundQueriedChildType extends QueriedChildType {
  final String letBoundName;
  final dart.DartType containerType;
  LetBoundQueriedChildType(this.letBoundName, this.containerType);
  @override
  T accept<T>(QueriedChildTypeVisitor<T> visitor) =>
      visitor.visitLetBoundQueriedChildType(this);
}

/// Base class for `@ContentChild` query types.
///
/// The query may be a directive, element, or let-bound variable. Supports a
/// visitor to distinguish these cases.
abstract class QueriedChildType {
  T accept<T>(QueriedChildTypeVisitor<T> visitor);
}

/// A visitor for [QueriedChildType], used to match queries to the AST.
abstract class QueriedChildTypeVisitor<T> {
  T visitDirectiveQueriedChildType(DirectiveQueriedChildType query);
  T visitElementQueriedChildType(ElementQueriedChildType query);
  T visitLetBoundQueriedChildType(LetBoundQueriedChildType query);
  T visitTemplateRefQueriedChildType(TemplateRefQueriedChildType query);
}

/// Represents `@ContentChild(TemplateRef)` queries.
class TemplateRefQueriedChildType extends QueriedChildType {
  @override
  T accept<T>(QueriedChildTypeVisitor<T> visitor) =>
      visitor.visitTemplateRefQueriedChildType(this);
}
