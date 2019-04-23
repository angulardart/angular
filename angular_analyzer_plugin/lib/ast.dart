import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/selector.dart';
import 'package:meta/meta.dart';

/// A node in the plugin's template/html/angular binding AST.
///
/// Currently the plugin uses its own AST because we need to store our own
/// resolution information in it. Therefore we don't resolve the angular_ast
/// package nodes.
abstract class AngularAstNode {
  List<AngularAstNode> get children;
  int get length;
  int get offset;

  void accept(AngularAstVisitor visitor);
}

/// Base visitor class for the plugin AST.
abstract class AngularAstVisitor {
  void visitDocumentInfo(DocumentInfo document) {
    for (AngularAstNode child in document.childNodes) {
      child.accept(this);
    }
  }

  void visitElementInfo(ElementInfo elementInfo) =>
      _visitAllChildren(elementInfo);

  void visitEmptyStarBinding(EmptyStarBinding emptyBinding) =>
      visitTextAttr(emptyBinding);

  void visitExpressionBoundAttr(ExpressionBoundAttribute attr) =>
      _visitAllChildren(attr);

  void visitMustache(Mustache mustache) {}

  void visitStatementsBoundAttr(StatementsBoundAttribute attr) =>
      _visitAllChildren(attr);

  void visitTemplateAttr(TemplateAttribute attr) => _visitAllChildren(attr);

  void visitTextAttr(TextAttribute textAttr) => _visitAllChildren(textAttr);

  void visitTextInfo(TextInfo textInfo) => _visitAllChildren(textInfo);

  void _visitAllChildren(AngularAstNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
  }
}

/// Information about any HTML attribute, ie, `foo="bar"` or `[foo]="bar"`.
abstract class AttributeInfo extends AngularAstNode {
  HasDirectives parent;

  final String name;
  final int nameOffset;

  final String value;
  final int valueOffset;

  final String originalName;
  final int originalNameOffset;

  AttributeInfo(this.name, this.nameOffset, this.value, this.valueOffset,
      this.originalName, this.originalNameOffset);

  @override
  int get length => valueOffset == null
      ? originalName.length
      : valueOffset + value.length - originalNameOffset;

  @override
  int get offset => originalNameOffset;

  int get valueLength => value != null ? value.length : 0;

  @override
  String toString() =>
      '([$name, $nameOffset], [$value, $valueOffset, $valueLength], '
      '[$originalName, $originalNameOffset])';
}

/// Information about attributes that can be bound to a component or directive.
abstract class BoundAttributeInfo extends AttributeInfo {
  Map<String, LocalVariable> localVariables = <String, LocalVariable>{};

  BoundAttributeInfo(String name, int nameOffset, String value, int valueOffset,
      String originalName, int originalNameOffset)
      : super(name, nameOffset, value, valueOffset, originalName,
            originalNameOffset);

  @override
  List<AngularAstNode> get children => const <AngularAstNode>[];

  @override
  String toString() => '(${super.toString()}, [$children])';
}

/// A location where a content child is bound to a template.
///
/// Allows us to track ranges for navigating ContentChild(ren), and detect when
/// multiple ContentChilds are matched which is an error.
///
/// Naming here is important: "bound content child" != "content child binding."
class ContentChildBinding {
  final DirectiveBase directive;
  final ContentChild boundContentChild;
  final Set<ElementInfo> boundElements = <ElementInfo>{};
  // TODO: track bound attributes in #foo?

  ContentChildBinding(this.directive, this.boundContentChild);
}

/// A location where an [DirectiveBase] is bound to a template.
///
/// These occur on an [ElementInfo] or a [TemplateAttribute]. For each bound
/// directive, there is a directive binding. Has [InputBinding]s and
/// [OutputBinding]s which themselves indicate an [AttributeInfo] bound to an
/// [Input] or [Input] in the context of this [DirectiveBinding].
///
/// Naming here is important: "bound directive" != "directive binding."
class DirectiveBinding {
  final DirectiveBase boundDirective;
  final inputBindings = <InputBinding>[];
  final outputBindings = <OutputBinding>[];
  final contentChildBindings = <ContentChild, ContentChildBinding>{};
  final contentChildrenBindings = <ContentChild, ContentChildBinding>{};

