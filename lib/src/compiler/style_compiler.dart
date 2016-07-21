import "package:angular2/src/compiler/shadow_css.dart" show ShadowCss;
import "package:angular2/src/compiler/url_resolver.dart" show UrlResolver;
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/facade/lang.dart" show isPresent;

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileDirectiveMetadata;
import "output/output_ast.dart" as o;
import "style_url_resolver.dart" show extractStyleUrls;

const COMPONENT_VARIABLE = "%COMP%";
final HOST_ATTR = '''_nghost-${ COMPONENT_VARIABLE}''';
final CONTENT_ATTR = '''_ngcontent-${ COMPONENT_VARIABLE}''';

class StylesCompileDependency {
  String sourceUrl;
  bool isShimmed;
  CompileIdentifierMetadata valuePlaceholder;
  StylesCompileDependency(
      this.sourceUrl, this.isShimmed, this.valuePlaceholder) {}
}

class StylesCompileResult {
  List<o.Statement> statements;
  String stylesVar;
  List<StylesCompileDependency> dependencies;
  StylesCompileResult(this.statements, this.stylesVar, this.dependencies) {}
}

@Injectable()
class StyleCompiler {
  UrlResolver _urlResolver;
  ShadowCss _shadowCss = new ShadowCss();
  StyleCompiler(this._urlResolver) {}
  StylesCompileResult compileComponent(CompileDirectiveMetadata comp) {
    var shim =
        identical(comp.template.encapsulation, ViewEncapsulation.Emulated);
    return this._compileStyles(getStylesVarName(comp), comp.template.styles,
        comp.template.styleUrls, shim);
  }

  StylesCompileResult compileStylesheet(
      String stylesheetUrl, String cssText, bool isShimmed) {
    var styleWithImports =
        extractStyleUrls(this._urlResolver, stylesheetUrl, cssText);
    return this._compileStyles(getStylesVarName(null), [styleWithImports.style],
        styleWithImports.styleUrls, isShimmed);
  }

  StylesCompileResult _compileStyles(String stylesVar, List<String> plainStyles,
      List<String> absUrls, bool shim) {
    List<o.Expression> styleExpressions = <o.Expression>[];
    int styleCount = plainStyles.length;
    for (int s = 0; s < styleCount; s++) {
      styleExpressions.add(o.literal(this._shimIfNeeded(plainStyles[s], shim)));
    }
    var dependencies = <StylesCompileDependency>[];
    for (var i = 0; i < absUrls.length; i++) {
      var identifier =
          new CompileIdentifierMetadata(name: getStylesVarName(null));
      dependencies
          .add(new StylesCompileDependency(absUrls[i], shim, identifier));
      styleExpressions.add(new o.ExternalExpr(identifier));
    }
    // styles variable contains plain strings and arrays of other styles arrays (recursive),

    // so we set its type to dynamic.
    var stmt = o
        .variable(stylesVar)
        .set(o.literalArr(styleExpressions,
            new o.ArrayType(o.DYNAMIC_TYPE, [o.TypeModifier.Const])))
        .toDeclStmt(null, [o.StmtModifier.Final]);
    return new StylesCompileResult([stmt], stylesVar, dependencies);
  }

  String _shimIfNeeded(String style, bool shim) {
    return shim
        ? this._shadowCss.shimCssText(style, CONTENT_ATTR, HOST_ATTR)
        : style;
  }
}

String getStylesVarName(CompileDirectiveMetadata component) {
  var result = '''styles''';
  if (isPresent(component)) {
    result += '''_${ component . type . name}''';
  }
  return result;
}
