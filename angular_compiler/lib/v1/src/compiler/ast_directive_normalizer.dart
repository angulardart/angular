import 'package:angular/src/meta.dart';
import 'package:angular_ast/angular_ast.dart' as ast;
import 'package:angular_compiler/v1/angular_compiler.dart';
import 'package:angular_compiler/v1/cli.dart';
import 'package:angular_compiler/v2/context.dart';

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
  ) async {
    if (!directive.isComponent) {
      return directive;
    }
    return CompileDirectiveMetadata.from(
      directive,
      template: await _normalizeTemplate(
        directive.type!,
        directive.template,
      ),
    );
  }

  Future<CompileTemplateMetadata> _normalizeTemplate(
    CompileTypeMetadata directiveType,
    CompileTemplateMetadata? template,
  ) async {
    template ??= CompileTemplateMetadata(template: '');
    if (template.styles.isNotEmpty) {
      await _validateStyleUrlsNotMeant(template.styles, directiveType);
    }
    var inlineTemplate = template.template;
    if (inlineTemplate != null) {
      await _validateTemplateUrlNotMeant(inlineTemplate, directiveType);
      return _normalizeLoadedTemplate(
        directiveType,
        template,
        inlineTemplate,
        directiveType.moduleUrl!,
      );
    }
    var templateUrl = template.templateUrl;
    if (templateUrl != null) {
      final sourceAbsoluteUrl = _reader.resolveUrl(
        directiveType.moduleUrl!,
        templateUrl,
      );
      return _normalizeLoadedTemplate(
        directiveType,
        template,
        await _readTextOrThrow(sourceAbsoluteUrl, directiveType),
        sourceAbsoluteUrl,
      );
    }
    throw BuildError.withoutContext(
      'Component "${directiveType.name}" in \n'
      '${directiveType.moduleUrl}:\n'
      'Requires either a "template" or "templateUrl"; had neither.',
    );
  }

  Future<String> _readTextOrThrow(
    String sourceAbsoluteUrl,
    CompileTypeMetadata directiveType,
  ) async {
    try {
      return await _reader.readText(sourceAbsoluteUrl);
    } catch (e) {
      throw BuildError.withoutContext(
        'Component "${directiveType.name}" in \n'
        '${directiveType.moduleUrl}:\n'
        'Failed to read templateUrl $sourceAbsoluteUrl.\n'
        'Ensure the file exists on disk and is available to the compiler.',
      );
    }
  }

  Future<void> _validateStyleUrlsNotMeant(
    List<String> styles,
    CompileTypeMetadata directiveType,
  ) async {
    // Short-circuit.
    if (styles.every((s) => s.contains('\n') || !s.endsWith('.css'))) {
      return;
    }
    await Future.wait(
      styles.map((content) async {
        final canRead = await _reader.canRead(
          _reader.resolveUrl(directiveType.moduleUrl!, content),
        );
        if (canRead) {
          logWarning(
            'Component "${directiveType.name}" in\n  '
            '${directiveType.moduleUrl}:\n'
            '  Has a "styles" property set to a string that is a file.\n'
            '  This is a common mistake, did you mean "styleUrls" instead?',
          );
        }
      }),
    );
  }

  Future<void> _validateTemplateUrlNotMeant(
    String content,
    CompileTypeMetadata directiveType,
  ) async {
    // Short-circuit.
    if (content.contains('\n') || !content.endsWith('.html')) {
      return;
    }
    final canRead = await _reader.canRead(
      _reader.resolveUrl(directiveType.moduleUrl!, content),
    );
    if (canRead) {
      logWarning(
        'Component "${directiveType.name}" in\n  '
        '${directiveType.moduleUrl}:\n'
        '  Has a "template" property set to a string that is a file.\n'
        '  This is a common mistake, did you mean "templateUrl" instead?',
      );
    }
  }

  CompileTemplateMetadata _normalizeLoadedTemplate(
    CompileTypeMetadata directiveType,
    CompileTemplateMetadata templateMeta,
    String template,
    String templateAbsUrl,
  ) {
    // TODO(alorenzen): Remove need to parse template here.
    // We should be able to calculate this in the main parse.
    final ngContentSelectors = _parseTemplate(
      template,
      directiveType,
      templateAbsUrl,
    );

    final allExternalStyles = _resolveExternalStylesheets(
      templateMeta,
      directiveType.moduleUrl!,
    );

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
      templateOffset: templateMeta.templateOffset,
      styles: templateMeta.styles,
      styleUrls: allExternalStyles,
      ngContentSelectors: ngContentSelectors,
      preserveWhitespace: templateMeta.preserveWhitespace,
    );
  }

  List<String> _resolveExternalStylesheets(
    CompileTemplateMetadata templateMeta,
    String moduleUrl,
  ) {
    return [
      for (final url in templateMeta.styleUrls)
        if (isStyleUrlResolvable(url))
          _reader.resolveUrl(moduleUrl, url)
        else
          throw BuildError.withoutContext(
            'Invalid Style URL: "$url" (from "$moduleUrl").',
          )
    ];
  }

  /// Parse the template, and visit to find <ng-content>.
  List<String> _parseTemplate(
    String template,
    CompileTypeMetadata directiveType,
    String templateAbsUrl,
  ) {
    final exceptionHandler = AstExceptionHandler(
      template,
      templateAbsUrl,
      directiveType.name,
    );
    final parsedNodes = ast.parse(
      template,
      // TODO: Use the full-file path when possible.
      // Otherwise, the analyzer crashes today seeing an 'asset:...' URL.
      sourceUrl: Uri.parse(templateAbsUrl).replace(scheme: 'file').toFilePath(),
      exceptionHandler: exceptionHandler,
      desugar: false,
    );
    exceptionHandler.throwErrorsIfAny();
    final visitor = _FindAllNgContentSelectors();
    for (final node in parsedNodes) {
      node.accept(visitor);
    }
    return visitor.ngContentSelectors;
  }
}

class _FindAllNgContentSelectors extends ast.RecursiveTemplateAstVisitor<void> {
  final ngContentSelectors = <String>[];

  @override
  ast.EmbeddedContentAst visitEmbeddedContent(
    ast.EmbeddedContentAst astNode, [
    _,
  ]) {
    final selector = astNode.selector;
    if (selector == null) {
      throw BuildError.forSourceSpan(
        astNode.sourceSpan,
        'The "select" attribute must have a value or be omitted',
      );
    }
    ngContentSelectors.add(selector);
    return astNode;
  }
}
