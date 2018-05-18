import 'package:angular/angular.dart';

@Component(
  selector: 'message',
  template: '<p @i18n="description">message</p>',
)
class MessageComponent {}