  DirectiveBinding(this.boundDirective);
}

/// A wrapper for a given HTML document or dart-angular inline HTML template.
///
/// This is really here for historic reasons, because it closer resembels the
/// result of the original HTML parser we used. However, angular does not deal
/// with HTML documents, only snippets, and therefore its unnecessary.
///
/// However, it does make for a single node as a point of entry instead of a
/// list of nodes, which is nice.
class DocumentInfo extends ElementInfo {
  factory DocumentInfo() = DocumentInfo._;

  DocumentInfo._()
      : super(
          '',
          const SourceRange(0, 0),
          const SourceRange(0, 0),
          const SourceRange(0, 0),
          const SourceRange(0, 0),
          [],
          null,
          null,
          isTemplate: false,
        );

  @override
  List<AngularAstNode> get children => childNodes;

  @override
  bool get isSynthetic => false;

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitDocumentInfo(this);
}

/// An element in an HTML tree.
class ElementInfo extends NodeInfo implements HasDirectives {
  static const _closeBracket = '>';

  final List<NodeInfo> childNodes = <NodeInfo>[];

  final String localName;
  final SourceRange openingSpan;
  final SourceRange closingSpan;
  final SourceRange openingNameSpan;
  final SourceRange closingNameSpan;
  final bool isTemplate;
  final List<AttributeInfo> attributes;
  final TemplateAttribute templateAttribute;
  final ElementInfo parent;

  @override
  final boundDirectives = <DirectiveBinding>[];
  @override
  final boundStandardOutputs = <OutputBinding>[];
  @override
  final boundStandardInputs = <InputBinding>[];
  @override
  final availableDirectives = <DirectiveBase, List<SelectorName>>{};

  int childNodesMaxEnd;

  bool tagMatchedAsTransclusion = false;
  bool tagMatchedAsDirective = false;
  bool tagMatchedAsImmediateContentChild = false;
  bool tagMatchedAsCustomTag = false;
  ElementInfo(
      this.localName,
      this.openingSpan,
      this.closingSpan,
      this.openingNameSpan,
      this.closingNameSpan,
      this.attributes,
      this.templateAttribute,
      this.parent,
      {@required this.isTemplate}) {
    if (!isSynthetic) {
      childNodesMaxEnd = offset + length;
    }
  }

  @override
  List<AngularAstNode> get children {
    final list = List<AngularAstNode>.from(attributes);
    if (templateAttribute != null) {
      list.add(templateAttribute);
    }
    return list..addAll(childNodes);
  }

  List<DirectiveBase> get directives =>
      boundDirectives.map((bd) => bd.boundDirective).toList();
  bool get isOrHasTemplateAttribute => isTemplate || templateAttribute != null;

  @override
  bool get isSynthetic => openingSpan == null;

  @override
  int get length => (closingSpan != null)
      ? closingSpan.offset + closingSpan.length - openingSpan.offset
      : ((childNodesMaxEnd != null)
          ? childNodesMaxEnd - offset
          : openingSpan.length);

  @override
  int get offset => openingSpan.offset;

  bool get openingSpanIsClosed => isSynthetic
      ? false
      : (openingSpan.offset + openingSpan.length) ==
          (openingNameSpan.offset +
              openingNameSpan.length +
              _closeBracket.length);

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitElementInfo(this);
}

/// A location in a template where a star attr was made and not bound.
///
/// `*deferred` creates an empty text attribute, which is harmless. But so do
/// the less harmless cases of empty `*ngIf`, and or `*ngFor="let item of"`,
/// etc.
class EmptyStarBinding extends TextAttribute {
  /// Whether this is bound to the star attr itself, or an inner attribute.
  ///
  /// It is usually harmless if the star attr is not bound. However, it is
  /// usually a problem if the inner attributes are not bound.
  bool isPrefix;

