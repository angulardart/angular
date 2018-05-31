import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '<p @i18n="description">This is an <b>important</b> message!</p>',
)
class I18nHtmlComponent {}
