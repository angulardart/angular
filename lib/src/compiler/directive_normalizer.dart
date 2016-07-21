import "dart:async";

import "package:angular2/src/compiler/url_resolver.dart" show UrlResolver;
import "package:angular2/src/compiler/xhr.dart" show XHR;
import "package:angular2/src/core/di.dart" show Injectable;
import "package:angular2/src/core/metadata/view.dart" show ViewEncapsulation;
import "package:angular2/src/facade/async.dart" show PromiseWrapper;
import "package:angular2/src/facade/exceptions.dart" show BaseException;

import "compile_metadata.dart"
    show CompileTypeMetadata, CompileDirectiveMetadata, CompileTemplateMetadata;
import "html_ast.dart"
    show
        HtmlAstVisitor,
        HtmlElementAst,
        HtmlTextAst,
        HtmlAttrAst,
        HtmlCommentAst,
        HtmlExpansionAst,
        HtmlExpansionCaseAst,
        htmlVisitAll;
import "html_parser.dart" show HtmlParser;
import "style_url_resolver.dart" show extractStyleUrls, isStyleUrlResolvable;
import "template_preparser.dart" show preparseElement, PreparsedElementType;

@Injectable()
class DirectiveNormalizer {
  XHR _xhr;
  UrlResolver _urlResolver;
  HtmlParser _htmlParser;
  DirectiveNormalizer(this._xhr, this._urlResolver, this._htmlParser) {}
  Future<CompileDirectiveMetadata> normalizeDirective(
      CompileDirectiveMetadata directive) {
    if (!directive.isComponent) {
      // For non components there is nothing to be normalized yet.
      return PromiseWrapper.resolve(directive);
    }
    return this.normalizeTemplate(directive.type, directive.template).then(
        (CompileTemplateMetadata normalizedTemplate) =>
            new CompileDirectiveMetadata(
                type: directive.type,
                isComponent: directive.isComponent,
                selector: directive.selector,
                exportAs: directive.exportAs,
                changeDetection: directive.changeDetection,
                inputs: directive.inputs,
                outputs: directive.outputs,
                hostListeners: directive.hostListeners,
                hostProperties: directive.hostProperties,
                hostAttributes: directive.hostAttributes,
                lifecycleHooks: directive.lifecycleHooks,
                providers: directive.providers,
                viewProviders: directive.viewProviders,
                queries: directive.queries,
                viewQueries: directive.viewQueries,
                template: normalizedTemplate));
  }

  Future<CompileTemplateMetadata> normalizeTemplate(
      CompileTypeMetadata directiveType, CompileTemplateMetadata template) {
    if (template.template != null) {
      return PromiseWrapper.resolve(this.normalizeLoadedTemplate(
          directiveType,
          template,
          template.template,
          directiveType.moduleUrl,
          template.preserveWhitespace));
    } else if (template.templateUrl != null) {
      var sourceAbsUrl = this
          ._urlResolver
          .resolve(directiveType.moduleUrl, template.templateUrl);
      return this._xhr.get(sourceAbsUrl).then((templateContent) => this
          .normalizeLoadedTemplate(directiveType, template, templateContent,
              sourceAbsUrl, template.preserveWhitespace));
    } else {
      throw new BaseException(
          '''No template specified for component ${ directiveType . name}''');
    }
  }

  CompileTemplateMetadata normalizeLoadedTemplate(
      CompileTypeMetadata directiveType,
      CompileTemplateMetadata templateMeta,
      String template,
      String templateAbsUrl,
      bool preserveWhitespace) {
    var rootNodesAndErrors =
        this._htmlParser.parse(template, directiveType.name);
    if (rootNodesAndErrors.errors.length > 0) {
      var errorString = rootNodesAndErrors.errors.join("\n");
      throw new BaseException('Template parse errors: '
          '${ errorString}');
    }
    var visitor = new TemplatePreparseVisitor();
    htmlVisitAll(visitor, rootNodesAndErrors.rootNodes);
    List<String> allStyles =
        (new List.from(templateMeta.styles)..addAll(visitor.styles));
    List<String> allStyleAbsUrls = (new List.from(visitor.styleUrls
        .where(isStyleUrlResolvable)
        .toList()
        .map((url) => this._urlResolver.resolve(templateAbsUrl, url))
        .toList())
      ..addAll(templateMeta.styleUrls
          .where(isStyleUrlResolvable)
          .toList()
          .map((url) => this._urlResolver.resolve(directiveType.moduleUrl, url))
          .toList()));
    var allResolvedStyles = allStyles.map((style) {
      var styleWithImports =
          extractStyleUrls(this._urlResolver, templateAbsUrl, style);
      styleWithImports.styleUrls
          .forEach((styleUrl) => allStyleAbsUrls.add(styleUrl));
      return styleWithImports.style;
    }).toList();
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

class TemplatePreparseVisitor implements HtmlAstVisitor {
  List<String> ngContentSelectors = [];
  List<String> styles = [];
  List<String> styleUrls = [];
  num ngNonBindableStackCount = 0;
  dynamic visitElement(HtmlElementAst ast, dynamic context) {
    var preparsedElement = preparseElement(ast);
    switch (preparsedElement.type) {
      case PreparsedElementType.NG_CONTENT:
        if (identical(this.ngNonBindableStackCount, 0)) {
          this.ngContentSelectors.add(preparsedElement.selectAttr);
        }
        break;
      case PreparsedElementType.STYLE:
        var textContent = "";
        ast.children.forEach((child) {
          if (child is HtmlTextAst) {
            textContent += child.value;
          }
        });
        styles.add(textContent);
        break;
      case PreparsedElementType.STYLESHEET:
        styleUrls.add(preparsedElement.hrefAttr);
        break;
      default:
        // DDC reports this as error. See:

        // https://github.com/dart-lang/dev_compiler/issues/428
        break;
    }
    if (preparsedElement.nonBindable) {
      this.ngNonBindableStackCount++;
    }
    htmlVisitAll(this, ast.children);
    if (preparsedElement.nonBindable) {
      this.ngNonBindableStackCount--;
    }
    return null;
  }

  dynamic visitComment(HtmlCommentAst ast, dynamic context) {
    return null;
  }

  dynamic visitAttr(HtmlAttrAst ast, dynamic context) {
    return null;
  }

  dynamic visitText(HtmlTextAst ast, dynamic context) {
    return null;
  }

  dynamic visitExpansion(HtmlExpansionAst ast, dynamic context) {
    return null;
  }

  dynamic visitExpansionCase(HtmlExpansionCaseAst ast, dynamic context) {
    return null;
  }
}
