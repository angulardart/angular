import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '''
    <p
        @i18n="description"
        @i18n.locale="en_US"
        @i18n.meaning="meaning"
        @i18n.skip>
      message
    </p>
  ''',
)
class I18nTextComponent {}
