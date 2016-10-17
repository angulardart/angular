import 'dart:convert' as convert;

export 'dart:core' show RegExp, print, DateTime, Uri;

RegExp _fromFuncExp;

String stringify(obj) {
  _fromFuncExp ??= new RegExp(r"from Function '(\w+)'");
  final str = obj.toString();
  if (_fromFuncExp.firstMatch(str) != null) {
    return _fromFuncExp.firstMatch(str).group(1);
  } else {
    return str;
  }
}

String resolveEnumToken(enumValue, val) {
  // turn Enum.Token -> Token
  return val.toString().replaceFirst(new RegExp('^.+\\.'), '');
}

/// A [String.split] implementation that is like JS' implementation.
///
/// See https://dartpad.dartlang.org/37a53b0d5d4cced6c7312b2b965ed7fd.
List<String> jsSplit(String s, RegExp regExp) {
  var parts = <String>[];
  var lastEnd = 0;
  regExp.allMatches(s).forEach((match) {
    parts.add(s.substring(lastEnd, match.start));
    lastEnd = match.end;
    for (var i = 0; i < match.groupCount; i++) {
      parts.add(match.group(i + 1));
    }
  });
  parts.add(s.substring(lastEnd));
  return parts;
}

// Dart VM implements `identical` as true reference identity. JavaScript does
// not have this. The closest we have in JS is `===`. However, for strings JS
// would actually compare the contents rather than references. `dart2js`
// compiles `identical` to `===` and therefore there is a discrepancy between
// Dart VM and `dart2js`. The implementation of `looseIdentical` attempts to
// bridge the gap between the two while retaining good performance
// characteristics. In JS we use simple `identical`, which compiles to `===`,
// and in Dart VM we emulate the semantics of `===` by special-casing strings.
// Note that the VM check is a compile-time constant. This allows `dart2js` to
// evaluate the conditional during compilation and inline the entire function.
//
// See: dartbug.com/22496, dartbug.com/25270
const _IS_DART_VM = !identical(1.0, 1); // a hack
bool looseIdentical(a, b) =>
    _IS_DART_VM ? _looseIdentical(a, b) : identical(a, b);

// This function is intentionally separated from `looseIdentical` to keep the
// number of AST nodes low enough for `dart2js` to inline the code.
bool _looseIdentical(a, b) =>
    a is String && b is String ? a == b : identical(a, b);

/// Use this function to guard debugging code. When Dart is compiled in
/// production mode, the code guarded using this function will be tree
/// shaken away, reducing code size.
///
/// WARNING: DO NOT CHANGE THIS METHOD! This method is designed to have no
/// more AST nodes than the maximum allowed by dart2js to inline it. In
/// addition, the use of `assert` allows the compiler to statically compute
/// the value returned by this function and tree shake conditions guarded by
/// it.
///
/// Example:
///
/// if (assertionsEnabled()) {
///   ...code here is tree shaken away in prod mode...
/// }
bool assertionsEnabled() {
  var k = false;
  assert((k = true));
  return k;
}

// Can't be all uppercase as our transpiler would think it is a special directive...
class Json {
  static dynamic parse(String s) => convert.JSON.decode(s);
  static String stringify(data) {
    var encoder = new convert.JsonEncoder.withIndent("  ");
    return encoder.convert(data);
  }
}

bool isPrimitive(Object obj) =>
    obj is num || obj is bool || obj == null || obj is String;

num bitWiseOr(List values) {
  var val = values.reduce((num a, num b) => (a as int) | (b as int));
  return val as num;
}

num bitWiseAnd(List values) {
  var val = values.reduce((num a, num b) => (a as int) & (b as int));
  return val as num;
}
