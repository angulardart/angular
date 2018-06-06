import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '''
    <p @i18n="description">
      This message contains <i>multiple levels of <b>nested</b> HTML</i>.
    </p>
  ''',
)
class I18nHtmlComponent {}
