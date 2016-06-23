library angular2.src.compiler.view_compiler.view_compiler;

import "package:angular2/src/core/di.dart" show Injectable;
import "../output/output_ast.dart" as o;
import "compile_element.dart" show CompileElement;
import "compile_view.dart" show CompileView;
import "view_builder.dart" show buildView, finishView, ViewCompileDependency;
import "view_binder.dart" show bindView;
import "../compile_metadata.dart"
    show CompileDirectiveMetadata, CompilePipeMetadata;
import "../template_ast.dart" show TemplateAst;
import "../config.dart" show CompilerConfig;

class ViewCompileResult {
  List<o.Statement> statements;
  String viewFactoryVar;
  List<ViewCompileDependency> dependencies;
  ViewCompileResult(this.statements, this.viewFactoryVar, this.dependencies) {}
}

@Injectable()
class ViewCompiler {
  CompilerConfig _genConfig;
  ViewCompiler(this._genConfig) {}
  ViewCompileResult compileComponent(
      CompileDirectiveMetadata component,
      List<TemplateAst> template,
      o.Expression styles,
      List<CompilePipeMetadata> pipes) {
    var statements = [];
    var dependencies = [];
    var view = new CompileView(component, this._genConfig, pipes, styles, 0,
        CompileElement.createNull(), []);
    buildView(view, template, dependencies);
    // Need to separate binding from creation to be able to refer to

    // variables that have been declared after usage.
    bindView(view, template);
    finishView(view, statements);
    return new ViewCompileResult(
        statements, view.viewFactory.name, dependencies);
  }
}
