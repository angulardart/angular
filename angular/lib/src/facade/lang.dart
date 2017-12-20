/// A [String.split] implementation that is like JS' implementation.
///
/// See https://dartpad.dartlang.org/37a53b0d5d4cced6c7312b2b965ed7fd.
List<String> jsSplit(String s, RegExp regExp) {
  var parts = <String>[];
  var lastEnd = 0;
  for (var match in regExp.allMatches(s)) {
    parts.add(s.substring(lastEnd, match.start));
    lastEnd = match.end;
    for (var i = 0, len = match.groupCount; i < len; i++) {
      parts.add(match.group(i + 1));
    }
  }
  parts.add(s.substring(lastEnd));
  return parts;
}

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

bool isPrimitive(Object obj) =>
    obj is num || obj is bool || obj == null || obj is String;
