import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:angular/src/transform/common/logging.dart';
import 'package:angular/src/transform/common/mirror_matcher.dart';
import 'package:angular/src/transform/common/names.dart';

import 'codegen.dart';
import 'entrypoint_matcher.dart';

/// Matches the symbol `bootstrap`.
///
/// The lookahead pattern prevents matching a symbol which `bootstrap` prefixes.
/// For example, `bootstrapStatic`. [RegExp] doesn't support lookbehind, so to
/// prevent matching a symbol `bootstrap` suffixes, a capture group is used to
/// match and preserve the leading non-alphanumeric character.
final _bootstrapSymbolRe = new RegExp('(\\W)$BOOTSTRAP_NAME(?=\\W|\$)');

class Rewriter {
  final String _code;
  final Codegen _codegen;
  final EntrypointMatcher _entrypointMatcher;
  final MirrorMatcher _mirrorMatcher;

  Rewriter(this._code, this._codegen, this._entrypointMatcher,
      {MirrorMatcher mirrorMatcher, bool writeStaticInit: true})
      : _mirrorMatcher =
            mirrorMatcher == null ? const MirrorMatcher() : mirrorMatcher {
    if (_codegen == null) {
      throw new ArgumentError.notNull('Codegen');
    }
    if (_entrypointMatcher == null) {
      throw new ArgumentError.notNull('EntrypointMatcher');
    }
  }

  /// Rewrites the provided code to remove dart:mirrors.
  ///
  /// Specifically, removes imports of the
  /// {@link ReflectionCapabilities} library and instantiations of
  /// {@link ReflectionCapabilities}, as detected by the (potentially) provided
  /// {@link MirrorMatcher}.
  ///
  /// To the extent possible, this method does not change line numbers or
  /// offsets in the provided code to facilitate debugging via source maps.
  String rewrite(CompilationUnit node) {
    if (node == null) throw new ArgumentError.notNull('node');

    var visitor = new _RewriterVisitor(this);

    node.accept(visitor);

    return visitor.outputRewrittenCode();
  }
}

/// Visitor responsible for rewriting the Angular 2 code which instantiates
/// {@link ReflectionCapabilities} and removing its associated import.
///
/// This breaks our dependency on dart:mirrors, which enables smaller code
/// size and better performance.
class _RewriterVisitor extends Object with RecursiveAstVisitor<Object> {
  final Rewriter _rewriter;
  final buf = new StringBuffer();
  final reflectionCapabilityAssignments = <AssignmentExpression>[];

  int _currentIndex = 0;
  bool _setupAdded = false;
  bool _importAdded = false;
  ImportDirective _importHidesBootstrapStatic;

  _RewriterVisitor(this._rewriter);

  @override
  Object visitImportDirective(ImportDirective node) {
    buf.write(_rewriter._code.substring(_currentIndex, node.offset));
    _currentIndex = node.offset;
    if (_rewriter._mirrorMatcher.hasReflectionCapabilitiesUri(node)) {
      _rewriteReflectionCapabilitiesImport(node);
    } else if (_rewriter._mirrorMatcher.hasAngularUri(node)) {
      _rewriteAngularImportForBootstrapStatic(node);
    }
    if (!_importAdded) {
      // Add imports for ng_deps (once)
      buf.write(_rewriter._codegen.codegenImport());
      _importAdded = true;
    }
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    if (node.rightHandSide is InstanceCreationExpression &&
        _rewriter._mirrorMatcher
            .isNewReflectionCapabilities(node.rightHandSide)) {
      reflectionCapabilityAssignments.add(node);
      _rewriteReflectionCapabilitiesAssignment(node);
    }
    return super.visitAssignmentExpression(node);
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (_rewriter._mirrorMatcher.isNewReflectionCapabilities(node) &&
        !reflectionCapabilityAssignments.contains(node.parent)) {
      log.error('Unexpected format in creation of '
          '$REFLECTION_CAPABILITIES_NAME');
    }
    return super.visitInstanceCreationExpression(node);
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.toString() == BOOTSTRAP_NAME) {
      _rewriteBootstrapCallToStatic(node);
    }
    return super.visitMethodInvocation(node);
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    if (_rewriter._entrypointMatcher.isEntrypoint(node)) {
      _rewriteEntrypointFunctionBody(node.body);
    }
    return super.visitMethodDeclaration(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    if (_rewriter._entrypointMatcher.isEntrypoint(node)) {
      _rewriteEntrypointFunctionBody(node.functionExpression.body);
    }
    return super.visitFunctionDeclaration(node);
  }

