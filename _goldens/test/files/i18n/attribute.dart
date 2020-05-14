import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '<img alt="message" @i18n:alt="description">',
)
class I18nAttributeComponent {}
