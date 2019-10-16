// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:source_span/source_span.dart';

import 'ast.dart';
import 'exception_handler/exception_handler.dart';
import 'lexer.dart';
import 'parser/recursive.dart';
import 'visitor.dart';

class NgParser {
  // Elements that explicitly don't have a closing tag.
  //
  // https://www.w3.org/TR/html/syntax.html#void-elements
  static const _voidElements = <String>[
    'area',
    'base',
    'br',
    'col',
    'command',
    'embed',
    'hr',
    'img',
    'input',
    'keygen',
    'link',
    'meta',
    'param',
    'source',
    'track',
    'wbr',
  ];

  // SVG is pure html; all tags can be used with or without void syntax. We
  // already parse closer to XML than HTML, so we simply need to accept these
  // tags in <closed></closed> and <unclosed /> forms, which is simpler than
  // dropping into an xml parser for svgs, and better for error recovery.
  //
  // https://developer.mozilla.org/en-US/docs/Web/SVG/Element
  //
  // Some tags (a, script) overlap with HTML. Exclude those, to prefer correct
  // HTML semantics to correct SVG semantics.
  static const _svgElements = <String>[
    // 'a', Exclude this because it's also HTML
    'altGlyph',
    'altGlyphDef',
    'altGlyphItem',
    'animate',
    'animateColor',
    'animateMotion',
    'animateTransform',
    // 'audio', Exclude this because it's also HTML
    // 'canvas', Exclude this because it's also HTML
    'circle',
    'clipPath',
    'color-profile',
    'cursor',
    'defs',
    'desc',
    'discard',
    'ellipse',
    'feBlend',
    'feColorMatrix',
    'feComponentTransfer',
    'feComposite',
    'feConvolveMatrix',
    'feDiffuseLighting',
    'feDisplacementMap',
    'feDistantLight',
    'feDropShadow',
    'feFlood',
    'feFuncA',
    'feFuncB',
    'feFuncG',
    'feFuncR',
    'feGaussianBlur',
    'feImage',
    'feMerge',
    'feMergeNode',
    'feMorphology',
    'feOffset',
    'fePointLight',
    'feSpecularLighting',
    'feSpotLight',
    'feTile',
    'feTurbulence',
    'filter',
    // 'font', Exclude this because it's also HTML
    'font-face',
    'font-face-format',
    'font-face-name',
    'font-face-src',
    'font-face-uri',
    'foreignObject',
    'g',
    'glyph',
    'glyphRef',
    'hatch',
    'hatchpath',
    'hkern',
    // 'iframe', Exclude this because it's also HTML
    'image',
    'line',
    'linearGradient',
    'marker',
    'mask',
    'mesh',
    'meshgradient',
    'meshpatch',
    'meshrow',
    'metadata',
    'missing-glyph',
    'mpath',
    'path',
    'pattern',
    'polygon',
    'polyline',
    'radialGradient',
    'rect',
    // 'script', Exclude this because it's also HTML
    'set',
    'solidcolor',
    'stop',
    // 'style', Exclude this because it's also HTML
    // 'svg', Exclude this because it's also HTML
    'switch',
    'symbol',
    'text',
    'textPath',
    // 'title', Exclude this because it's also HTML
    'tref',
    'tspan',
    'unknown',
    'use',
    // 'video', Exclude this because it's also HTML
    'view',
    'vkern',
  ];

  final bool _toolFriendlyAstOrigin;

  @literal
  const factory NgParser({
    bool toolFriendlyAstOrigin,
  }) = NgParser._;

  // Prevent inheritance.
  const NgParser._({
    bool toolFriendlyAstOrigin = false,
  }) : _toolFriendlyAstOrigin = toolFriendlyAstOrigin;

  /// Return a series of tokens by incrementally scanning [template].
  ///
  /// Automatically desugars.
  List<StandaloneTemplateAst> parse(
    String template, {
    @required String sourceUrl,
    bool desugar = true,
    @deprecated bool parseExpressions,
    ExceptionHandler exceptionHandler = const ThrowingExceptionHandler(),
  }) {
    var tokens = const NgLexer().tokenize(template, exceptionHandler);
    var parser = RecursiveAstParser(
      SourceFile.fromString(
        template,
        url: sourceUrl,
      ),
      tokens,
      _voidElements,
      _svgElements,
      exceptionHandler,
    );
    var asts = parser.parse();
    if (desugar) {
      var desugarVisitor = DesugarVisitor(
        toolFriendlyAstOrigin: _toolFriendlyAstOrigin,
        exceptionHandler: exceptionHandler,
      );
      asts = asts
          .map((t) => t.accept(desugarVisitor))
          .cast<StandaloneTemplateAst>()
          .toList();
    }
    return asts;
  }
}
