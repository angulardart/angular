import 'package:analyzer/dart/ast/ast.dart'
    show SimpleIdentifier, PrefixedIdentifier, Identifier;
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';

/// Link [SummarizedExportedIdentifer] into [Export]s.
class ExportLinker {
  final ErrorReporter _errorReporter;

  ExportLinker(this._errorReporter);

  Export link(SummarizedExportedIdentifier export,
      ClassElement componentClassElement, LibraryScope scope) {
    if (_hasWrongTypeOfPrefix(export, scope)) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.EXPORTS_MUST_BE_PLAIN_IDENTIFIERS,
          export.offset,
          export.length);
      return null;
    }

    final element = scope.lookup(_getIdentifier(export), null);
    if (element == componentClassElement) {
      _errorReporter.reportErrorForOffset(
          AngularWarningCode.COMPONENTS_CANT_EXPORT_THEMSELVES,
          export.offset,
          export.length);
      return null;
    }

    return Export(export.name, export.prefix,
        SourceRange(export.offset, export.length), element);
  }

  Identifier _getIdentifier(SummarizedExportedIdentifier export) =>
      export.prefix == ''
          ? _getSimpleIdentifier(export)
          : _getPrefixedIdentifier(export);

  SimpleIdentifier _getPrefixAsSimpleIdentifier(
          SummarizedExportedIdentifier export) =>
      astFactory.simpleIdentifier(
          StringToken(TokenType.IDENTIFIER, export.prefix, export.offset));

  PrefixedIdentifier _getPrefixedIdentifier(
          SummarizedExportedIdentifier export) =>
      astFactory.prefixedIdentifier(
          _getPrefixAsSimpleIdentifier(export),
          SimpleToken(TokenType.PERIOD, export.offset + export.prefix.length),
          _getSimpleIdentifier(export, offset: export.prefix.length + 1));

  SimpleIdentifier _getSimpleIdentifier(SummarizedExportedIdentifier export,
          {int offset = 0}) =>
      astFactory.simpleIdentifier(StringToken(
          TokenType.IDENTIFIER, export.name, export.offset + offset));

  /// Check an export's prefix is well-formed.
  ///
  /// Only report false for known non-import-prefix prefixes, the rest get
  /// flagged by the dart analyzer already.
  bool _hasWrongTypeOfPrefix(
      SummarizedExportedIdentifier export, LibraryScope scope) {
    if (export.prefix == '') {
      return false;
    }

    final prefixElement =
        scope.lookup(_getPrefixAsSimpleIdentifier(export), null);

    return prefixElement != null && prefixElement is! PrefixElement;
  }
}
