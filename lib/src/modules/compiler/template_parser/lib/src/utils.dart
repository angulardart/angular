import 'package:charcode/charcode.dart';

/// A `[` character.
const int $openProperty = $open_bracket;

/// A `]` character.
const int $closeProperty = $close_bracket;

/// A `(` character.
const int $openEvent = $open_paren;

/// A `)` character.
const int $closeEvent = $close_paren;

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
