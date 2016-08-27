import "package:angular2/di.dart" show Injectable, PipeTransform, Pipe;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

final RegExp interpolationExp = new RegExp("#");

/// Maps a value to a string that pluralizes the value properly.
///
/// ## Usage
///
/// expression | i18nPlural:mapping
///
/// where `expression` is a number and `mapping` is an object that indicates the
/// proper text for when the `expression` evaluates to 0, 1, or some other
/// number.  You can interpolate the actual value into the text using the `#`
/// sign.
///
/// ## Example
///
/// ```dart
/// <div>
///   {{ messages.length | i18nPlural: messageMapping }}
/// </div>
///
/// class MyApp {
///   List messages;
///   dynamic messageMapping = {
///     '=0': 'No messages.',
///     '=1': 'One message.',
///     'other': '# messages.'
///   }
///   ...
/// }
/// ```
@Pipe(name: "i18nPlural", pure: true)
@Injectable()
class I18nPluralPipe implements PipeTransform {
  String transform(num value, Map<String, String> pluralMap) {
    String key;
    String valueStr;
    if (pluralMap is! Map) {
      throw new InvalidPipeArgumentException(I18nPluralPipe, pluralMap);
    }
    key =
        identical(value, 0) || identical(value, 1) ? '''=${ value}''' : "other";
    valueStr = value != null ? value.toString() : "";
    return pluralMap[key].replaceAll(interpolationExp, valueStr);
  }

  const I18nPluralPipe();
}
