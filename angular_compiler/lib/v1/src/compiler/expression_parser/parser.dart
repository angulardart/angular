import 'package:meta/meta.dart';
import 'package:angular_compiler/v2/context.dart';

import '../compile_metadata.dart';
import '../js_split_facade.dart';
import 'analyzer_parser.dart';
import 'ast.dart' show AST, ASTWithSource;

final _findInterpolation = RegExp(r'{{([\s\S]*?)}}');

class ParseException extends BuildError {
  final String _message;

  ParseException(
    String message,
    String? input,
    String errLocation, [
    dynamic ctxLocation,
  ]) : _message =
            'Parser Error: $message $errLocation [$input] in $ctxLocation';

  @override
  String toString() => _message;
}

abstract class ExpressionParser {
  factory ExpressionParser() = AnalyzerExpressionParser;

  @protected
  const ExpressionParser.forInheritence();

  /// Parses an event binding (historically called an "action").
  ///
  /// ```
  /// // <div (click)="doThing()">
  /// parseAction('doThing()', ...)
  /// ```
  ASTWithSource parseAction(
    String? input,
    String location,
    List<CompileIdentifierMetadata> exports,
  ) {
    if (input == null) {
      throw ParseException(
        'Blank expressions are not allowed in event bindings.',
        input,
        location,
      );
    }
    _checkNoInterpolation(input, location);
    return ASTWithSource(
      parseActionImpl(input, location, exports),
      input,
      location,
    );
  }

  /// Parses an input, property, or attribute binding.
  ///
  /// ```
  /// // <div [title]="renderTitle">
  /// parseBinding('renderTitle', ...)
  /// ```
  ASTWithSource parseBinding(
    String input,
    String location,
    List<CompileIdentifierMetadata> exports,
  ) {
    _checkNoInterpolation(input, location);
    return ASTWithSource(
      parseBindingImpl(input, location, exports),
      input,
      location,
    );
  }

  /// Parses a text interpolation.
  ///
  /// ```
  /// // Hello {{place}}!
  /// parseInterpolation('place', ...)
  /// ```
  ///
  /// Returns `null` if there were no interpolations in [input].
  ASTWithSource? parseInterpolation(
    String input,
    String location,
    List<CompileIdentifierMetadata> exports,
  ) {
    final result = parseInterpolationImpl(input, location, exports);
    if (result == null) {
      return null;
    }
    return ASTWithSource(
      result,
      input,
      location,
    );
  }

  /// Override to implement [parseAction].
  ///
  /// Basic validation is already performed that [input] is seemingly valid.
  @visibleForOverriding
  AST parseActionImpl(
    String input,
    String location,
    List<CompileIdentifierMetadata> exports,
  );

  /// Override to implement [parseBinding].
  ///
  /// Basic validation is already performed that [input] is seemingly valid.
  @visibleForOverriding
  AST parseBindingImpl(
    String input,
    String location,
    List<CompileIdentifierMetadata> exports,
  );

  /// Override to implement [parseInterpolation].
  ///
  /// Basic validation is already performed that [input] is seemingly valid.
  @visibleForOverriding
  AST? parseInterpolationImpl(
    String input,
    String location,
    List<CompileIdentifierMetadata> exports,
  );

  /// Helper method for implementing [parseInterpolation].
  ///
  /// Splits a longer multi-expression interpolation into [SplitInterpolation].
  @protected
  SplitInterpolation? splitInterpolation(String input, String location) {
    var parts = jsSplit(input, _findInterpolation);
    if (parts.length <= 1) {
      return null;
    }
    var strings = <String>[];
    var expressions = <String>[];
    for (var i = 0; i < parts.length; i++) {
      var part = parts[i];
      if (i.isEven) {
        // fixed string
        strings.add(part);
      } else if (part.trim().isNotEmpty) {
        expressions.add(part);
      } else {
        throw ParseException(
          'Blank expressions are not allowed in interpolated strings',
          input,
          'at column ${_findInterpolationErrorColumn(parts, i)} in',
          location,
        );
      }
    }
    return SplitInterpolation._(strings, expressions);
  }

  void _checkNoInterpolation(String input, String location) {
    var parts = jsSplit(input, _findInterpolation);
    if (parts.length > 1) {
      throw ParseException(
          'Got interpolation ({{}}) where expression was expected',
          input,
          'at column ${_findInterpolationErrorColumn(parts, 1)} in',
          location);
    }
  }

  static int _findInterpolationErrorColumn(
    List<String> parts,
    int partInErrIdx,
  ) {
    var errLocation = '';
    for (var j = 0; j < partInErrIdx; j++) {
      errLocation += j.isEven ? parts[j] : '{{${parts[j]}}}';
    }
    return errLocation.length;
  }
}

/// Splits a longer interpolation expression into [strings] and [expressions].
class SplitInterpolation {
  final List<String> strings;
  final List<String> expressions;

  SplitInterpolation._(this.strings, this.expressions);
}
