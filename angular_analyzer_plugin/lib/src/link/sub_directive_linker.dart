import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/constant.dart';
import 'package:analyzer/src/generated/source.dart' show SourceRange;
import 'package:angular_analyzer_plugin/errors.dart';
import 'package:angular_analyzer_plugin/src/link/directive_provider.dart';
import 'package:angular_analyzer_plugin/src/model.dart';
import 'package:angular_analyzer_plugin/src/summary/idl.dart';

/// Class to link the `directives:` list of a [Component] into [Directive]s.
///
/// Performs a scope lookup of the references inside the list, and computes
/// their constant value. With that constant value, find all types and look up
/// their [Directive]s with the [DirectiveProvider].
///
/// Correctly tracks offsets so that if a reference is a constant list where
/// one of the items in that list is not a directive, we can highlight the
/// correct range.
class SubDirectiveLinker {
  final DirectiveProvider _directiveProvider;
  final ErrorReporter _errorReporter;

  SubDirectiveLinker(this._directiveProvider, this._errorReporter);

  void link(SummarizedDirectiveUse dirUseSum, LibraryScope scope,
      List<DirectiveBase> directives) {
    final nameIdentifier = astFactory
        .simpleIdentifier(StringToken(TokenType.IDENTIFIER, dirUseSum.name, 0));
    final prefixIdentifier = astFactory.simpleIdentifier(
        StringToken(TokenType.IDENTIFIER, dirUseSum.prefix, 0));
    final element = scope.lookup(
        dirUseSum.prefix == ""
            ? nameIdentifier
            : astFactory.prefixedIdentifier(
                prefixIdentifier, null, nameIdentifier),
        null);

    if (element != null && element.source != null) {
      if (element is ClassElement || element is FunctionElement) {
        _addDirectiveFromElement(element, directives,
            SourceRange(dirUseSum.offset, dirUseSum.length));
        return;
      } else if (element is PropertyAccessorElement) {
        element.variable.computeConstantValue();
        final values = element.variable.constantValue?.toListValue();
        if (values != null) {
          _addDirectivesForDartObject(directives, values,
              SourceRange(dirUseSum.offset, dirUseSum.length));
          return;
        }
      }
    }

    _errorReporter.reportErrorForOffset(
        AngularWarningCode.TYPE_LITERAL_EXPECTED,
        dirUseSum.offset,
        dirUseSum.length);
  }

  void _addDirectiveFromElement(
      Element element, List<DirectiveBase> targetList, SourceRange errorRange) {
    final directive = _directiveProvider.getAngularTopLevel(element);
    if (directive != null) {
      targetList.add(directive as DirectiveBase);
      return;
    } else {
      _errorReporter.reportErrorForOffset(
          element is FunctionElement
              ? AngularWarningCode.FUNCTION_IS_NOT_A_DIRECTIVE
              : AngularWarningCode.TYPE_IS_NOT_A_DIRECTIVE,
          errorRange.offset,
          errorRange.length,
          [element.name]);
    }
  }

  /// Walk the given [value] and add directives into [directives].
  ///
  /// Return `true` if success, or `false` the [value] has items that don't
  /// correspond to a directive.
  void _addDirectivesForDartObject(List<DirectiveBase> directives,
      List<DartObject> values, SourceRange errorRange) {
    for (final listItem in values) {
      final typeValue = listItem.toTypeValue();
      final isType =
          typeValue is InterfaceType && typeValue.element is ClassElement;
      final isFunction = listItem.type?.element is FunctionElement;
      final element = isType ? typeValue.element : listItem.type?.element;
      if (isType || isFunction) {
        _addDirectiveFromElement(element, directives, errorRange);
        continue;
      }

      final listValue = listItem.toListValue();
      if (listValue != null) {
        _addDirectivesForDartObject(directives, listValue, errorRange);
        continue;
      }

      _errorReporter.reportErrorForOffset(
        AngularWarningCode.TYPE_LITERAL_EXPECTED,
        errorRange.offset,
        errorRange.length,
      );
    }
  }
}
