import 'package:angular/angular.dart';

@Directive(selector: '[message]')
class MessageDirective {
  @Input()
  String message;
}

@Component(
  selector: 'message',
  template: '''
    <div [message]="'message'" @i18n:message="description"></div>,
  ''',
  directives: [MessageDirective],
)
class I18nPropertyComponent {}
