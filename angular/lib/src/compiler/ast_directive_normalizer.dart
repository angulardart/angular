import 'dart:async';

import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

import 'compile_metadata.dart';
import 'expression_parser/visitor.dart';
import 'style_url_resolver.dart' show extractStyleUrls, isStyleUrlResolvable;

/// Loads the content of `templateUrl` and `styleUrls` to normalize directives.
///
/// [CompileDirectiveMetadata] is converted to a normalized form where template
/// content and styles are available to the compilation step as simple strings.
///
/// The normalizer also resolves inline style and stylesheets in the template.
class AstDirectiveNormalizer {
  final NgAssetReader _reader;
  const AstDirectiveNormalizer(this._reader);

  void _parseExpressionsWithLegacyParser(
    ast.TemplateAst astNode,
    List<CompileIdentifierMetadata> exports,
  ) {
    astNode.accept(new LegacyExpressionVisitor(exports: exports));
  }

  Future<CompileDirectiveMetadata> normalizeDirective(
    CompileDirectiveMetadata directive,
  ) {
    // For non-components there is nothing to be normalized yet.
    if (!directive.isComponent) {
      return new Future.value(directive);
    }
    return _normalizeTemplate(
      directive.type,
      directive.template,
      exports: directive.exports,
    ).then((result) {
      return new CompileDirectiveMetadata(
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
        template: result,
        analyzedClass: directive.analyzedClass,
        visibility: directive.visibility,
      );
    });
  }

  Future<CompileTemplateMetadata> _normalizeTemplate(
    CompileTypeMetadata directiveType,
    CompileTemplateMetadata template, {
    List<CompileIdentifierMetadata> exports,
  }) async {
    template ??= new CompileTemplateMetadata(template: '');
    if (template.styles != null && template.styles.isNotEmpty) {
      await _validateStyleUrlsNotMeant(template.styles, directiveType);
    }
    if (template.template != null) {
      await _validateTemplateUrlNotMeant(template.template, directiveType);
      return _normalizeLoadedTemplate(
        directiveType,
        template,
        template.template,
        directiveType.moduleUrl,
        template.preserveWhitespace,
        exports: exports,
      );
    }
    if (template.templateUrl != null) {
      final sourceAbsoluteUrl = _reader.resolveUrl(
        directiveType.moduleUrl,
        template.templateUrl,
      );
      return _reader.readText(sourceAbsoluteUrl).then((templateContent) {
        return _normalizeLoadedTemplate(
          directiveType,
          template,
          templateContent,
          sourceAbsoluteUrl,
          template.preserveWhitespace,
          exports: exports,
        );
      });
    }
    throwFailure(''
        'Component "${directiveType.name}" in \n'
        '${directiveType.moduleUrl}:\n'
        'Requires either a "template" or "templateUrl"; had neither.');
  }

  Future<void> _validateStyleUrlsNotMeant(
    List<String> styles,
    CompileTypeMetadata directiveType,
  ) {
    // Short-circuit.
    if (styles.every((s) => s.contains('\n') || !s.endsWith('.css'))) {
      return new Future.value();
    }
    return Future.wait(
      styles.map((content) {
        return _reader
            .canRead(_reader.resolveUrl(directiveType.moduleUrl, content))
            .then((couldRead) {
          if (couldRead) {
            // TODO: https://github.com/dart-lang/angular/issues/851.
            logWarning('Component "${directiveType.name}" in\n  '
                '${directiveType.moduleUrl}:\n'
                '  Has a "styles" property set to a string that is a file.\n'
                '  This is a common mistake, did you mean "styleUrls" instead?');
          }
        });
      }),
    );
  }

  Future<void> _validateTemplateUrlNotMeant(
    String content,
    CompileTypeMetadata directiveType,
  ) {
    // Short-circuit.
    if (content.contains('\n') || !content.endsWith('.html')) {
      return new Future.value();
    }
    return _reader
        .canRead(_reader.resolveUrl(directiveType.moduleUrl, content))
        .then((couldRead) {
      if (couldRead) {
        // TODO: https://github.com/dart-lang/angular/issues/851.
        logWarning('Component "${directiveType.name}" in\n  '
            '${directiveType.moduleUrl}:\n'
            '  Has a "template" property set to a string that is a file.\n'
            '  This is a common mistake, did you mean "templateUrl" instead?');
      }
    });
  }

