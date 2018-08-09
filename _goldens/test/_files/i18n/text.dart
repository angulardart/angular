import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '<p @i18n="description" @i18n.meaning="meaning">message</p>',
)
class I18nTextComponent {}
