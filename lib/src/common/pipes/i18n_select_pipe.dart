import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/src/facade/lang.dart" show isStringMap;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

/**
 *
 *  Generic selector that displays the string that matches the current value.
 *
 *  ## Usage
 *
 *  expression | i18nSelect:mapping
 *
 *  where `mapping` is an object that indicates the text that should be displayed
 *  for different values of the provided `expression`.
 *
 *  ## Example
 *
 *  ```
 *  <div>
 *    {{ gender | i18nSelect: inviteMap }}
 *  </div>
 *
 *  class MyApp {
 *    gender: string = 'male';
 *    inviteMap: any = {
 *      'male': 'Invite her.',
 *      'female': 'Invite him.',
 *      'other': 'Invite them.'
 *    }
 *    ...
 *  }
 *  ```
 */
@Pipe(name: "i18nSelect", pure: true)
@Injectable()
class I18nSelectPipe implements PipeTransform {
  String transform(String value, Map<String, String> mapping) {
    if (!isStringMap(mapping)) {
      throw new InvalidPipeArgumentException(I18nSelectPipe, mapping);
    }
    return StringMapWrapper.contains(mapping, value)
        ? mapping[value]
        : mapping["other"];
  }

  const I18nSelectPipe();
}
