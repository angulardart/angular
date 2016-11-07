import 'package:charcode/charcode.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
// import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';

/// Attempts to parse a String into an unresolved AST expression.
Expression parseAngularExpression(String contents, String name,
    {bool suppressErrors: false, bool parseFunctionBodies: true}) {
  var source = new StringSource(contents, name);
  var reader = new CharSequenceReader(contents);
  var errorCollector = new _ErrorCollector();
  var scanner = new Scanner(source, reader, errorCollector);
  var token = scanner.tokenize();
  var parser = new Parser(source, errorCollector)
    ..parseFunctionBodies = parseFunctionBodies;
  var unit = parser.parseExpression(token);

  if (errorCollector.hasErrors && !suppressErrors) throw errorCollector.group;

  return unit;
}

/// Taken from package:analyzer/analyzer.dart.
/// A simple error listener that collects errors into an [AnalyzerErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  _ErrorCollector();

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
      new AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  /// Whether any errors where collected.
  bool get hasErrors => _errors.isNotEmpty;

  @override
  void onError(AnalysisError error) => _errors.add(error);
}

/// A `[` character.
const int $openProperty = $open_bracket;

/// A `]` character.
const int $closeProperty = $close_bracket;

/// A `(` character.
const int $openEvent = $open_paren;

/// A `)` character.
const int $closeEvent = $close_paren;

/// A `#` character.
const int $binding = $hash;

/// A `*` character.
const int $star = $asterisk;

/// Returns whether [char] is `(a-Z)`.
bool isAsciiLetter(int char) => char >= $a && char <= $Z;

/// Returns whether [char] should be considered a 'whitespace' character.
///
/// In the template AST, this is a `' '`, `'\t'`, `'\r'` or `'\n'`.
bool isWhiteSpace(int char) =>
    char == $space || // ' '
    char == $tab || // '\t'
    char == $cr || // '\r'
    char == $lf; // '\n'