  void _rewriteEntrypointFunctionBody(FunctionBody node) {
    if (node is BlockFunctionBody) {
      final insertOffset = node.block.leftBracket.end;
      buf.write(_rewriter._code.substring(_currentIndex, insertOffset));
      buf.write(_getStaticReflectorInitBlock());
      _currentIndex = insertOffset;
      _setupAdded = true;
    } else if (node is ExpressionFunctionBody) {
      // TODO(kegluneq): Add support, see issue #5474.
      throw new ArgumentError(
          'Arrow syntax is not currently supported as `@AngularEntrypoint`s');
    } else if (node is NativeFunctionBody) {
      throw new ArgumentError('Native functions and methods are not supported '
          'as `@AngularEntrypoint`s');
    } else if (node is EmptyFunctionBody) {
      throw new ArgumentError('Empty functions and methods are not supported '
          'as `@AngularEntrypoint`s');
    }
  }

  String outputRewrittenCode() {
    if (_currentIndex < _rewriter._code.length) {
      buf.write(_rewriter._code.substring(_currentIndex));
    }
    return '$buf';
  }

  void _rewriteAngularImportForBootstrapStatic(ImportDirective node) {
    // Write import statement, retaining prefix if present.
    final idx = node.prefix?.end ?? node.uri.end;
    buf.write(_rewriter._code.substring(_currentIndex, idx));

    // Index of the last processed character.
    var lastIdx = idx;

    if (node.combinators != null) {
      for (var combinator in node.combinators) {
        if (combinator is ShowCombinator) {
          // Write shown names, replacing `bootstrap` with `bootstrapStatic`.
          buf.write(_rewriter._code
              .substring(lastIdx, combinator.end)
              .replaceFirstMapped(_bootstrapSymbolRe,
                  (match) => '${match[1]}$BOOTSTRAP_STATIC_NAME'));
          lastIdx = combinator.end;
        } else if (combinator is HideCombinator) {
          if (combinator.hiddenNames
              .any((hiddenName) => hiddenName.name == BOOTSTRAP_STATIC_NAME)) {
            // Remember import statement that hides `bootstrapStatic` so it can
            // be reported in an error message if `bootstrapStatic` is needed.
            _importHidesBootstrapStatic = node;
          }
          // Write hidden names as is.
          buf.write(_rewriter._code.substring(lastIdx, combinator.end));
          lastIdx = combinator.end;
        }
      }
    }

    // Write anything after the combinators.
    buf.write(_rewriter._code.substring(lastIdx, node.end));
    _currentIndex = node.end;
  }

  void _rewriteBootstrapCallToStatic(MethodInvocation node) {
    if (_importHidesBootstrapStatic != null) {
      throw new FormatException(
          "Import statement may not hide '$BOOTSTRAP_STATIC_NAME': "
          '$_importHidesBootstrapStatic');
    }

    buf.write(_rewriter._code.substring(_currentIndex, node.offset));

    var args = node.argumentList.arguments;
    int numArgs = node.argumentList.arguments.length;
    if (numArgs < 1 || numArgs > 2) {
      log.warning('`bootstrap` does not support $numArgs arguments. '
          'Found bootstrap${node.argumentList}. Transform may not succeed.');
    }

    var reflectorInit =
        _setupAdded ? '' : ', () { ${_getStaticReflectorInitBlock()} }';

    // rewrite `bootstrap(...)` to `bootstrapStatic(...)`
    if (node.target != null && node.target is SimpleIdentifier) {
      // `bootstrap` imported with a prefix, maintain this.
      buf.write('${node.target}.');
    }
    buf.write('$BOOTSTRAP_STATIC_NAME(${args[0]}');
    if (numArgs == 1) {
      // bootstrap args are positional, so before we pass reflectorInit code
      // we need to pass `null` for DI bindings.
      if (reflectorInit.isNotEmpty) {
        buf.write(', null');
      }
    } else {
      // pass DI bindings
      buf.write(', ${args[1]}');
    }
    buf.write(reflectorInit);
    buf.write(')');
    _setupAdded = true;
    _currentIndex = node.end;
  }

  String _getStaticReflectorInitBlock() {
    return _rewriter._codegen.codegenSetupReflectionCall();
  }

  void _rewriteReflectionCapabilitiesImport(ImportDirective node) {
    buf.write(_rewriter._code.substring(_currentIndex, node.offset));
    if ('${node.prefix}' == _rewriter._codegen.prefix) {
      log.warning(
          'Found import prefix "${_rewriter._codegen.prefix}" in source file.'
          ' Transform may not succeed.');
    }
    buf.write(_commentedNode(node));
    _currentIndex = node.end;
  }

  void _rewriteReflectionCapabilitiesAssignment(
      AssignmentExpression assignNode) {
    var node = assignNode;
    while (node.parent is ExpressionStatement) {
      node = node.parent;
    }
    buf.write(_rewriter._code.substring(_currentIndex, node.offset));
    if (!_setupAdded) {
      buf.write(_getStaticReflectorInitBlock());
      _setupAdded = true;
    }
    buf.write(_commentedNode(node));
    _currentIndex = node.end;
  }

  String _commentedNode(AstNode node) {
    return '/*${_rewriter._code.substring(node.offset, node.end)}*/';
  }
}
