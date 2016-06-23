library angular2.src.common.pipes.i18n_plural_pipe;

import "package:angular2/src/facade/lang.dart"
    show isStringMap, StringWrapper, isPresent, RegExpWrapper;
import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;
import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

RegExp interpolationExp = RegExpWrapper.create("#");

/**
 *
 *  Maps a value to a string that pluralizes the value properly.
 *
 *  ## Usage
 *
 *  expression | i18nPlural:mapping
 *
 *  where `expression` is a number and `mapping` is an object that indicates the proper text for
 *  when the `expression` evaluates to 0, 1, or some other number.  You can interpolate the actual
 *  value into the text using the `#` sign.
 *
 *  ## Example
 *
 *  ```
 *  <div>
 *    {{ messages.length | i18nPlural: messageMapping }}
 *  </div>
 *
 *  class MyApp {
 *    messages: any[];
 *    messageMapping: any = {
 *      '=0': 'No messages.',
 *      '=1': 'One message.',
 *      'other': '# messages.'
 *    }
 *    ...
 *  }
 *  ```
 *
 */
@Pipe(name: "i18nPlural", pure: true)
@Injectable()
class I18nPluralPipe implements PipeTransform {
  String transform(num value, [List<dynamic> args = null]) {
    String key;
    String valueStr;
    Map<String, String> pluralMap = ((args[0]) as Map<String, String>);
    if (!isStringMap(pluralMap)) {
      throw new InvalidPipeArgumentException(I18nPluralPipe, pluralMap);
    }
    key =
        identical(value, 0) || identical(value, 1) ? '''=${ value}''' : "other";
    valueStr = isPresent(value) ? value.toString() : "";
    return StringWrapper.replaceAll(pluralMap[key], interpolationExp, valueStr);
  }

  const I18nPluralPipe();
}
