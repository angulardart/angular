import 'package:analyzer/dart/ast/ast.dart' hide Directive;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/error_verifier.dart';
import 'package:meta/meta.dart';
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';

/// Visitor to report disallowed dart expressions in a template.
///
/// Find nodes which are not supported in angular (such as compound assignment
/// and function expressions etc.), as well as terms used in the template that
/// weren't exported by the component.
class AngularSubsetVisitor extends RecursiveAstVisitor<Object> {
  final bool acceptAssignment;
  final Component owningComponent;

  final ErrorReporter errorReporter;

  AngularSubsetVisitor(
      {@required this.errorReporter,
      @required this.owningComponent,
      @required this.acceptAssignment});

  @override
  void visitAsExpression(AsExpression exp) {
    // An offset of 0 means we generated this in a pipe, and its OK.
    if (exp.asOperator.offset != 0) {
      _reportDisallowedExpression(exp, "As expression", visitChildren: false);
    }

    // Don't visit the TypeName or it may suggest exporting it, which is not
    // possible.
    exp.expression.accept(this);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression exp) {
    if (exp.operator.type != TokenType.EQ) {
      _reportDisallowedExpression(exp, 'Compound assignment',
          visitChildren: false);
    }
    // Only block reassignment of locals, not poperties. Resolve elements to
    // check that.
    final variableElement = ErrorVerifier.getVariableElement(exp.leftHandSide);
    final isLocal =
        variableElement != null && variableElement is! PropertyInducingElement;
    if (!acceptAssignment || isLocal) {
      _reportDisallowedExpression(exp, 'Assignment of locals',
          visitChildren: false);
    }

    super.visitAssignmentExpression(exp);
  }

  @override
  void visitAwaitExpression(AwaitExpression exp) =>
      _reportDisallowedExpression(exp, "Await");

  @override
  void visitCascadeExpression(CascadeExpression exp) =>
      _reportDisallowedExpression(exp, "Cascades");

  @override
  void visitFunctionExpression(FunctionExpression exp) =>
      _reportDisallowedExpression(exp, "Anonymous functions");

  /// Check that an identifier is valid in an angular template.
  ///
  /// Only allow access to:
  /// * current class members
  /// * inherited class members
  /// * methods
  /// * angular references (ie `<h1 #ref id="foo"></h1> {{h1.id}}`)
  /// * exported members
  ///
  /// Flag the rest and give the hint that they should be exported.
  void visitIdentifier(Identifier id) {
    final element = id.staticElement;
    final parent = id.parent;
    if (id is PrefixedIdentifier && id.prefix.staticElement is! PrefixElement) {
      // Static methods, enums, etc. Check the LHS.
      visitIdentifier(id.prefix);
      return;
    }
    if (parent is PropertyAccess && id == parent.propertyName) {
      // Accessors are always allowed.
      return;
    }
    if (element is PrefixElement) {
      // Prefixes can't be exported, and analyzer reports a warning for dangling
      // prefixes.
      return;
    }
    if (element is MethodElement) {
      // All methods are OK, as in `x.y()`. It's only `x` that may be hidden.
      return;
    }
    if (element is ClassElement && element == owningComponent.classElement) {
      // Static method calls on the current class are allowed
      return;
    }
    if (element is DynamicElementImpl) {
      // Usually indicates a resolution error, so don't double report it.
      return;
    }
    if (element == null) {
      // Also usually indicates an error, don't double report.
      return;
    }
    if (element is LocalVariableElement) {
      // `$event` variables, `ngFor` variables, these are OK.
      return;
    }
    if (element is ParameterElement) {
      // Named parameters always allowed
      return;
    }
    if (id is SimpleIdentifier &&
        (element is PropertyInducingElement ||
            element is PropertyAccessorElement) &&
        (owningComponent.classElement.lookUpGetter(id.name, null) != null ||
            owningComponent.classElement.lookUpSetter(id.name, null) != null)) {
      // Part of the component interface.
      return;
    }

    if (id is PrefixedIdentifier) {
      if (owningComponent.exports.any((export) =>
          export.prefix == id.prefix.name &&
          id.identifier.name == export.name)) {
        // Correct reference to exported prefix identifier
        return;
      }
    } else {
      if (parent is MethodInvocation && parent.methodName == id) {
        final target = parent.target;
        if (target is SimpleIdentifier &&
            target.staticElement is PrefixElement &&
            owningComponent.exports.any((export) =>
                export.prefix == target.name && export.name == id.name)) {
          // Invocation of a top-level function behind a prefix, which is stored
          // as a [MethodInvocation].
          return;
        }
      }
      if (owningComponent.exports
          .any((export) => export.prefix == '' && id.name == export.name)) {
        // Correct reference to exported simple identifier
        return;
      }
    }

    errorReporter.reportErrorForNode(
        AngularWarningCode.IDENTIFIER_NOT_EXPORTED, id, [id]);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression exp) {
    _reportDisallowedExpression(exp, "Usage of new", visitChildren: false);
    // Don't visit the TypeName or it may suggest exporting it, which is not
    // possible.

    exp.argumentList.accept(this);
  }

  @override
  void visitIsExpression(IsExpression exp) {
    _reportDisallowedExpression(exp, "Is expression", visitChildren: false);
    // Don't visit the TypeName or it may suggest exporting it, which is not
    // possible.

    exp.expression.accept(this);
  }

  @override
  void visitListLiteral(ListLiteral list) {
    if (list.typeArguments != null) {
      _reportDisallowedExpression(list, "Typed list literals",
          visitChildren: false);
      // Don't visit the TypeName or it may suggest exporting it, which is not
      // possible.

      list.elements.accept(this);
    } else {
      super.visitListLiteral(list);
    }
  }

  @override
  void visitPostfixExpression(PostfixExpression exp) {
    _reportDisallowedExpression(exp, exp.operator.lexeme);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier id) => visitIdentifier(id);

  @override
  void visitPrefixExpression(PrefixExpression exp) {
    if (exp.operator.type != TokenType.MINUS &&
        exp.operator.type != TokenType.BANG) {
      _reportDisallowedExpression(exp, exp.operator.lexeme);
    }
  }

  @override
  void visitSetOrMapLiteral(SetOrMapLiteral map) {
    if (map.typeArguments != null) {
      _reportDisallowedExpression(map, "Typed map literals",
          visitChildren: false);
      // Don't visit the TypeName or it may suggest exporting it, which is not
      // possible.

      map.elements.accept(this);
    } else {
      super.visitSetOrMapLiteral(map);
    }
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier id) => visitIdentifier(id);

  @override
  void visitSymbolLiteral(SymbolLiteral exp) =>
      _reportDisallowedExpression(exp, "Symbol literal");

  @override
  void visitThrowExpression(ThrowExpression exp) =>
      _reportDisallowedExpression(exp, "Throw");

  void _reportDisallowedExpression(Expression node, String description,
      {bool visitChildren = true}) {
    errorReporter.reportErrorForNode(
        AngularWarningCode.DISALLOWED_EXPRESSION, node, [description]);

    if (visitChildren) {
      node.visitChildren(this);
    }
  }
}
