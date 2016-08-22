import "package:angular2/core.dart" show Injectable, PipeTransform, Pipe;

import "invalid_pipe_argument_exception.dart" show InvalidPipeArgumentException;

///
/// Generic selector that displays the string that matches the current value.
///
/// ## Usage
///
/// expression | i18nSelect:mapping
///
/// where `mapping` is an object that indicates the text that should be displayed
/// for different values of the provided `expression`.
///
/// ## Example
///
/// ```dart
/// <div>
///   {{ gender | i18nSelect: inviteMap }}
/// </div>
///
/// class MyApp {
///   String gender = 'male';
///   dynamic inviteMap = {
///     'male': 'Invite her.',
///     'female': 'Invite him.',
///     'other': 'Invite them.'
///   }
///   ...
/// }
/// ```
@Pipe(name: "i18nSelect", pure: true)
@Injectable()
class I18nSelectPipe implements PipeTransform {
  String transform(String value, Map<String, String> mapping) {
    if (mapping is! Map) {
      throw new InvalidPipeArgumentException(I18nSelectPipe, mapping);
    }
    return mapping[value] ?? mapping['other'];
  }

  const I18nSelectPipe();
}