  EmptyStarBinding(
      String name, int nameOffset, String originalName, int originalNameOffset,
      {@required this.isPrefix})
      : super.synthetic(
            name, nameOffset, null, null, originalName, originalNameOffset, []);

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitEmptyStarBinding(this);
}

/// An expression bound attribute is an input or two way binding.
///
/// The right hand side of the attribute represents a dart expression,
/// therefore, not outputs (which have statements on the rhs) or template
/// attributes (which hase microsyntax on the rhs).
class ExpressionBoundAttribute extends BoundAttributeInfo {
  Expression expression;
  final ExpressionBoundType bound;
  ExpressionBoundAttribute(
      String name,
      int nameOffset,
      String value,
      int valueOffset,
      String originalName,
      int originalNameOffset,
      this.expression,
      this.bound)
      : super(name, nameOffset, value, valueOffset, originalName,
            originalNameOffset);

  @override
  void accept(AngularAstVisitor visitor) =>
      visitor.visitExpressionBoundAttr(this);

  @override
  String toString() => '(${super.toString()}, [$bound, $expression])';
}

/// The type of binding on a bound expression.
enum ExpressionBoundType { input, twoWay, attr, attrIf, clazz, style }

/// An AngularAstNode which has directives, such as [ElementInfo] and
/// [TemplateAttribute].
///
/// Contains an array of [DirectiveBinding]s because those contain more info
/// than just the bound directive itself.
abstract class HasDirectives extends AngularAstNode {
  Map<DirectiveBase, List<SelectorName>> get availableDirectives;
  List<DirectiveBinding> get boundDirectives;
  List<InputBinding> get boundStandardInputs;
  List<OutputBinding> get boundStandardOutputs;
}

/// A binding between an [AttributeInfo] and an [Input].
///
/// This is used in the context of a [DirectiveBinding] because each instance of
/// a bound directive has different input bindings. Note that inputs can be
/// bound via bracket syntax (an [ExpressionBoundAttribute]), or via plain
/// attribute syntax (a [TextAttribute]).
///
/// Naming here is important: "bound input" != "input binding."
class InputBinding {
  final Input boundInput;
  final AttributeInfo attribute;

  InputBinding(this.boundInput, this.attribute);
}

/// A variable defined inside an angular template via `#foo`, `let-foo`, etc.
class LocalVariable extends DartElement {
  final String name;
  final SourceRange localRange;
  final LocalVariableElement dartVariable;

  LocalVariable(this.name, this.dartVariable, {this.localRange})
      : super(dartVariable) {
    assert(source != null);
  }

  @override
  SourceRange get navigationRange => localRange ?? super.navigationRange;
}

/// A mustache binding in a template, ie, `{{foo}}`.
class Mustache extends AngularAstNode {
  Expression expression;
  @override
  final int offset;
  @override
  final int length;
  final int exprBegin;
  final int exprEnd;

  Map<String, LocalVariable> localVariables = <String, LocalVariable>{};

  Mustache(
    this.offset,
    this.length,
    this.expression,
    this.exprBegin,
    this.exprEnd,
  );

  @override
  List<AngularAstNode> get children => const <AngularAstNode>[];

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitMustache(this);
}

/// The HTML elements in the tree: tags, text nodes, but not attributes etc.
abstract class NodeInfo extends AngularAstNode {
  bool get isSynthetic;
}

/// A binding between an [BoundAttributeInfo] and an [Input].
///
/// This is used in the context of a [DirectiveBinding] because each instance of
/// a bound directive has different output bindings.
///
/// Binds to an [BoundAttributeInfo] and not a [StatementsBoundAttribute]
/// because it might be a two-way binding, and thats the greatest common subtype
/// of statements bound and expression bound attributes.
///
/// Naming here is important: "bound output" != "output binding."
class OutputBinding {
  final Output boundOutput;
  final BoundAttributeInfo attribute;

