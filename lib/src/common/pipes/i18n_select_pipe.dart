library angular2.src.common.pipes.i18n_select_pipe;

import "package:angular2/src/facade/lang.dart" show isStringMap;
import "package:angular2/src/facade/collection.dart" show StringMapWrapper;
import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;
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
  String transform(String value, [List<dynamic> args = null]) {
    Map<String, String> mapping = ((args[0]) as Map<String, String>);
    if (!isStringMap(mapping)) {
      throw new InvalidPipeArgumentException(I18nSelectPipe, mapping);
    }
    return StringMapWrapper.contains(mapping, value)
        ? mapping[value]
        : mapping["other"];
  }

  const I18nSelectPipe();
}
