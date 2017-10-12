import "dart:async";

import "package:angular/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular/src/facade/exceptions.dart" show BaseException;
import "package:angular_compiler/angular_compiler.dart";

import "compile_metadata.dart"
    show CompileTypeMetadata, CompileDirectiveMetadata, CompileTemplateMetadata;
import "html_ast.dart";
import "html_parser.dart" show HtmlParser;
import "style_url_resolver.dart" show extractStyleUrls, isStyleUrlResolvable;
import "template_preparser.dart" show preparseElement;

/// Loads contents of templateUrls, styleUrls to convert
/// CompileDirectiveMetadata into a normalized form where template content and
/// styles are available to compilation step as simple strings.
/// The normalizer also resolves inline style and stylesheets in the template.
class DirectiveNormalizer {
  final HtmlParser _htmlParser;
  final NgAssetReader _reader;

  DirectiveNormalizer(this._htmlParser, this._reader);

  Future<CompileDirectiveMetadata> normalizeDirective(
      CompileDirectiveMetadata directive) {
    if (!directive.isComponent) {
      // For non components there is nothing to be normalized yet.
      return new Future.value(directive);
    }
    return normalizeTemplate(directive.type, directive.template).then(
        (CompileTemplateMetadata normalizedTemplate) =>
            new CompileDirectiveMetadata(
              type: directive.type,
              metadataType: directive.metadataType,
              selector: directive.selector,
              exportAs: directive.exportAs,
              changeDetection: directive.changeDetection,
              inputs: directive.inputs,
              inputTypes: directive.inputTypes,
              outputs: directive.outputs,
              hostListeners: directive.hostListeners,
              hostProperties: directive.hostProperties,
              hostAttributes: directive.hostAttributes,
              lifecycleHooks: directive.lifecycleHooks,
              providers: directive.providers,
              viewProviders: directive.viewProviders,
              exports: directive.exports,
              queries: directive.queries,
              viewQueries: directive.viewQueries,
              template: normalizedTemplate,
              analyzedClass: directive.analyzedClass,
              visibility: directive.visibility,
            ));
  }

  Future<CompileTemplateMetadata> normalizeTemplate(
    CompileTypeMetadata directiveType,
    CompileTemplateMetadata template,
  ) {
    // This emulates the same behavior for interpreted mode, that is, that
    // omitting either template: or templateUrl: results in an empty template.
    template ??= new CompileTemplateMetadata(template: '');
    if (template.template != null) {
      return new Future.value(normalizeLoadedTemplate(
          directiveType,
          template,
          template.template,
          directiveType.moduleUrl,
          template.preserveWhitespace));
    } else if (template.templateUrl != null) {
      var sourceAbsUrl = this
          ._reader
          .resolveUrl(directiveType.moduleUrl, template.templateUrl);
      return this._reader.readText(sourceAbsUrl).then((templateContent) => this
          .normalizeLoadedTemplate(directiveType, template, templateContent,
              sourceAbsUrl, template.preserveWhitespace));
    } else {
      throw new BaseException(
          'No template specified for component ${directiveType.name}');
    }
  }

  CompileTemplateMetadata normalizeLoadedTemplate(
      CompileTypeMetadata directiveType,
      CompileTemplateMetadata templateMeta,
      String template,
      String templateAbsUrl,
      bool preserveWhitespace) {
    var rootNodesAndErrors = _htmlParser.parse(template, directiveType.name);
    if (rootNodesAndErrors.errors.isNotEmpty) {
      var errorString = rootNodesAndErrors.errors.join('\n');
      throw new BaseException('Template parse errors: $errorString');
    }
    var visitor = new TemplatePreparseVisitor();
    htmlVisitAll(visitor, rootNodesAndErrors.rootNodes);
    List<String> allStyles =
        (new List.from(templateMeta.styles)..addAll(visitor.styles));
    List<String> allStyleAbsUrls = (new List.from(visitor.styleUrls
        .where(isStyleUrlResolvable)
        .toList()
        .map((url) => _reader.resolveUrl(templateAbsUrl, url))
        .toList())
      ..addAll(templateMeta.styleUrls
          .where(isStyleUrlResolvable)
          .toList()
          .map((url) => _reader.resolveUrl(directiveType.moduleUrl, url))
          .toList()));
    var allResolvedStyles = allStyles.map((style) {
      var styleWithImports = extractStyleUrls(templateAbsUrl, style);
      styleWithImports.styleUrls
          .forEach((styleUrl) => allStyleAbsUrls.add(styleUrl));
      return styleWithImports.style;
    }).toList();

    // Optimization: Turn off encapsulation if there are no resolved styles or
    // absolute urls in the template definition to shim at runtime.
    var encapsulation = templateMeta.encapsulation;
    if (identical(encapsulation, ViewEncapsulation.Emulated) &&
        identical(allResolvedStyles.length, 0) &&
        identical(allStyleAbsUrls.length, 0)) {
      encapsulation = ViewEncapsulation.None;
    }
    return new CompileTemplateMetadata(
        encapsulation: encapsulation,
        template: template,
        templateUrl: templateAbsUrl,
        styles: allResolvedStyles,
        styleUrls: allStyleAbsUrls,
        ngContentSelectors: visitor.ngContentSelectors,
        preserveWhitespace: preserveWhitespace);
  }
}

/// Extracts a list of inline styles, stylesheet links and content selectors
/// from a template to use for normalization of templates.
class TemplatePreparseVisitor implements HtmlAstVisitor<Null, Null> {
  List<String> ngContentSelectors = [];
  List<String> styles = [];
  List<String> styleUrls = [];
  int inLiteralHtmlArea = 0;

  @override
  bool visit(HtmlAst ast, dynamic context) => false;

  @override
  Null visitElement(HtmlElementAst ast, Null _) {
    var preparsedElement = preparseElement(ast);
    if (preparsedElement.isNgContent) {
      if (inLiteralHtmlArea == 0) {
        ngContentSelectors.add(preparsedElement.selectAttr);
      }
    } else if (preparsedElement.isStyle) {
      final sb = new StringBuffer();
      for (var child in ast.children) {
        if (child is HtmlTextAst) {
          sb.write(child.value);
        }
      }
      styles.add(sb.toString());
    } else if (preparsedElement.isStyleSheet) {
      styleUrls.add(preparsedElement.hrefAttr);
    } else {
      // DDC reports this as error. See:
      // https://github.com/dart-lang/dev_compiler/issues/428
    }
    if (preparsedElement.nonBindable) {
      inLiteralHtmlArea++;
    }
    htmlVisitAll(this, ast.children);
    if (preparsedElement.nonBindable) {
      inLiteralHtmlArea--;
    }
    return null;
  }

  @override
  Null visitComment(HtmlCommentAst _, Null __) {
    return null;
  }

  @override
  Null visitAttr(HtmlAttrAst _, Null __) {
    return null;
  }

  @override
  Null visitText(HtmlTextAst _, Null __) {
    return null;
  }
}
