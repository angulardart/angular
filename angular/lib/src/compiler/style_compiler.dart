import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:angular_compiler/cli.dart';

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileDirectiveMetadata;
import "output/output_ast.dart" as o;
import "shadow_css.dart";
import "style_url_resolver.dart" show extractStyleUrls;

const COMPONENT_VARIABLE = "%COMP%";
final HOST_ATTR_PREFIX = '_nghost-';
final HOST_ATTR = '$HOST_ATTR_PREFIX$COMPONENT_VARIABLE';
final CONTENT_ATTR_PREFIX = '_ngcontent-';
final CONTENT_ATTR = '$CONTENT_ATTR_PREFIX$COMPONENT_VARIABLE';

class StylesCompileDependency {
  String sourceUrl;
  bool isShimmed;
  CompileIdentifierMetadata valuePlaceholder;
  StylesCompileDependency(
      this.sourceUrl, this.isShimmed, this.valuePlaceholder);
}

class StylesCompileResult {
  final List<o.Statement> statements;
  final String stylesVar;
  final List<StylesCompileDependency> dependencies;
  final bool usesHostAttribute;
  final bool usesContentAttribute;
  StylesCompileResult(this.statements, this.stylesVar, this.dependencies,
      this.usesHostAttribute, this.usesContentAttribute);
}

class StyleCompiler {
  final CompilerFlags _config;

  bool usesContentAttribute;
  bool usesHostAttribute;

  StyleCompiler(this._config);

  /// Compile styles to a set of statements that will initialize the global
  /// styles_ComponentName variable that will be passed to component factory.
  ///
  /// [comp.template.styles] contains a list of inline styles (or overrides in
  /// tests) and [comp.template.styleUrls] contains urls to other css.shim.dart
  /// resources.
  StylesCompileResult compileComponent(CompileDirectiveMetadata comp) {
    usesContentAttribute = false;
    usesHostAttribute = false;
    var requiresShim =
        comp.template.encapsulation == ViewEncapsulation.Emulated;
    return this._compileStyles(getStylesVarName(comp), comp.template.styles,
        comp.template.styleUrls, requiresShim);
  }

  StylesCompileResult compileStylesheet(
      String stylesheetUrl, String cssText, bool isShimmed) {
    var styleWithImports = extractStyleUrls(stylesheetUrl, cssText);
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

    // Styles variable contains plain strings and arrays of other styles arrays
    // (recursive), so we set its type to dynamic.
    var stmt = o
        .variable(stylesVar)
        .set(o.literalArr(styleExpressions,
            new o.ArrayType(o.DYNAMIC_TYPE, [o.TypeModifier.Const])))
        .toDeclStmt(null, [o.StmtModifier.Const]);
    return new StylesCompileResult([stmt], stylesVar, dependencies,
        usesHostAttribute, usesContentAttribute);
  }

  String _shimIfNeeded(String style, bool shim) {
    String result = shim
        ? shimShadowCss(style, CONTENT_ATTR, HOST_ATTR,
            useLegacyEncapsulation: _config.useLegacyStyleEncapsulation)
        : style;
    if (result.contains(CONTENT_ATTR_PREFIX)) {
      usesContentAttribute = true;
    }
    if (result.contains(HOST_ATTR_PREFIX)) {
      usesHostAttribute = true;
    }
    return result;
  }
}

/// Returns variable name to use to access styles for a particular component
/// type.
///
/// Styles are assigned to style_componentTypeName variables and
/// passed onto ViewUtils.createRenderComponentType for creating the prototype.
String getStylesVarName(CompileDirectiveMetadata component) =>
    component != null ? 'styles\$${component.type.name}' : 'styles';
