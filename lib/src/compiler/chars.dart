const $EOF = 0;
const $TAB = 9;
const $LF = 10;
const $VTAB = 11;
const $FF = 12;
const $CR = 13;
const $SPACE = 32;
const $BANG = 33;
const $DQ = 34;
const $HASH = 35;
const $$ = 36;
const $PERCENT = 37;
const $AMPERSAND = 38;
const $SQ = 39;
const $LPAREN = 40;
const $RPAREN = 41;
const $STAR = 42;
const $PLUS = 43;
const $COMMA = 44;
const $MINUS = 45;
const $PERIOD = 46;
const $SLASH = 47;
const $COLON = 58;
const $SEMICOLON = 59;
const $LT = 60;
const $EQ = 61;
const $GT = 62;
const $QUESTION = 63;
const $0 = 48;
const $9 = 57;
const $A = 65;
const $E = 69;
const $Z = 90;
const $LBRACKET = 91;
const $BACKSLASH = 92;
const $RBRACKET = 93;
const $CARET = 94;
const $_ = 95;
const $a = 97;
const $e = 101;
const $f = 102;
const $n = 110;
const $r = 114;
const $t = 116;
const $u = 117;
const $v = 118;
const $z = 122;
const $LBRACE = 123;
const $BAR = 124;
const $RBRACE = 125;
const $NBSP = 160;
const $NGSP = 0xE500; // Unicode PUA for space.
const $PIPE = 124;
const $TILDA = 126;
const $AT = 64;
const String ngSpace = '\uE500';
String replaceNgSpace(String value) {
  return value.replaceAll(ngSpace, ' ');
}

bool isWhitespace(num code) {
  return (code >= $TAB && code <= $SPACE) || (code == $NBSP) || (code == $NGSP);
}
