import 'package:angular/di.dart' show PipeTransform, Pipe;

import 'invalid_pipe_argument_exception.dart' show InvalidPipeArgumentException;

/// Creates a new String with some or all of the matches of a pattern replaced
/// by a replacement.
///
/// The pattern to be matched is specified by the 'pattern' parameter.
///
/// The replacement to be set is specified by the 'replacement' parameter.
///
/// An optional 'flags' parameter can be set.
///
/// ### Usage
///
///     expression | replace:pattern:replacement
///
/// All behavior is based on the expected behavior of the JavaScript API
/// String.prototype.replace() function.
///
/// Where the input expression is a [String] or [Number] (to be treated as a
/// string),
/// the `pattern` is a [String] or [RegExp],
/// the 'replacement' is a [String] or [Function].
///
/// --Note--: The 'pattern' parameter will be converted to a RegExp instance.
/// Make sure to escape the string properly if you are matching for regular
/// expression special characters like parenthesis, brackets etc.
@Pipe('replace')
class ReplacePipe implements PipeTransform {
  const ReplacePipe();

  dynamic transform(dynamic value, dynamic /* String | RegExp */ pattern,
      dynamic /* Function | String */ replacement) {
    if (value == null) {
      return value;
    }
    if (!this._supportedInput(value)) {
      throw new InvalidPipeArgumentException(ReplacePipe, value);
    }
    var input = value.toString();
    if (!this._supportedPattern(pattern)) {
      throw new InvalidPipeArgumentException(ReplacePipe, pattern);
    }
    if (!this._supportedReplacement(replacement)) {
      throw new InvalidPipeArgumentException(ReplacePipe, replacement);
    }
    // template fails with literal RegExp e.g /pattern/igm
    if (replacement is _Matcher) {
      var rgxPattern =
          pattern is String ? new RegExp(pattern) : (pattern as RegExp);
      return input.replaceAllMapped(rgxPattern, replacement);
    }
    if (pattern is RegExp) {
      // use the replaceAll variant
      return input.replaceAll(pattern, (replacement as String));
    }
    return input.replaceFirst((pattern as String), (replacement as String));
  }

  bool _supportedInput(dynamic input) => input is String || input is num;

  bool _supportedPattern(dynamic pattern) {
    return pattern is String || pattern is RegExp;
  }

  bool _supportedReplacement(dynamic replacement) {
    return replacement is String || replacement is Function;
  }
}

typedef String _Matcher(Match _);