  CompileTemplateMetadata _normalizeLoadedTemplate(
    CompileTypeMetadata directiveType,
    CompileTemplateMetadata templateMeta,
    String template,
    String templateAbsUrl,
    bool preserveWhitespace, {
    List<CompileIdentifierMetadata> exports: const [],
  }) {
    // Parse the template, and visit to find <style>/<link> and <ng-content>.
    final visitor = new _TemplateNormalizerVisitor();
    final parsedNodes = ast.parse(
      template,
      // TODO: Use the full-file path when possible.
      // Otherwise, the analyzer crashes today seeing an 'asset:...' URL.
      sourceUrl: Uri.parse(templateAbsUrl).replace(scheme: 'file').toFilePath(),
    );

    for (final node in parsedNodes) {
      node.accept(visitor);
      _parseExpressionsWithLegacyParser(node, exports);
    }

    final allInlineStyles = templateMeta.styles + visitor.inlineStyles;
    final allExternalStyles = <String>[];
    final allResolvedStyles = <String>[];

    // Try to resolve external stylesheets.
    for (final url in visitor.externalStyles) {
      if (isStyleUrlResolvable(url)) {
        allExternalStyles.add(_reader.resolveUrl(templateAbsUrl, url));
      }
    }
    for (final url in templateMeta.styleUrls) {
      if (isStyleUrlResolvable(url)) {
        allExternalStyles.add(_reader.resolveUrl(directiveType.moduleUrl, url));
      }
    }

    // Try to resolve <style> import statements.
    for (final inlineStyle in allInlineStyles) {
      final import = extractStyleUrls(templateAbsUrl, inlineStyle);
      allExternalStyles.addAll(import.styleUrls);
      allResolvedStyles.add(import.style);
    }

    // Optimization: Turn off encapsulation when there are no styles to apply.
    var encapsulation = templateMeta.encapsulation;
    if (encapsulation == ViewEncapsulation.Emulated &&
        allResolvedStyles.isEmpty &&
        allExternalStyles.isEmpty) {
      encapsulation = ViewEncapsulation.None;
    }

    return new CompileTemplateMetadata(
      encapsulation: encapsulation,
      template: template,
      templateUrl: templateAbsUrl,
      styles: allResolvedStyles,
      styleUrls: allExternalStyles,
      ngContentSelectors: visitor.ngContentSelectors,
      preserveWhitespace: preserveWhitespace,
    );
  }
}

class _TemplateNormalizerVisitor extends ast.RecursiveTemplateAstVisitor<Null> {
  final externalStyles = <String>[];
  final inlineStyles = <String>[];
  final ngContentSelectors = <String>[];

  static String _extractAttrValue(ast.ElementAst astNode, String name) =>
      astNode?.attributes
          ?.firstWhere((a) => a.name.toLowerCase() == name, orElse: () => null)
          ?.value;

  static String _extractInnerText(ast.ElementAst astNode) {
    if (astNode.childNodes.isEmpty) {
      return '';
    }
    final firstChild = astNode.childNodes.first;
    if (firstChild is ast.TextAst) {
      return firstChild.value;
    }
    return '';
  }

  @override
  ast.EmbeddedContentAst visitEmbeddedContent(
    ast.EmbeddedContentAst astNode, [
    _,
  ]) {
    ngContentSelectors.add(astNode.selector);
    return astNode;
  }

  @override
  ast.TemplateAst visitElement(ast.ElementAst astNode, [_]) {
    final tagName = astNode.name.toLowerCase();
    switch (tagName) {
      case 'link':
        if (_extractAttrValue(astNode, 'rel')?.toLowerCase() == 'stylesheet') {
          final href = _extractAttrValue(astNode, 'href');
          if (href != null) {
            externalStyles.add(href);
          }
        }
        break;
      case 'style':
        inlineStyles.add(_extractInnerText(astNode));
        break;
    }
    return super.visitElement(astNode);
  }
}
