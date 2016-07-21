import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;
import "package:angular2/src/facade/lang.dart"
    show isBlank, isString, isNumber, isFunction, RegExpWrapper, StringWrapper;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

/**
 * Creates a new String with some or all of the matches of a pattern replaced by
 * a replacement.
 *
 * The pattern to be matched is specified by the 'pattern' parameter.
 *
 * The replacement to be set is specified by the 'replacement' parameter.
 *
 * An optional 'flags' parameter can be set.
 *
 * ### Usage
 *
 *     expression | replace:pattern:replacement
 *
 * All behavior is based on the expected behavior of the JavaScript API
 * String.prototype.replace() function.
 *
 * Where the input expression is a [String] or [Number] (to be treated as a string),
 * the `pattern` is a [String] or [RegExp],
 * the 'replacement' is a [String] or [Function].
 *
 * --Note--: The 'pattern' parameter will be converted to a RegExp instance. Make sure to escape the
 * string properly if you are matching for regular expression special characters like parenthesis,
 * brackets etc.
 */
@Pipe(name: "replace")
@Injectable()
class ReplacePipe implements PipeTransform {
  dynamic transform(dynamic value, dynamic /* String | RegExp */ pattern,
      dynamic /* Function | String */ replacement) {
    if (isBlank(value)) {
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

    // var rgx = pattern instanceof RegExp ? pattern : RegExpWrapper.create(pattern);
    if (replacement is _Matcher) {
      var rgxPattern = isString(pattern)
          ? RegExpWrapper.create((pattern as String))
          : (pattern as RegExp);
      return StringWrapper.replaceAllMapped(input, rgxPattern, replacement);
    }
    if (pattern is RegExp) {
      // use the replaceAll variant
      return StringWrapper.replaceAll(input, pattern, (replacement as String));
    }
    return StringWrapper.replace(
        input, (pattern as String), (replacement as String));
  }

  bool _supportedInput(dynamic input) {
    return isString(input) || isNumber(input);
  }

  bool _supportedPattern(dynamic pattern) {
    return isString(pattern) || pattern is RegExp;
  }

  bool _supportedReplacement(dynamic replacement) {
    return isString(replacement) || isFunction(replacement);
  }
}

typedef String _Matcher(Match _);