  OutputBinding(this.boundOutput, this.attribute);
}

/// An attribute where the value is a set of dart [Statements].
///
/// For instance, an output `(foo)="bar(); baz();"`.
class StatementsBoundAttribute extends BoundAttributeInfo {
  static const _period = '.';

  List<Statement> statements;

  /// Reductions as in `(keyup.ctrl.shift.space)`. Not currently analyzed.
  List<String> reductions;

  StatementsBoundAttribute(
      String name,
      int nameOffset,
      String value,
      int valueOffset,
      String originalName,
      int originalNameOffset,
      this.reductions,
      this.statements)
      : super(name, nameOffset, value, valueOffset, originalName,
            originalNameOffset);

  int get reductionsLength => reductions.isEmpty
      ? null
      : _period.length + reductions.join(_period).length;

  int get reductionsOffset =>
      reductions.isEmpty ? null : nameOffset + name.length;
  @override
  void accept(AngularAstVisitor visitor) =>
      visitor.visitStatementsBoundAttr(this);

  @override
  String toString() => '(${super.toString()}, [$statements])';
}

/// Represents either a star-attr or `template="foo"` attribute.
///
/// Note that these introduce a new context which can have its own directive
/// bindings, so this has more in common with [ElementInfo] than with other
/// types of attributes.
class TemplateAttribute extends BoundAttributeInfo implements HasDirectives {
  final List<AttributeInfo> virtualAttributes;
  @override
  final boundDirectives = <DirectiveBinding>[];
  @override
  final boundStandardOutputs = <OutputBinding>[];
  @override
  final boundStandardInputs = <InputBinding>[];
  @override
  final availableDirectives = <DirectiveBase, List<SelectorName>>{};

  String prefix;

  TemplateAttribute(String name, int nameOffset, String value, int valueOffset,
      String originalName, int originalNameOffset, this.virtualAttributes,
      {this.prefix})
      : super(name, nameOffset, value, valueOffset, originalName,
            originalNameOffset);

  @override
  List<AngularAstNode> get children =>
      List<AngularAstNode>.from(virtualAttributes);

  List<DirectiveBase> get directives =>
      boundDirectives.map((bd) => bd.boundDirective).toList();

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitTemplateAttr(this);

  @override
  String toString() => '(${super.toString()}, [$virtualAttributes])';
}

/// A simple text attribute, ie, `foo="bar"`.
///
/// May have mustaches, ie, `foo="{{bar}}"`.
class TextAttribute extends AttributeInfo {
  final List<Mustache> mustaches;
  final bool isReference;

  TextAttribute(String name, int nameOffset, String value, int valueOffset,
      this.mustaches)
      : isReference = name.startsWith('#'),
        super(name, nameOffset, value, valueOffset, name, nameOffset);

  TextAttribute.synthetic(
      String name,
      int nameOffset,
      String value,
      int valueOffset,
      String originalName,
      int originalNameOffset,
      this.mustaches)
      : isReference = name.startsWith('#'),
        super(name, nameOffset, value, valueOffset, originalName,
            originalNameOffset);

  @override
  List<AngularAstNode> get children => List<AngularAstNode>.from(mustaches);

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitTextAttr(this);
}

/// A text node in an HTML tree.
class TextInfo extends NodeInfo {
  final List<Mustache> mustaches;
  final ElementInfo parent;
  final String text;

  @override
  final int offset;
  final bool _isSynthetic;
  TextInfo(this.offset, this.text, this.parent, this.mustaches,
      {bool synthetic = false})
      : _isSynthetic = synthetic;

  @override
  List<AngularAstNode> get children => List<AngularAstNode>.from(mustaches);

  @override
  bool get isSynthetic => _isSynthetic;

  @override
  int get length => text.length;

  @override
  void accept(AngularAstVisitor visitor) => visitor.visitTextInfo(this);
}
