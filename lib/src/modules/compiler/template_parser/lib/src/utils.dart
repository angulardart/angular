import 'package:charcode/charcode.dart';

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
