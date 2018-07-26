// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:source_span/source_span.dart';

import '../token/tokens.dart';
import '../visitor.dart';

/// Represents an AST node parsed from an Angular template.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class TemplateAst {
  // All parsed ASTs come from a source file; used to get a source span.
  final SourceFile _sourceFile;

  /// Initializes an AST node by specifying where it was parsed from.
  ///
  /// This constructor is considered a convenience for most forms of ASTs.
  const TemplateAst.parsed(this.beginToken, this.endToken, this._sourceFile);

  /// First token that was used to form this AST.
  final NgToken beginToken;

  /// Child nodes, if any.
  List<StandaloneTemplateAst> get childNodes => const [];

  /// Last token that was used to form this AST.
  final NgToken endToken;

  /// Segment of source text from which the AST was parsed from.
  ///
  /// Includes all *significant* parts of the source text, including child nodes
  /// and identifying characters. May not include pre or post whitespace or
  /// delimiters.
  SourceSpan get sourceSpan {
    return _sourceFile.span(beginToken.offset, endToken.end);
  }

  String get sourceUrl {
    return _sourceFile.url.toString();
  }

  /// Have the [visitor] start visiting this node.
  R accept<R, C>(TemplateAstVisitor<R, C> visitor, [C context]);

  /// Whether this node is capable of containing children and does.
  ///
  /// If `true` then [childNodes] has at least one element.
  final bool isParent = false;

  /// Whether this node needs to be 'attached' to another node to be valid.
  bool get isStandalone => this is StandaloneTemplateAst;

  /// Whether this node did not truly originate from the parsed source.
  ///
  /// May be `true` when:
  /// - The parser needed this node to have a valid tree, but it was missing
  /// - A developer created a node programmatically for testing
  /// - An original AST node was transformed
  ///
  /// In the _original AST node was transformed_ case, you can view the original
  /// AST by casting to [SyntheticTemplateAst] and reading the `origin` field.
  final bool isSynthetic = false;
}

/// A marker interface for [TemplateAst] types that do not need to be attached.
///
/// For example, elements, comments, and text may be free-standing nodes.
abstract class StandaloneTemplateAst implements TemplateAst {}

/// An AST node that was created programmatically (not from parsed source).
///
/// Synthetic ASTs are useful for:
/// - Error fallback (parser can add nodes that were missing but expected)
/// - Testing (i.e. comparing actual parsed nodes to expected synthetic ones)
/// - Transformation (modifying an AST tree that originally was parsed)
abstract class SyntheticTemplateAst implements TemplateAst {
  // Indicates that some fields/properties for this AST are not viewable.
  static Error _unsupported() {
    return UnsupportedError('Has no originating source code (synthetic)');
  }

  /// What AST node this node originated from (before transformation); optional.
  /// Requires `toolFriendlyAstOrigin` flag to be turned on.
  final TemplateAst origin;

  /// Create a synthetic AST that has no origin from parsed source.
  ///
  /// ASTs created this way will throw `UnsupportedError` on [sourceSpan].
  const SyntheticTemplateAst() : origin = null;

  /// Create a synthetic AST that originated from another AST node.
  const SyntheticTemplateAst.from(this.origin);

  @override
  NgToken get beginToken {
    if (origin != null) {
      return origin.beginToken;
    }
    throw _unsupported();
  }

  /// Child nodes, if any.
  @override
  List<StandaloneTemplateAst> get childNodes => const [];

  @override
  NgToken get endToken {
    if (origin != null) {
      return origin.endToken;
    }
    throw _unsupported();
  }

  @override
  bool get isParent => childNodes.isNotEmpty;

  @override
  bool get isStandalone => this is StandaloneTemplateAst;

  @override
  final bool isSynthetic = true;

  @override
  SourceSpan get sourceSpan {
    if (origin != null) {
      return origin.sourceSpan;
    }
    throw _unsupported();
  }

  @override
  String get sourceUrl {
    if (origin != null) {
      return origin.sourceUrl;
    }
    throw _unsupported();
  }
}

/// Mixin used to preserve offsets of tokens to be able to reproduce the same
/// text. In addition, preserves offsets in cases where banana syntax and
/// template syntax are desugared.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class TagOffsetInfo {
  int get nameOffset;
  int get valueOffset;
  int get quotedValueOffset;
  int get equalSignOffset;
}

/// Represents an interface for a parsed element decorator.
///
/// Clients should not extend, implement, or mix-in this class.
abstract class ParsedDecoratorAst {
  NgToken get prefixToken;
  NgToken get nameToken;
  NgToken get suffixToken;
  NgAttributeValueToken get valueToken;

  int get prefixOffset;
  int get suffixOffset; //May be null for reference and template
}
