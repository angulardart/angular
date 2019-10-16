import 'dart:async';

import 'package:angular/src/core/metadata/view.dart' show ViewEncapsulation;
import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:angular_compiler/angular_compiler.dart';
import 'package:angular_compiler/cli.dart';

import 'compile_metadata.dart';
import 'parse_util.dart';
import 'style_url_resolver.dart' show isStyleUrlResolvable;

/// Loads the content of `templateUrl` and `styleUrls` to normalize directives.
///
/// [CompileDirectiveMetadata] is converted to a normalized form where template
/// content and styles are available to the compilation step as simple strings.
class AstDirectiveNormalizer {
  final NgAssetReader _reader;
  const AstDirectiveNormalizer(this._reader);

  Future<CompileDirectiveMetadata> normalizeDirective(
    CompileDirectiveMetadata directive,
  ) {
    // For non-components there is nothing to be normalized yet.
    if (!directive.isComponent) {
      return Future.value(directive);
    }
    return _normalizeTemplate(
      directive.type,
      directive.template,
    ).then((result) {
      return CompileDirectiveMetadata.from(directive, template: result);
    });
  }

  Future<CompileTemplateMetadata> _normalizeTemplate(
      CompileTypeMetadata directiveType,
      CompileTemplateMetadata template) async {
    template ??= CompileTemplateMetadata(template: '');
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
      );
    }
    if (template.templateUrl != null) {
      final sourceAbsoluteUrl = _reader.resolveUrl(
        directiveType.moduleUrl,
        template.templateUrl,
      );
      final templateContent =
          await _readTextOrThrow(sourceAbsoluteUrl, directiveType);
      return _normalizeLoadedTemplate(
        directiveType,
        template,
        templateContent,
        sourceAbsoluteUrl,
      );
    }
    throwFailure(''
        'Component "${directiveType.name}" in \n'
        '${directiveType.moduleUrl}:\n'
        'Requires either a "template" or "templateUrl"; had neither.');
  }

  Future<String> _readTextOrThrow(
      String sourceAbsoluteUrl, CompileTypeMetadata directiveType) async {
    try {
      return await _reader.readText(sourceAbsoluteUrl);
    } catch (e) {
      throwFailure(''
          'Component "${directiveType.name}" in \n'
          '${directiveType.moduleUrl}:\n'
          'Failed to read templateUrl $sourceAbsoluteUrl.\n'
          'Ensure the file exists on disk and is available to the compiler.');
    }
  }

  Future<void> _validateStyleUrlsNotMeant(
    List<String> styles,
    CompileTypeMetadata directiveType,
  ) {
    // Short-circuit.
    if (styles.every((s) => s.contains('\n') || !s.endsWith('.css'))) {
      return Future.value();
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
      return Future.value();
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
      String templateAbsUrl) {
    // TODO(alorenzen): Remove need to parse template here.
    // We should be able to calculate this in the main parse.
    var ngContentSelectors =
        _parseTemplate(template, directiveType, templateAbsUrl);

    List<String> allExternalStyles =
        _resolveExternalStylesheets(templateMeta, directiveType.moduleUrl);

    // Optimization: Turn off encapsulation when there are no styles to apply.
    var encapsulation = templateMeta.encapsulation;
    if (encapsulation == ViewEncapsulation.Emulated &&
        templateMeta.styles.isEmpty &&
        allExternalStyles.isEmpty) {
      encapsulation = ViewEncapsulation.None;
    }

    return CompileTemplateMetadata(
      encapsulation: encapsulation,
      template: template,
      templateUrl: templateAbsUrl,
      styles: templateMeta.styles,
      styleUrls: allExternalStyles,
      ngContentSelectors: ngContentSelectors,
      preserveWhitespace: templateMeta.preserveWhitespace,
    );
  }

  List<String> _resolveExternalStylesheets(
      CompileTemplateMetadata templateMeta, String moduleUrl) {
    final allExternalStyles = <String>[];

    // Try to resolve external stylesheets.
    for (final url in templateMeta.styleUrls) {
      if (isStyleUrlResolvable(url)) {
        allExternalStyles.add(_reader.resolveUrl(moduleUrl, url));
      } else {
        throwFailure('Invalid Style URL: "$url" (from "$moduleUrl").');
      }
    }
    return allExternalStyles;
  }

  /// Parse the template, and visit to find <ng-content>.
  List<String> _parseTemplate(String template,
      CompileTypeMetadata directiveType, String templateAbsUrl) {
    final exceptionHandler = AstExceptionHandler(template, templateAbsUrl);
    final parsedNodes = ast.parse(
      template,
      // TODO: Use the full-file path when possible.
      // Otherwise, the analyzer crashes today seeing an 'asset:...' URL.
      sourceUrl: Uri.parse(templateAbsUrl).replace(scheme: 'file').toFilePath(),
      exceptionHandler: exceptionHandler,
      desugar: false,
    );
    exceptionHandler.maybeReportExceptions();

    final visitor = _TemplateNormalizerVisitor();
    for (final node in parsedNodes) {
      node.accept(visitor);
    }
    return visitor.ngContentSelectors;
  }
}

class _TemplateNormalizerVisitor extends ast.RecursiveTemplateAstVisitor<Null> {
  final ngContentSelectors = <String>[];

  @override
  ast.EmbeddedContentAst visitEmbeddedContent(
    ast.EmbeddedContentAst astNode, [
    _,
  ]) {
    ngContentSelectors.add(astNode.selector);
    return astNode;
  }
}
