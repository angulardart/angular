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

bool isPrimitive(Object obj) =>
    obj is num || obj is bool || obj == null || obj is String;
