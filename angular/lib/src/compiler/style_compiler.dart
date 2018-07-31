import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import 'package:angular_compiler/cli.dart';

import "compile_metadata.dart"
    show CompileIdentifierMetadata, CompileDirectiveMetadata;
import 'compiler_utils.dart';
import "output/output_ast.dart" as o;
import "shadow_css.dart";
import "style_url_resolver.dart" show extractStyleUrls;

/// This placeholder is replaced by the component ID at run-time.
const _componentIdPlaceholder = '%ID%';

/// This CSS class is used to apply styles to a component's host element.
const _hostClass = '_nghost-$_componentIdPlaceholder';

/// This CSS class is used to encapsulate styles within a component's view.
const _viewClass = '_ngcontent-$_componentIdPlaceholder';

class StylesCompileResult {
  final List<o.Statement> statements;
  final String stylesVar;
  final bool usesHostAttribute;
  final bool usesContentAttribute;
  StylesCompileResult(this.statements, this.stylesVar, this.usesHostAttribute,
      this.usesContentAttribute);
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
    return this._compileStyles(_getStylesVarName(comp), comp.template.styles,
        comp.template.styleUrls, requiresShim);
  }

  StylesCompileResult compileStylesheet(
      String stylesheetUrl, String cssText, bool isShimmed) {
    var styleWithImports = extractStyleUrls(stylesheetUrl, cssText);
    return this._compileStyles(_getStylesVarName(), [styleWithImports.style],
        styleWithImports.styleUrls, isShimmed);
  }

  StylesCompileResult _compileStyles(
    String stylesVar,
    List<String> styles,
    List<String> styleUrls,
    bool shim,
  ) {
    final styleExpressions = <o.Expression>[];

    /// Add URLs from @import statements first.
    for (final url in styleUrls) {
      final identifier = CompileIdentifierMetadata(
        name: _getStylesVarName(),
        moduleUrl: stylesModuleUrl(url, shim),
      );
      styleExpressions.add(o.ExternalExpr(identifier));
    }

    /// Add contents of style sheet after @import statements. This allows an
    /// imported style to be overriden after its @import statement.
    for (final style in styles) {
      styleExpressions.add(o.literal(_shimIfNeeded(style, shim)));
    }

    // Styles variable contains plain strings and arrays of other styles arrays
    // (recursive), so we set its type to dynamic.
    final listShouldBeConst = styleExpressions.isEmpty;
    final statement = o
        .variable(stylesVar)
        .set(o.literalArr(
            styleExpressions,
            o.ArrayType(
              o.DYNAMIC_TYPE,
              listShouldBeConst ? [o.TypeModifier.Const] : const [],
            )))
        .toDeclStmt(
      null,
      [o.StmtModifier.Final],
    );
    return StylesCompileResult(
      [statement],
      stylesVar,
      usesHostAttribute,
      usesContentAttribute,
    );
  }

  String _shimIfNeeded(String style, bool shim) {
    String result = shim
        ? shimShadowCss(style, _viewClass, _hostClass,
            useLegacyEncapsulation: _config.useLegacyStyleEncapsulation)
        : style;
    if (result.contains(_viewClass)) {
      usesContentAttribute = true;
    }
    if (result.contains(_hostClass)) {
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
String _getStylesVarName([CompileDirectiveMetadata component]) =>
    component != null ? 'styles\$${component.type.name}' : 'styles';
