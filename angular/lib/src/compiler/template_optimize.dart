import 'analyzed_class.dart';
import 'compile_metadata.dart';
import 'identifiers.dart';
import 'output/convert.dart';
import 'output/output_ast.dart';
import 'template_ast.dart';
import 'template_parser/recursive_template_visitor.dart';

/// Augments [TemplateAst]s with additional information to enable optimizations.
///
/// This information can't be provided during construction of the [TemplateAst]s
/// as it may not exist yet at the time it is needed.
class OptimizeTemplateAstVisitor extends RecursiveTemplateVisitor<Null> {
  final CompileDirectiveMetadata _component;

  OptimizeTemplateAstVisitor(this._component);

  @override
  TemplateAst visitEmbeddedTemplate(EmbeddedTemplateAst ast, _) {
    _typeNgForLocals(_component, ast.directives, ast.variables);
    return super.visitEmbeddedTemplate(ast, null);
  }
}

/// Adds type information to the [VariableAst]s of `NgFor` locals.
///
/// This type information is used to type-annotate the local variable
/// declarations, which would otherwise be dynamic as they're retrieved from a
/// dynamic map.
void _typeNgForLocals(
  CompileDirectiveMetadata component,
  List<DirectiveAst> directives,
  List<VariableAst> variables,
) {
  final ngFor = directives.firstWhere(
      (directive) =>
          directive.directive.type.moduleUrl ==
          Identifiers.NG_FOR_DIRECTIVE.moduleUrl,
      orElse: () => null);
  if (ngFor == null) return; // No `NgFor` to optimize.
  BoundExpression ngForOfValue;
  for (final input in ngFor.inputs) {
    if (input.templateName == 'ngForOf') {
      final boundValue = input.value;
      if (boundValue is BoundExpression) {
        ngForOfValue = boundValue;
      }
      break;
    }
  }
  if (ngForOfValue == null) {
    // No [ngForOf] binding from which to get type.
    return;
  }
  final ngForOfType =
      getExpressionType(ngForOfValue.expression, component.analyzedClass);
  // Augment locals set by `NgFor` with type information.
  for (var variable in variables) {
    switch (variable.value) {
      case r'$implicit':
        // This local is the generic type of the `Iterable` bound to [ngForOf].
        final elementType = getIterableElementType(ngForOfType);
        variable.type = fromDartType(elementType, resolveBounds: false);
        break;
      case 'index':
      case 'count':
        // These locals are always integers.
        variable.type = INT_TYPE;
        break;
      case 'first':
      case 'last':
      case 'even':
      case 'odd':
        // These locals are always booleans.
        variable.type = BOOL_TYPE;
        break;
    }
  }
}
