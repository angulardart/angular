import 'analyzed_class.dart';
import 'compile_metadata.dart';
import 'identifiers.dart';
import 'template_ast.dart';
import 'template_parser/recursive_template_visitor.dart';

/// Augments [TemplateAst]s with additional information to enable optimizations.
///
/// This information can't be provided during construction of the [TemplateAst]s
/// as it may not exist yet at the time it is needed.
class OptimizeTemplateAstVisitor
    extends RecursiveTemplateVisitor<CompileDirectiveMetadata> {
  OptimizeTemplateAstVisitor();

  @override
  TemplateAst visitEmbeddedTemplate(
      EmbeddedTemplateAst ast, CompileDirectiveMetadata component) {
    _typeNgForLocals(component, ast.directives, ast.variables);

    // Add the local variables to the [CompileDirectiveMetadata] used in
    // children embedded templates.
    var scoped = CompileDirectiveMetadata.from(component,
        analyzedClass: AnalyzedClass.from(
          component.analyzedClass,
          additionalLocals: Map.fromIterable(
            ast.variables,
            key: (v) => (v as VariableAst).name,
            value: (v) => (v as VariableAst).dartType,
          ),
        ));

    return super.visitEmbeddedTemplate(ast, scoped);
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
      getExpressionType(ngForOfValue.expression.ast, component.analyzedClass);
  // Augment locals set by `NgFor` with type information.
  for (var variable in variables) {
    switch (variable.value) {
      case r'$implicit':
        // This local is the generic type of the `Iterable` bound to [ngForOf].
        variable.dartType = getIterableElementType(ngForOfType);
        break;
      case 'index':
      case 'count':
        // These locals are always integers.
        variable.dartType = intType(component.analyzedClass);
        break;
      case 'first':
      case 'last':
      case 'even':
      case 'odd':
        // These locals are always booleans.
        variable.dartType = boolType(component.analyzedClass);
        break;
    }
  }
}
