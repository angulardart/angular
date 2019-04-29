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

/// Class to link the `pipes:` list of a [Component] into [Pipe]s.
///
/// Performs a scope lookup of the references inside the list, and computes
/// their constant value. With that constant value, find all types and look up
/// their [Pipe]s with the [DirectiveProvider].
///
/// Correctly tracks offsets so that if a reference is a constant list where
/// one of the items in that list is not a directive, we can highlight the
/// correct range.
class SubPipeLinker {
  final DirectiveProvider _directiveProvider;
  final ErrorReporter _errorReporter;

  SubPipeLinker(this._directiveProvider, this._errorReporter);

  void link(SummarizedPipesUse pipeSum, LibraryScope scope, List<Pipe> pipes) {
    final element = scope.lookup(
        astFactory.simpleIdentifier(
            StringToken(TokenType.IDENTIFIER, pipeSum.name, 0)),
        null);

    if (element != null && element.source != null) {
      if (element is ClassElement) {
        _addPipeFromElement(
            element, pipes, SourceRange(pipeSum.offset, pipeSum.length));
        return;
      } else if (element is PropertyAccessorElement) {
        element.variable.computeConstantValue();
        final values = element.variable.constantValue?.toListValue();
        if (values != null) {
          _addPipesForDartObject(
              pipes, values, SourceRange(pipeSum.offset, pipeSum.length));
          return;
        }
      }
    }

    _errorReporter.reportErrorForOffset(
        AngularWarningCode.TYPE_LITERAL_EXPECTED,
        pipeSum.offset,
        pipeSum.length);
  }

  void _addPipeFromElement(
      ClassElement element, List<Pipe> targetList, SourceRange errorRange) {
    final pipe = _directiveProvider.getPipe(element);
    if (pipe != null) {
      targetList.add(pipe);
      return;
    } else {
      _errorReporter.reportErrorForOffset(AngularWarningCode.TYPE_IS_NOT_A_PIPE,
          errorRange.offset, errorRange.length, [element.name]);
    }
  }

  /// Walk the given [value] and add directives into [directives].
  ///
  /// Return `true` if success, or `false` the [value] has items that don't
  /// correspond to a directive.
  void _addPipesForDartObject(
      List<Pipe> pipes, List<DartObject> values, SourceRange errorRange) {
    for (final listItem in values) {
      final typeValue = listItem.toTypeValue();
      final element = typeValue?.element;
      if (typeValue is InterfaceType && element is ClassElement) {
        _addPipeFromElement(element, pipes, errorRange);
        continue;
      }

      final listValue = listItem.toListValue();
      if (listValue != null) {
        _addPipesForDartObject(pipes, listValue, errorRange);
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
